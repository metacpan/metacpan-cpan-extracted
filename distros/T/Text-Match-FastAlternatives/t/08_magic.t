#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use Text::Match::FastAlternatives;
use Tie::Scalar;

sub _magic_ok {
    my ($expected, $tmfa, $method, $args, $desc) = @_;
    my ($value, @args) = @$args;
    tie my $magical, 'Tie::StdScalar', $value;
    my $ret = $tmfa->$method($magical, @args);
    ok($expected ? $ret : !$ret,
       "$desc: $method " . ($expected ? 'expected' : 'unexpected'));
}

sub magic_yes_ok { _magic_ok(1, @_) }
sub magic_no_ok  { _magic_ok(0, @_) }

for my $tmfa (Text::Match::FastAlternatives->new('hello')) {
    my $desc = 'tied scalar target';
    magic_yes_ok($tmfa, match => ['__hello__'],   $desc);
    magic_no_ok( $tmfa, match => ['__goodbye__'], $desc);
    magic_no_ok( $tmfa, match_at => ['__hello__', 0], $desc);
    magic_yes_ok($tmfa, match_at => ['__hello__', 2], $desc);
    magic_yes_ok($tmfa, exact_match => ['hello'], $desc);
    magic_no_ok( $tmfa, exact_match => ['__hello__'], $desc);
}

{
    tie my $hello, 'Tie::StdScalar', 'hello';
    my $tmfa = Text::Match::FastAlternatives->new($hello);
    isa_ok($tmfa, 'Text::Match::FastAlternatives',
           'construct instance from tied scalar');
    ok($tmfa->match('__hello__'), 'tied scalar needle: match');
}
