use Test::More tests => 2;

BEGIN { use_ok('Text::CSV::Separator', 'get_separator') };

can_ok( __PACKAGE__, 'get_separator' );

