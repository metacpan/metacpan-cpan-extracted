use Test::More tests => 1;
use Test::Deep;

use Throw::Back;
ok( defined &throw::back, 'throw::back via use' );
