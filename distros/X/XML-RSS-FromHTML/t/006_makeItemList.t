use Test::More tests => 1;
use strict;
use FindBin;
BEGIN {
	require "$FindBin::RealBin/Test.pm";
}
my $rss = XML::RSS::FromHTML::Test->new();

# load html text
local($/) = undef;
open(my $fh,"$FindBin::RealBin/Test.html") or die $!;
my $html = <$fh>;

# makeItemList
my $expect = [
	{ title => 'to link 01', link => 'http://link/01.html' },
	{ title => 'to link 02', link => 'http://link/02.html' },
	{ title => 'リンクその 03', link => 'http://link/03.html' },
];
my $list = $rss->makeItemList($html);
is_deeply($list,$expect);
