#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Find::Scalar;

my $finder = Text::Find::Scalar->new();

local $/;
my $string = <DATA>;
my $test = $finder->find($string);

$finder->_counter(1000);
is $finder->nextElement, undef;

done_testing();

__DATA__
$foo
${foo}
