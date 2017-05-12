# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok( 'URL::Signature::Google::Maps::API' ); }

my $object = URL::Signature::Google::Maps::API->new ();
isa_ok ($object, 'URL::Signature::Google::Maps::API');

