
use strict;
use warnings;
use Test::More;

use XML::Filter::RemoveEmpty;
eval {
	require XML::SAX::Machines;
	import XML::SAX::Machines qw( :all );
};
if ($@) {
	plan skip_all => "XML::SAX::Machines required for these tests";
}

my $xml0 = <<'XML0';
<?xml version='1.0'?>
<abc>
	<def>
		<ghi>hello,</ghi>
		<jkl> </jkl>
		<mno>
			world <!-- here is a comment, part 1 -->
		</mno>
		<pqr>
			!
			<stu></stu>
		</pqr>
	</def> <!-- This is also a comment -->
	<vwx>
		<yz>
		</yz>
	</vwx>
</abc>
XML0

my @tests = (
	{},	# default arguments
	{
		TrimWhitespace	=> 'always',
	},
	{
		TrimWhitespace	=> 'only',
	},
#	{
#		TrimWhitespace	=> 'always',
#		Comments		=> 'preserve',
#	},
#	{
#		TrimWhitespace	=> 'only',
#		Comments		=> 'preserve',
#	},
#	{
#		TrimWhitespace	=> 'always',
#		Comments		=> 'strip',
#	},
#	{
#		TrimWhitespace	=> 'only',
#		Comments		=> 'strip',
#	},
#	{
#		Comments		=> 'preserve',
#	},
	{
		Comments		=> 'strip',
	},
);

my @results = (
	qq{<?xml version='1.0'?><abc><def><ghi>hello,</ghi><mno>world</mno><pqr>!</pqr></def></abc>},
	qq{<?xml version='1.0'?><abc><def><ghi>hello,</ghi><mno>world</mno><pqr>!</pqr></def></abc>},
	qq{<?xml version='1.0'?><abc><def><ghi>hello,</ghi><mno>
			world </mno><pqr>
			!
			</pqr></def></abc>},
	qq{<?xml version='1.0'?><abc><def><ghi>hello,</ghi><mno>world</mno><pqr>!</pqr></def></abc>},
);

my @xmls = (
	$xml0,
	$xml0,
	$xml0,
	$xml0,
);

plan tests => scalar @tests;
for my $i (0 .. $#tests) {
	my ($test, $xml, $result) = ($tests[$i], $xmls[$i], $results[$i]);
	my $filter = XML::Filter::RemoveEmpty->new(%$test);
	my $output;
	my $machine = Pipeline($filter => \$output);
	$machine->parse_string($xml);
	is($output, $result, "test " . ($i + 1));
}

