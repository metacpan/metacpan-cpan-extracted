# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

BEGIN {
    use_ok('ZOOM::IRSpy');
}

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;

my $irspy_to_zeerex_xsl = 'xsl/irspy2zeerex.xsl';

$ZOOM::IRSpy::irspy_to_zeerex_xsl = $irspy_to_zeerex_xsl
  if $irspy_to_zeerex_xsl;

my $dbname =  ZOOM::IRSpy::connect_to_registry();
my $spy = new ZOOM::IRSpy( $dbname, "admin", "fruitbat" );

isa_ok( $spy, 'ZOOM::IRSpy' );

# test for failure if template not exists
eval {
    $ZOOM::IRSpy::irspy_to_zeerex_xsl = '/nonexist';
    $ZOOM::IRSpy::xslt_max_depth = 100;
    $spy = new ZOOM::IRSpy( $dbname, "admin", "fruitbat" );
};

like( $@, qr/No such file or directory/, "xslt configure test" );

1;

__DATA__;
foo
