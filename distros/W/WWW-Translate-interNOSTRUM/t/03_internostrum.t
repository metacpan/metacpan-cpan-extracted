#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;

use_ok( 'WWW::Translate::interNOSTRUM') or exit;

my $engine = WWW::Translate::interNOSTRUM->new();

isa_ok( $engine, 'WWW::Translate::interNOSTRUM' );

# Language pair tests
is( $engine->from_into(), 'ca-es',
   'Default language pair should be Catalan -> Spanish' );

$engine->from_into( 'es-ca' );
is( $engine->from_into(), 'es-ca',
    'Current language pair should be Spanish -> Catalan' );

$engine->from_into( 'es-va' );
is( $engine->from_into(), 'es-va',
    'Current language pair should be Spanish -> Valencian Catalan' );


# Output format tests
is( $engine->output_format, 'plain_text',
    'Default output format should be plain text' );

$engine->output_format('marked_text');
is( $engine->output_format, 'marked_text',
    'Current output format should be marked text' );

# Create object overriding defaults
my $engine2 = WWW::Translate::interNOSTRUM->new(
                                                lang_pair => 'es-va',
                                                output => 'marked_text',
                                                );

is( $engine2->from_into(), 'es-va',
    'Current language pair should be Spanish -> Valencian Catalan' );
is( $engine2->output_format, 'marked_text',
    'Current output format should be marked text' );
