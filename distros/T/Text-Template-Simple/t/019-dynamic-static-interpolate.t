#!/usr/bin/env perl -w
use strict;
use warnings;
use lib qw(t/lib lib);
use Test::More qw( no_plan );
use Text::Template::Simple;
use MyUtil;

ok( my $t   = Text::Template::Simple->new(),           'Got the object' );
ok( my $out = $t->compile( 't/data/interpolate.tts' ), 'Compile'        );

_p "OUTPUT($out)\n";

my $expect = confirm();

ok( $out         , 'Interpolated dynamic & static include' );
is( $out, $expect, 'Interpolated include has correct data' );

sub confirm {
    return <<"CONFIRMED";

Test: $^O
Test: <%= \$^O %>
Test: $^O
Test: <%= \$^O %>
CONFIRMED
}
