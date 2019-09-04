#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'Text::Layout::FontConfig' );
    use_ok( 'Text::Layout' );
}

diag( "Testing Text::Layout $Text::Layout::VERSION, Perl $], $^X" );

BEGIN {
    use_ok( 'Text::Layout::Markdown' );
    use_ok( 'Text::Layout::PDFAPI2' );
    use_ok( 'Text::Layout::Pango' );
    use_ok( 'Text::Layout::Cairo' );
}
