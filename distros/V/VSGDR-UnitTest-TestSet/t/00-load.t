#!perl -T

use Test::More tests => 18;

BEGIN {
    use_ok( 'VSGDR::UnitTest::TestSet' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Representation' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Representation::NET' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Representation::NET::CS' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Representation::NET::VB' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Representation::XLS' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Representation::XML' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Resx' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test::TestCondition' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test::TestCondition::Checksum' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test::TestCondition::EmptyResultSet' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test::TestCondition::ExecutionTime' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test::TestCondition::ExpectedSchema' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test::TestCondition::Inconclusive' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test::TestCondition::NotEmptyResultSet' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test::TestCondition::RowCount' ) || print "Bail out!\n";
    use_ok( 'VSGDR::UnitTest::TestSet::Test::TestCondition::ScalarValue' ) || print "Bail out!\n";
}

diag( "Testing VSGDR::UnitTest::TestSet $VSGDR::UnitTest::TestSet::VERSION, Perl $], $^X" );
