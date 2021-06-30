#perl
use strict;
use warnings;

$Throwable::_TEST_MOOSE = 1;
use lib '.';
do "t/basic.t";
