package RoleWithMethod;

# test case by Smylers from:
# https://rt.cpan.org/Public/Bug/Display.html?id=124745

use strict;
use warnings;
use true;

use Function::Parameters;
use Moo::Role;

sub test { 42 }

method foo () {}
