#!perl -T

use Test::More tests => 1;
use Text::NumericData::App::txdconstruct;
use Text::NumericData::App::txdstatistics;
use lib 't';
use txdtestutil;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdstatistics->new();

my $consapp = Text::NumericData::App::txdconstruct->new();
my $indata;
open(my $indata_h, '>', \$indata);
$consapp->run([@defcon, '-n=10', '[1]=C0; [2]=42'], undef, $indata_h);
close($indata_h);

ok( txdtestutil::txdtest( $app
,	[
		@defcon, '-N=d', '-N.=s', '-N.=0.2f', '-N.=0.2f'
	, '--lineend=UNIX'
	]
, \$indata, "$prefix/statistics.dat", 1.1e-2
), 'statistics 1' );
