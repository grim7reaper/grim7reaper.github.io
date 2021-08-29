#!/usr/bin/env ruby
# encoding: utf-8

require 'ffi'

# Create a function from bytecode.
class JitFunction
  # Create a new JIT function
  #
  # `ret`:  the return type
  # `args`: the arguments types
  # `code`: the bytecode
  def initialize(ret, args, code)
    @size = code.bytesize
    # Map the memory as read-write.
    @address = Internal.mmap(nil, @size, Internal::PROT_RW,
                             Internal::MAP_PRIVATE | Internal::MAP_ANONYMOUS,
                             -1, 0)
    raise 'cannot map memory' if @address == Internal::MAP_FAILED
    # Write the code.
    @address.put_string(0, code)
    # Re-map the memory as read-execute.
    status = Internal.mprotect(@address, @size, Internal::PROT_RX)
    raise "cannot change memory's permission" if status == -1
    @func = FFI::Function.new(ret, args, @address, convention: :default)
  end

  def call(*args)
    @func.call(*args)
  end

  def free
    Internal.munmap(@address, @size)
  end

  # A thin wrapper around mmap functions.
  # XXX: This is not portable, it's a quick'n'dirty wrapper!
  module Internal
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    attach_function 'mmap',     %i[pointer size_t int int int off_t], :pointer
    attach_function 'mprotect', %i[pointer size_t int], :int
    attach_function 'munmap',   %i[pointer size_t], :int

    PROT_NONE  = 0x0 # Data cannot be accessed.
    PROT_READ  = 0x1 # Data can be read.
    PROT_WRITE = 0x2 # Data can be written.
    PROT_EXEC  = 0x4 # Data can be executed.

    PROT_RW = PROT_READ | PROT_WRITE
    PROT_RX = PROT_READ | PROT_EXEC

    MAP_SHARED    = 0x1   # Share changes.
    MAP_PRIVATE   = 0x2   # Changes are private.
    MAP_ANONYMOUS = 0x20  # Don't use a file.

    MAP_FAILED = FFI::Pointer.new(:void, -1)
  end
  private_constant :Internal
end

if __FILE__ == $PROGRAM_NAME
  # mov rax, rdi
  # add rax, 4
  # ret
  code = "\x48\x89\xf8\x48\x83\xc0\x04\xc3"
  func = JitFunction.new(:long, [:long], code)
  begin
    puts func.call(-100)
  ensure
    func.free
  end
end
