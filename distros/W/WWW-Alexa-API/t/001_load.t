#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN { use_ok( 'WWW::Alexa::API' ) || print "Cannot load WWW::Alexa::API"; }

my $object = WWW::Alexa::API->new ();
isa_ok ($object, 'WWW::Alexa::API');