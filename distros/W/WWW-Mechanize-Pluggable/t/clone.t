#!perl
use warnings;

use strict;
use Test::More tests => 3;

BEGIN {
    use FindBin;

    use lib "$FindBin::Bin/lib";
    use_ok( 'WWW::Mechanize::Pluggable' );
}

my $mech = WWW::Mechanize::Pluggable->new();
isa_ok( $mech, 'WWW::Mechanize::Pluggable' );

my $clone = $mech->clone();
isa_ok( $clone, 'WWW::Mechanize::Pluggable' );
