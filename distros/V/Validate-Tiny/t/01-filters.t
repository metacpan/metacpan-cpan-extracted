#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Validate::Tiny ':all';

my $ok;

my $i = { a => 'a', b => 'b' };
my $r = { fields => ['a', 'b'] };

my $filter = sub { ord($_[0]) };

# First
$r->{filters} = [ a => filter('uc') ];
is_deeply validate( $i, $r )->{data},  { a => 'A', b => 'b' };

# Array
$r->{filters} = [ [qw/a b/] => filter('uc') ];
is_deeply validate( $i, $r )->{data},  { a => 'A', b => 'B' };

# Regex 1
$r->{filters} = [ qr/.+/ => filter('uc') ];
is_deeply validate( $i, $r )->{data},  { a => 'A', b => 'B' };

# Regex 2
$r->{filters} = [ qr/b/ => filter('uc') ];
is_deeply validate( $i, $r )->{data},  { a => 'a', b => 'B' };

# Missing field
$r->{filters} = [ a => filter('uc') ];
is_deeply validate( { b => 'b' }, $r )->{data},  { b => 'b' };

# Double filter
$r->{filters} = [ a => [filter('uc'), $filter] ];
is_deeply validate( $i, $r )->{data},  { a => ord('A'), b => 'b' };

$r->{filters} = [ a => [filter('uc'), filter('lc')] ];
is_deeply validate( $i, $r )->{data},  { a => 'a', b => 'b' };

$r->{filters} = [ a => [filter(qw/uc lc/)] ];
is_deeply validate( $i, $r )->{data},  { a => 'a', b => 'b' };

$r->{filters} = [ [qw/a b/] => [filter('uc'), $filter] ];
is_deeply validate( $i, $r )->{data},  { a => ord('A'), b => ord('B') };
is_deeply validate( {}, $r )->{data},  {};

# Deep
$r->{filters} = [ a => [[ filter('uc') ], $filter] ];
is_deeply validate( $i, $r )->{data},  { a => ord('A'), b => 'b' };

# Same field
$r->{filters} = [ a => filter('uc'), a => $filter ];
is_deeply validate( $i, $r )->{data},  { a => ord('A'), b => 'b' };


