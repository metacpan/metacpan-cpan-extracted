# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Text::XmlMatch' ); }
use Text::XmlMatch;

my $object = Text::XmlMatch->new('extras/config.xml');
isa_ok ($object, 'Text::XmlMatch');


