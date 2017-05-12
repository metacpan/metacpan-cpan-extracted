use Test::More tests => 3;

require_ok( 'Text::Fold' );

diag( "Testing Text::Fold $Text::Fold::VERSION" );

ok(defined &Text::Fold::fold_text, 'Text::Fold::fold_text() defined');
ok(!defined &fold_text, 'fold_text() not imported when import() not called');