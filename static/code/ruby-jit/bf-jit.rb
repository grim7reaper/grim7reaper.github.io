#!/usr/bin/env ruby
# encoding: utf-8

require 'set'
require_relative 'jit'

# Brainfuck's instruction set.
INSTRUCTION_SET = Set.new('[]><+-.,'.chars).freeze

# Mapping f(Brainfuck instruction) = x86_64 assembly
INSTRUCTIONS_MAPPING = {
  # inc r10
  '>' => "\x49\xFF\xC2".b,
  # dec r10
  '<' => "\x49\xFF\xCA".b,
  # addb [r10], 1
  '+' => "\x41\x80\x02\x01".b,
  # subb [r10], 1
  '-' => "\x41\x80\x2A\x01".b,
  # mov rax, 1
  # mov rdi, 1
  # mov rsi, r10
  # mov rdx, 1
  # syscall
  '.' => [0x48, 0xC7, 0xC0, 0x01, 0x00, 0x00, 0x00,
          0x48, 0xC7, 0xC7, 0x01, 0x00, 0x00, 0x00,
          0x4C, 0x89, 0xD6,
          0x48, 0xC7, 0xC2, 0x01, 0x00, 0x00, 0x00,
          0x0F, 0x05].pack('c*'),
  # mov rax, 0
  # mov rdi, 0
  # mov rsi, r10
  # mov rdx, 1
  # syscall
  ',' => [0x48, 0xC7, 0xC0, 0x00, 0x00, 0x00, 0x00,
          0x48, 0xC7, 0xC7, 0x00, 0x00, 0x00, 0x00,
          0x4C, 0x89, 0xD6,
          0x48, 0xC7, 0xC2, 0x01, 0x00, 0x00, 0x00,
          0x0F, 0x05].pack('c*')
}.freeze

# From https://github.com/eliben/code-for-blog/blob/master/2017/bfjit/jit_utils.cpp
def compute_jump_offset(from, to)
  if to >= from
    diff = to - from
    raise 'offset too large' unless diff < (1 << 31)
    diff
  else
    # Here the diff is negative, so we need to encode it as 2s complement.
    diff = from - to
    raise 'offset too large' unless (diff - 1) < (1 << 31)
    (~diff + 1) & 0xFFFFFFFF
  end
end

# XXX: This function generates x86_64 assembly for Linux (this is not portable).
def compile_bf(bf, memory)
  stack = []
  # movabs r10, @memory (in little-endian)
  asm = "\x49\xBA".b + "#{[memory.address].pack('Q<')}"
  bf.each do |instruction|
    case instruction
    when '>', '<', '+', '-', '.', ','
      asm << INSTRUCTIONS_MAPPING.fetch(instruction)
    when '['
      asm << "\x41\x80\x3A\x00".b # cmpb [r10], 0
      stack << asm.size # Save the offset where we will patch the jump.
      # Insert a placeholder of 6 bytes (2 for JZ + 4 for the address).
      asm << "\x0F\x84\x00\x00\x00\x00".b
    when ']'
      raise 'unmatched ]' if stack.empty?
      asm << "\x41\x80\x3A\x00".b # cmpb [r10], 0
      jz_pos     = stack.pop    # Address of the JZ to patch.
      start_loop = jz_pos + 6   # Address of the first instruction of the loop body.
      end_loop   = asm.size + 6 # Address of the first instruction after the loop body.
      # Generate the jump to the start of the loop (using JNZ).
      offset = compute_jump_offset(end_loop, start_loop)
      asm << "\x0F\x85".b << [offset].pack('L<') # L< because little endian!
      # Go back to patch the jump to the end of the loop.
      offset = compute_jump_offset(start_loop, end_loop)
      asm[jz_pos, 6] = "\x0F\x84".b + [offset].pack('L<')
    else
      raise "invalid instruction: #{instruction}"
    end
  end
  raise 'unmatched [' unless stack.empty?
  asm << "\xC3".b # ret
end

if __FILE__ == $PROGRAM_NAME
  abort 'Missing argument: expected filename' if ARGV.empty?
  bf_code = File.read(ARGV[0]).chars.select! { |c| INSTRUCTION_SET.include? c }
  memory  = FFI::MemoryPointer.new(:uchar, 30_000)
  bf_prog = JitFunction.new(:void, [], compile_bf(bf_code, memory))
  begin
    bf_prog.call
  ensure
    bf_prog.free
    memory.free
  end
end
