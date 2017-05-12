#!/usr/bin/env perl -w
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use Text::Template::Simple;
use MyUtil;

ok( my $t   = Text::Template::Simple->new(),       'Got the object' );
ok( my $out = $t->compile( 't/data/dynamic.tts' ), 'Compile'        );

_p "OUTPUT: $out\n";

is( $out, confirm(), 'Valid output from dynamic inclusion' );

sub confirm {
    return <<'CONFIRMED';
RAW 1: raw content <%= $$ %>
RAW 2: raw content <%= $$ %>
RAW 3: raw content <%= $$ %>
CONFIRMED
}
