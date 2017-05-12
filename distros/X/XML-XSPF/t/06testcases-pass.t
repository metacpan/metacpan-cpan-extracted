use Test::More 'tests' => '3';

BEGIN {
	use_ok('XML::XSPF');
};

my @files = qw(
	playlist-extensive.xspf
	track-extensive.xspf
);

for my $file (@files) {

	my $xspf = eval { XML::XSPF->parse("data/testcase/pass/$file") };

	ok($xspf->isa('XML::XSPF'), '$xspf->isa(XML::XSPF)');
}
