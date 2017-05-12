use Test::More tests => 3;

BEGIN {
use_ok( 'Text::Fold' );
}

diag( "Testing Text::Fold $Text::Fold::VERSION" );

ok(defined &Text::Fold::fold_text, 'Text::Fold::fold_text() defined');
ok(defined &fold_text, 'fold_text() imported via import()');