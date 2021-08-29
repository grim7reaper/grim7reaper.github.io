#!/usr/bin/env ruby
# Interpréteur brainfuck Ruby 1.9
# Codé par Ouranos
# Merci à grim7reaper pour son aide
# License : aGPL
f = File.open(ARGV[0], "r")
s = ""
dp = 0
ip = 0
table = Array.new(30000, 0)

f.each do |l|
	s += l.chomp
end

left = Array.new
hash = Hash.new
i = 0
code = s.split(//)
while i < s.length do
	case code[i]
        when "[" then left.push(i) 
        when "]" then raise "Syntax error : unmatched ]" if left.size == 0
                      hash[left.pop] = i
	end
	i+=1
end
raise "Syntax error : unmatched [" if left.size != 0

while ip < code.size
	case code[ip]
        when '>' then dp+=1; raise "Segmentation Fault" if dp >= 30000
        when '<' then dp-=1; raise "Segmentation Fault" if dp < 0
        when '+' then table[dp] = (table[dp] == 255) ? 0   : table[dp] + 1
        when '-' then table[dp] = (table[dp] == 0)   ? 255 : table[dp] - 1
        when '.' then print table[dp].chr
        when ',' then table[dp]=STDIN.getc.ord
        when '[' then ip = hash[ip] if table[dp] == 0
        when ']' then ip = hash.invert[ip] - 1
	end
    ip+=1
end
