#!/usr/bin/env perl
#===============================================================================
#
#         FILE:  rtorrent_stats
#
#        USAGE:  ./rtorrent_stats
#
#  DESCRIPTION:  This script provides statistics from rtorrent.
#
#      OPTIONS:  ---
# REQUIREMENTS:  Frontier::Client and XML-RPC server.
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Laperche Sylvain (aka grim7reaper), sylvain.laperche@gmx.fr
#      VERSION:  1.1
#      CREATED:  04/08/2010 14:54:39
#     REVISION:  23/01/2011 12:18:28
#===============================================================================
use strict;
use warnings;

use Carp ();
$SIG{__WARN__} = \&Carp::cluck;
$SIG{__DIE__} = \&Carp::confess;

use Frontier::Client;

# Fix 'i8' type problem.
$Frontier::RPC2::scalars{'i8'} = 1;

# Configuration.
use constant server => 'http://grim7reaper.no-ip.info/RPC2';

# Format.
my $default = '${color}${font}';
my $name = '${color}${font URW Gothic L:style=Medium Normal:pixelsize=12}';

if(`ps -C rtorrent` =~ /rtorrent/)
{
    if(`ps -C lighttpd` =~ /lighttpd/)
    {
        my $server = Frontier::Client->new(url => server);

        my $uprate = $server->call('get_up_rate');
        my $downrate = $server->call('get_down_rate');

        my $torrents = $server->call('d.multicall', "active",
            "d.get_base_filename=",
            "d.get_bytes_done=",
            "d.get_size_bytes=",
            "d.get_up_rate=",
            "d.get_down_rate=",
            "d.get_ratio=");

        my @res;
        foreach my $d (@$torrents)
        {
            my $bar;
            my $rate;
            my $up_rate = $d->[3] / 1024;
            my $dl_rate = $d->[4] / 1024;
            my $percent_done = 100 * ($d->[1] / $d->[2]);
            my $ratio = $d->[5] / 1000;

            if($percent_done >= 75)    { $bar = '${color green}';  }
            elsif($percent_done >= 50) { $bar = '${color orange}'; }
            elsif($percent_done >= 25) { $bar = '${color yellow}'; }
            else                       { $bar = '${color red}';    }

            if($ratio > 1)       { $rate = '${color green}'; }
            elsif($ratio > 0.80) { $rate = '${color yellow}'; }
            else                 { $rate = '${color red}';   }

            push(@res,
                sprintf("$name%.37s$default".
                    '${alignr}${color2}Up: ${color}%4.1f kB/s    '.
                    '${alignr}${color2}Down: ${color}%4.1f kB/s'."\n".
                    " "x5 ."$bar%3.2f%%" .
                    '${goto 70}${execbar echo %3.0f }'.$default.
                    '${alignr}'.$rate." Ratio: %2.2f",
                    $d->[0], $up_rate, $dl_rate, $percent_done, $percent_done,
                    $ratio)
            );
        }
        print join("\n\n", @res), "\n";
    }
    else
    {
        print "Server is not running.";
    }
}
else
{
    print "rtorrent is not running.";
}
