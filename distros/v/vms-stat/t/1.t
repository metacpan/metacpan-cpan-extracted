# Before `mmk install' is performed this script should be runnable with
# Either `perl "-Mblib" t/1.t' or `mmk test'.
# After `mmk install' it should work as `perl t/1.t'

#########################

use File::Path; # access to rmtree which is used to clean up
use VMS::Stat; 

BEGIN { 
    print "1..5\n";
};

# Under 5.8.1 we could use Test::More, but for earlier perl's that have not
# visited CPAN we could not.  Sorry Michael.
my $t = 1;

print "ok $t\n"; # The use statement compile OK if we got this far.

#########################

my $rc = undef;
# print "# PID used as temp name: $$\n";

++$t;
$rc = VMS::Stat::vmsmkdir( "SYS\$DISK:[.$$]" );
print + defined( $rc ) ? "ok $t\n" : "not ok $t # >$rc< basic mkdir call\n";
# print "# rc from first>$rc<\n";
rmtree( "[.$$]" );

++$t;
$rc = VMS::Stat::vmsmkdir( "SYS\$DISK:[.$$]", 0777 );
print + defined( $rc ) ? "ok $t\n" : "not ok $t # >$rc< mkdir with protection call\n";
rmtree( "[.$$]" );

# This one does not seem to work:
# $rc = VMS::Stat::vmsmkdir( "SYS\$DISK:[.$$]", 0777, 0 );
# ok( defined( $rc ), "mkdir with protection and UIC call" );
# rmtree( "[.$$]" );

++$t;
$rc = VMS::Stat::vmsmkdir( "SYS\$DISK:[.$$]", 0777, 0, 1 );
print + defined( $rc ) ? "ok $t\n" : "not ok $t # >$rc< mkdir with protection, UIC, and version limit call\n";
my $dir_out = `directory\\/full $$.DIR`;
++$t;
print + ( $dir_out =~ m/File attributes:\s+Allocation: \d+, Extend: \d+, Global buffer count: \d+, Default version limit: 1, Contiguous, Directory file/mgs )
          ? "ok $t\n" : "not ok $t # DIRECTORY output\n";
# print "# $dir_out\n";
rmtree( "[.$$]" );

