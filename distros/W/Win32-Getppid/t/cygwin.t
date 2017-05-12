use strict;
use warnings;
use Test::More;
use Win32::Getppid;

plan skip_all => 'cygwin only' unless $^O =~ /^(cygwin|msys)$/;
plan tests => 3;

my $cygwin_ppid = getppid;
my $win_ppid    = Win32::Getppid::getppid;

like $cygwin_ppid, qr{^[0-9]+$}, "cygwin_ppid = $cygwin_ppid";
like $win_ppid, qr{^[0-9]+$}, "win_ppid = $win_ppid";
isnt $cygwin_ppid, $win_ppid, "they aren't the same";
