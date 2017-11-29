#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 18;

BEGIN {
    use_ok( 'Validator::Lazy' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::TestRole::ExtRoleExample' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::TestRole::FieldDep' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Composer' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Notifications' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::Required' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::Test' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::Email' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::Phone' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::MinMax' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::IP' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::Trim' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::RegExp' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::Form' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::IsIn' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::Case' ) || print "Bail out!\n";
    use_ok( 'Validator::Lazy::Role::Check::CountryCode' ) || print "Bail out!\n";
}

diag( "Testing Validator::Lazy $Validator::Lazy::VERSION, Perl $], $^X" );
