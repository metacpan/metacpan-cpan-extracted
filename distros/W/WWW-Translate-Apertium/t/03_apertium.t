#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 32;

use_ok( 'WWW::Translate::Apertium') or exit;

my $engine = WWW::Translate::Apertium->new();

isa_ok( $engine, 'WWW::Translate::Apertium' );

# Language pair tests

$engine->from_into( 'es-ca' );
is( $engine->from_into(), 'es-ca', 'Current language pair should be Spanish -> Catalan' );

$engine->from_into( 'ca-es' );
is( $engine->from_into(), 'ca-es', 'Current language pair should be Catalan -> Spanish' );

$engine->from_into( 'es-gl' );
is( $engine->from_into(), 'es-gl', 'Current language pair should be Spanish -> Galician' );

$engine->from_into( 'gl-es' );
is( $engine->from_into(), 'gl-es', 'Current language pair should be Galician -> Spanish' );

$engine->from_into( 'es-pt' );
is( $engine->from_into(), 'es-pt', 'Current language pair should be Spanish -> Portuguese' );

$engine->from_into( 'pt-es' );
is( $engine->from_into(), 'pt-es', 'Current language pair should be Portuguese -> Spanish' );

$engine->from_into( 'es-pt_BR' );
is( $engine->from_into(), 'es-pt_BR', 'Current language pair should be Spanish -> Brazilian Portuguese' );

$engine->from_into( 'oc-ca' );
is( $engine->from_into(), 'oc-ca', 'Current language pair should be Occitan -> Catalan' );

$engine->from_into( 'ca-oc' );
is( $engine->from_into(), 'ca-oc', 'Current language pair should be Catalan -> Occitan' );

$engine->from_into( 'oc_aran-ca' );
is( $engine->from_into(), 'oc_aran-ca', 'Current language pair should be Aranese -> Catalan' );

$engine->from_into( 'ca-oc_aran' );
is( $engine->from_into(), 'ca-oc_aran', 'Current language pair should be Catalan -> Aranese' );

$engine->from_into( 'en-ca' );
is( $engine->from_into(), 'en-ca', 'Current language pair should be English -> Catalan' );

$engine->from_into( 'ca-en' );
is( $engine->from_into(), 'ca-en', 'Current language pair should be Catalan -> English' );

$engine->from_into( 'fr-ca' );
is( $engine->from_into(), 'fr-ca', 'Current language pair should be French -> Catalan' );

$engine->from_into( 'ca-fr' );
is( $engine->from_into(), 'ca-fr', 'Current language pair should be Catalan -> French' );

$engine->from_into( 'fr-es' );
is( $engine->from_into(), 'fr-es', 'Current language pair should be French -> Spanish' );

$engine->from_into( 'es-fr' );
is( $engine->from_into(), 'es-fr', 'Current language pair should be Spanish -> French' );

$engine->from_into( 'ca-eo' );
is( $engine->from_into(), 'ca-eo', 'Current language pair should be Catalan -> Esperanto' );

$engine->from_into( 'es-eo' );
is( $engine->from_into(), 'es-eo', 'Current language pair should be Spanish -> Esperanto' );

$engine->from_into( 'ro-es' );
is( $engine->from_into(), 'ro-es', 'Current language pair should be Romanian -> Spanish' );

$engine->from_into( 'es-en' );
is( $engine->from_into(), 'es-en', 'Current language pair should be Spanish -> English' );

$engine->from_into( 'en-es' );
is( $engine->from_into(), 'en-es', 'Current language pair should be English -> Spanish' );

$engine->from_into( 'cy-en' );
is( $engine->from_into(), 'cy-en', 'Current language pair should be Welsh -> English' );

$engine->from_into( 'eu-es' );
is( $engine->from_into(), 'eu-es', 'Current language pair should be Basque -> Spanish' );

$engine->from_into( 'en-gl' );
is( $engine->from_into(), 'en-gl', 'Current language pair should be English -> Galician' );

$engine->from_into( 'gl-en' );
is( $engine->from_into(), 'gl-en', 'Current language pair should be Galician -> English' );



# Output format tests
is( $engine->output_format, 'plain_text', 'Default output format should be plain text' );

$engine->output_format('marked_text');
is( $engine->output_format, 'marked_text', 'Current output format should be marked text' );

# Create object overriding defaults
my $engine2 = WWW::Translate::Apertium->new(
                                            lang_pair => 'pt-es',
                                            output => 'marked_text',
                                           );

is( $engine2->from_into(), 'pt-es', 'Current language pair should be Portuguese -> Spanish' );
is( $engine2->output_format, 'marked_text', 'Current output format should be marked text' );
