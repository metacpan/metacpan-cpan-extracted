#!perl

use Test::More tests => 1;
use Text::NumericData::App::txdnorm;
use File::Compare;
use lib 't';
use txdtestutil;

my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

my $app = Text::NumericData::App::txdnorm->new();

ok( txdtestutil::txdtest( $app
,	[@defcon, '--lineend=UNIX', '-N=.3f']
,	"$prefix/test1.dat", "$prefix/test-txdnorm1.dat", 1.1e-3
), 'y norm' );
