#!perl -T

use Test::More tests => 6;

BEGIN {
    use_ok( 'Text::NumericData' ) || print "Bail out!\n";
}

BEGIN {
    use_ok( 'Text::NumericData::File' ) || print "Bail out!\n";
}

BEGIN {
    use_ok( 'Text::NumericData::Calc' ) || print "Bail out!\n";
}

BEGIN {
    use_ok( 'Text::NumericData::FileCalc' ) || print "Bail out!\n";
}

BEGIN {
    use_ok( 'Text::NumericData::Stat' ) || print "Bail out!\n";
}

BEGIN {
    use_ok( 'Text::NumericData::App' ) || print "Bail out!\n";
}

diag( "Testing Text::NumericData $Text::NumericData::VERSION, Perl $], $^X" );
