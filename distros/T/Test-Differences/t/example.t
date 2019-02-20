#!perl

use strict;
use warnings;
my $x;

my $demo = $ENV{DEMO};

eval <<'PRELOAD' ? eval <<'TEST' : ( $x = $@, eval <<'FALLBACK' );
    use Test::More;
    1;
PRELOAD
    use Test::Differences;

    plan tests => 3 ;

    print "#\n# This test misuses TODO:",
          " these TODOs are actually real tests.\n#\n"
        unless $demo;
    TODO: {
        local $TODO = "testing failure, not really a TODO" unless $demo;
        my @docs = (
            join( "", map "this is line $_\n", qw( 1 2 3 ) ),
            join( "", map "this is line $_\n", qw( 1 b 3 ) )
        );
        eq_or_diff @docs, "differences in text";

        @docs = ( ( "        indented\n" x 3 ) x 2 );

        $docs[1] =~ s/(^..*?^)\s+/$1\t/ms or die "Can't subst \\t for ' '";

        eq_or_diff @docs, "differences in whitespace";

        eq_or_diff( Test::Builder->new, [ "Dry, humorless message" ] );
    }
TEST
    use Test;

    plan tests => 1;

    skip $x, "" ;
FALLBACK

die $@ if $@;
