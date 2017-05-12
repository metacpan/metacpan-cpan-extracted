use Test::More tests => 9;

require_ok('Unix::Whereis');

diag("Testing Unix::Whereis $VERSION");

ok( !defined &whereis,          'whereis() not defined initially-sanity' );
ok( !defined &whereis_everyone, 'whereis_everyone() not defined initially-sanity' );
ok( !defined &pathsep,          'pathsep() not defined initially-sanity' );
Unix::Whereis->import();
ok( defined &whereis,           'whereis() is imported' );
ok( !defined &whereis_everyone, 'whereis_everyone() not imported automatically' );
ok( !defined &pathsep,          'pathsep() not imported' );

Unix::Whereis->import('whereis_everyone');
ok( defined &whereis_everyone, 'whereis_everyone() imported explicitly' );
ok( !defined &pathsep,         'pathsep() still not imported' );
