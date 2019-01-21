#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Types::Standard qw(Int);
use Tie::CheckVariables;

my $error;
Tie::CheckVariables->on_error( sub { $error = 'This was a test' } );

is Tie::CheckVariables::register( 'age' ), undef;

my $re =Tie::CheckVariables->register( 'plz' => qr/\A[0-9]{5}\z/ );

tie my $plz, 'Tie::CheckVariables', 'plz';

$plz = 99;
is $error, 'This was a test';
$error = '';

$plz = 'a';
is $error, 'This was a test';
$error = '';

$plz = '01238';
is $error, '';

done_testing;
