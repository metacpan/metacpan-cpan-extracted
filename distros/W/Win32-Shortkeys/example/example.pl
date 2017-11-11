use strict;
use warnings;
#use lib qw(../lib);
use Win32::Shortkeys;

my $s = Win32::Shortkeys->new("kbhook.properties");

$s->run;

