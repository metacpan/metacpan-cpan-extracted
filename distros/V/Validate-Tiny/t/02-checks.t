#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 23;
use Validate::Tiny ':all';

my $r = { fields => [qw/a b/] };
my ( $i, $o );
my @checks;
my $c = sub {
    return unless defined $_[0] && $_[0] ne '';
    return $_[0] =~ /^\w+$/ ? undef : 'message';
};

# Single
$r->{checks} = [ a => is_required() ];
$i = { a => 'a', b => 'b' };
$o = { success => 1, data => $i, error => {} };
is_deeply validate( $i, $r ), $o;

$i = { a => '', b => 'b' };
$o = { success => 0, data => $i, error => { a => 'Required' } };
is_deeply validate( $i, $r ), $o;

$i = { a => 0, b => 'b' };
$o = { success => 1, data => $i, error => {} };
is_deeply validate( $i, $r ), $o;

$i = { b => 'b' };
$o = { success => 0, data => $i, error => { a => 'Required' } };
is_deeply validate( $i, $r ), $o;

# Combine fields in the left side
@checks = (
    [ [qw/a b/] => is_required() ],
    [ qr/.+/ => is_required() ]
);

for ( @checks ) {
    $r->{checks} = $_;
    $i = { a => '', b => 'b' };
    $o = { success => 0, data => $i, error => { a => 'Required' } };
    is_deeply validate( $i, $r ), $o;

    $i = { a => 'a', b => '' };
    $o = { success => 0, data => $i, error => { b => 'Required' } };
    is_deeply validate( $i, $r ), $o;

    $i = { b => '' };
    $o = { success => 0, data => $i, error => { a => 'Required', b => 'Required' } };
    is_deeply validate( $i, $r ), $o;
}


# Chaining
@checks = (
    [ a => is_required(),   a => $c ],
    [ a => [ is_required(), $c ] ],
    [ a => [ [ is_required() ], [$c] ] ]
);

for (@checks) {
    $r->{checks} = $_;

    $i = { a => 'a' };
    $o = { success => 1, data => $i, error => {} };
    is_deeply validate( $i, $r ), $o;

    $i = { a => '' };
    $o = { success => 0, data => $i, error => { a => 'Required' } };
    is_deeply validate( $i, $r ), $o;

    $i = { a => '%' };
    $o = { success => 0, data => $i, error => { a => 'message' } };
    is_deeply validate( $i, $r ), $o;
}

# Non-required
$r->{checks} = [ a => $c ];
$i = { a => 'w' };
$o = { success => 1, data => $i, error => {} };
is_deeply validate($i, $r), $o;

$i = { a => '%' };
$o = { success => 0, data => $i, error => { a => 'message' } };
is_deeply validate($i, $r), $o;

$i = { a => '' };
$o = { success => 1, data => $i, error => {} };
is_deeply validate($i, $r), $o;

$i = { b => 'b' };
$o = { success => 1, data => $i, error => {} };
is_deeply validate($i, $r), $o;

