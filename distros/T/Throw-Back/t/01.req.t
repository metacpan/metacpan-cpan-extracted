use Test::More tests => 1;
use Test::Deep;

require Throw::Back;
ok( defined &throw::back, 'throw::back via require' );
