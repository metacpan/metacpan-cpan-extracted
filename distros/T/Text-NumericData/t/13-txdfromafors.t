#!perl -T

use Test::More tests => 2;
use File::Compare;
use Text::NumericData::App::txdfromafors;

my $app = Text::NumericData::App::txdfromafors->new();


my $prefix = 't/testdata';
my @defcon = ("--config=testdata/default.conf");

ok( txdtest([@defcon, '--lineend=UNIX'], 'afors-iv.dat', 'afors-iv_out.dat'), 'AFORS-HET iv' );
ok( txdtest([@defcon, '--lineend=UNIX'], 'afors-res.dat', 'afors-res_out.dat'), 'AFORS-HET res' );

sub txdtest
{
	my ($args, $infile, $reffile) = @_;
	my $outstr;
	open(my $in, '<', "$prefix/$infile");
	open(my $out, '>', \$outstr);
	$app->run($args, $in, $out);
	close($out);
	close($in);

	open($out, '<', \$outstr);
	if(compare($out, "$prefix/$reffile") == 0)
	{
		return 1;
	}
	else
	{
		print STDERR "difference in data .. debug";
		close($out);
		print STDERR "$outstr";
		return 0;
	}
}
