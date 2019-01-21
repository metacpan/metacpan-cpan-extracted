#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Types::Standard qw(Int);
use Tie::CheckVariables;

my $error;
Tie::CheckVariables->on_error( sub { $error = 'This was a test' } );

tie my $int, 'Tie::CheckVariables', sub { no warnings; int $_[0] eq $_[0] };
$int = 99;

is $int, 99;

$int = 'a';

is $error, 'This was a test';

done_testing;
