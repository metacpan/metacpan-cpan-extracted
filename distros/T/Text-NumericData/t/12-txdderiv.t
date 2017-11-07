#!perl -T

use Test::More tests => 7;
use File::Compare;
use Text::NumericData::App::txdconstruct;
use Text::NumericData::App::txdderiv;
use lib 't';
use txdtestutil;

my $app = Text::NumericData::App::txdderiv->new();


my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $consapp = Text::NumericData::App::txdconstruct->new();
my $indata;
open(my $indata_h, '>', \$indata);
$consapp->run([@defcon, '-n=10', '[1]=C0; [2] = [1]**2 + 7; [3] = sqrt([@defcon, 1]);'], undef, $indata_h);
close($indata_h);

ok( txdtestutil::txdtest( $app
,	[@defcon, '-N=.3f', '--lineend=UNIX']
,	\$indata, "$prefix/deriv1.dat", 1.1e-3
), 'central diff in-place' );
ok( txdtestutil::txdtest( $app
,	[@defcon, '-N=.3f', '--append', '--lineend=UNIX']
,	\$indata, "$prefix/deriv2.dat", 1.1e-3
), 'central diff append' );
ok( txdtestutil::txdtest( $app
,	[@defcon, '-N=.3f', '--dualgrid', '--lineend=UNIX']
,	\$indata, "$prefix/deriv3.dat", 1.1e-3
), 'dualgrid in-place' );
# test title modification, hack for now (or forever) since txdfilter is not yet in place
$indata = "#data\n#\"x\"	\"y\"	\"z\"\n".$indata;
ok( txdtestutil::txdtest( $app
,	[@defcon, '-N=.3f', '--lineend=UNIX']
,	\$indata, "$prefix/deriv4.dat", 1.1e-3
), 'central diff in-place title' );
ok( txdtestutil::txdtest( $app
,	[@defcon, '-N=.3f', '--append', '--lineend=UNIX']
,	\$indata, "$prefix/deriv5.dat", 1.1e-3
), 'central diff append title' );
# also non-default columns
ok( txdtestutil::txdtest( $app
,	[@defcon, '-N=.3f', '--append', '-x=3', '-y=1', '--lineend=UNIX']
,	\$indata, "$prefix/deriv6.dat", 1.1e-3
), 'central diff cols append' );
ok( txdtestutil::txdtest( $app
,	[@defcon, '-N=.3f', '--dualgrid', '-x=2', '-y=3', '-y.=1', '--lineend=UNIX']
,	\$indata, "$prefix/deriv7.dat", 1.1e-3
), 'dualgrid in-place cols' );
