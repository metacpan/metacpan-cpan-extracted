#! perl

use strict;
use warnings;

use Test::More;

use Unix::ResID qw/getresuid getresgid/;

my ($ruid, $euid, $suid) = getresuid();

is $ruid, $<, "RUID is $<";
is $euid, $>, "EUID is $>";

my ($rgid, $egid, $sgid) = getresgid();

is $rgid, 0+$(, "RGID is $(";
is $egid, 0+$), "EGID is $)";

done_testing;

