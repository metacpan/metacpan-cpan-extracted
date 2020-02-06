#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'Text::Layout::FontConfig' );
    use_ok( 'Text::Layout' );
}

diag( "Testing Text::Layout $Text::Layout::VERSION, Perl $], $^X" );

eval {
    require HarfBuzz::Shaper;
    HarfBuzz::Shaper->VERSION(0.019);
    diag( "Shaping enabled (HarfBuzz::Shaper $HarfBuzz::Shaper::VERSION)" );
    1;
} || diag( "Shaping disabled (HarfBuzz::Shaper not found)" );

BEGIN {
    use_ok( 'Text::Layout::Markdown' );
    use_ok( 'Text::Layout::PDFAPI2' );
    use_ok( 'Text::Layout::Pango' );
    use_ok( 'Text::Layout::Cairo' );
}
