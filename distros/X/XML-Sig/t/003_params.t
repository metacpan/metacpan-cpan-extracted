# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN {
    use_ok( 'XML::Sig' );
}

my $sig = XML::Sig->new( { key => 't/rsa.private.key' } );
isa_ok( $sig, 'XML::Sig' );

is( $sig->canonicalizer, 'XML::CanonicalizeXML', 'Default for canonicalizer is XML::CanonicalizeXML' );
is( $sig->key, 't/rsa.private.key', 'Key is stored in object' );

dies_ok { $sig = XML::Sig->new(); $sig->sign('<foo />') } 'sign should die when called without a key being specified';


