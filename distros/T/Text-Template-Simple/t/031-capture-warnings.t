#!/usr/bin/env perl -w
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use Text::Template::Simple;
use MyUtil;

my @p = (
    capture_warnings => 1,
);

ok( my $t = Text::Template::Simple->new( @p ), 'Got the object' );

ok( my $got = $t->compile(q/Warn<%= my $r %>this/), 'Compile' );

my $w    = 'Warnthis[warning] Use of uninitialized value';
my $want = "$w in concatenation (.) or string at <ANON> line 1.\n";

is( $got, $want, 'Warning captured' );
