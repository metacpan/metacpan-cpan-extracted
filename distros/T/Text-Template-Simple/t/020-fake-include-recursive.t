#!/usr/bin/env perl -w
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use Text::Template::Simple;
use Text::Template::Simple::Constants qw(MAX_RECURSION);
use MyUtil;

use constant RECURSE_LIMIT => MAX_RECURSION + 10;

ok( my $t = Text::Template::Simple->new(), 'Got the object' );

sub test {
    ok(my $rv  = $t->compile( q{<%* t/data/test_var.tts %>} ), 'Compile');
    _p "GOT: $rv\n";
    return is( $$, $rv, 'Compile OK' );
}

test() for 0..RECURSE_LIMIT;

ok( 1, 'Fake recursive test did not fail' );
