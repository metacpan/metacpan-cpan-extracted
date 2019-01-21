#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tie::CheckVariables;

my $error;
Tie::CheckVariables->on_error( sub { $error = 'This was a test' } );

tie my $int, 'Tie::CheckVariables', 'integer';
$int = 'a';
is $error, 'This was a test';

Tie::CheckVariables->on_error( [] );
$error = '';
$int = 'a';
is $error, 'This was a test';

done_testing;
