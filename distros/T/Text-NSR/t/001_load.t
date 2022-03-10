
use Test::More tests => 2;

use lib 'lib';

BEGIN { use_ok( 'Text::NSR' ); }

my $object = Text::NSR->new( filepath => 't/test.nsr' );
isa_ok ($object, 'Text::NSR');


