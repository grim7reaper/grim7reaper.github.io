#!/usr/bin/perl -w
use strict;      # Brainfuck Interpreter | Author: grim7reaper | License: WTFPL

my $t = 30000;   # Size of memory (in octet).
my @mem = (0)x$t;# Memory.
my $code = "";   # Source code.
my $dp = 0;      # Data Pointer.
my $ip = 0;      # Instruction Pointer.
my %l2r = ();    # Pairs of square bracket.
my %r2l = ();    # Pairs of square bracket (reverse of l2r).
my @left = ();   # List of positions of left brackets.
my %symbols =    # Symbols Table: http://aminet.net/dev/lang/brainfuck-2.readme
( ">" => sub{ $dp++; die "Segmentation Fault\n"  if $dp >= $t; },
  "<" => sub{ $dp--; die "Segmentation Fault\n"  if $dp < 0;  },
  "+" => sub{ $mem[$dp]++; $mem[$dp] = 0   if $mem[$dp] > 255; },
  "-" => sub{ $mem[$dp]--; $mem[$dp] = 255 if $mem[$dp] < 0;   },
  "." => sub{ print chr($mem[$dp]);    },
  "," => sub{ $mem[$dp] = ord(getc()); },
  "[" => sub{ $ip = $l2r{$ip - 1} + 1 if $mem[$dp] == 0;   },
  "]" => sub{ $ip = $r2l{$ip - 1}; });

open (SRC, $ARGV[0]) || die "Can't open $ARGV[0]: $!"; # Open source code.
while (<SRC>) { chomp($code .= $_); }  # Concatenate the code into one line.
$code =~ s/[^\+\-\.\[\],<>]//g;        # Removing invalid characters.

my @code = split(//, $code);              # Split code into symbols.
for(my $i = 0; $i < length($code); $i++)  # Analyse symbol per symbol.
{
    push(@left, $i) if $code[$i] eq '[';  # If left bracket:  push.
    if($code[$i] eq ']')                  # If right bracket: pop.
    {
        die "Unmatched ]\n" unless @left; # Right bracket && empty stack = bad.
        $l2r{pop @left} = $i;             # Create pairs for jumps.
    }
} die "Unmatched [\n" if @left;      # End of code && not empty stack = bad.
%r2l = reverse %l2r; 

while($ip < @code)          # Loop of code's interpretation. 
{ 
    my $c = $code[$ip++];   # Read instruction.
    $symbols{$c}->();       # Decode and execute the instruction.
}
