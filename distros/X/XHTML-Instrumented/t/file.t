use Test::More;
use Test::XML;

plan tests => 7;

use_ok( 'XHTML::Instrumented' );

$x = XHTML::Instrumented->new(
    name => 'test',
    path => 'examples',
    cachepath => '/tmp/test1',
);

is($x->path(), 'examples', 'path');
is($x->cachepath(), '/tmp/test1', 'cachepath');

my $output = $x->instrument(
    content_tag => 'body',
    control => {},
);

my $cmp = <<DATA;
<div id="all">
test
</div>
DATA

is_xml($output, $cmp, 'test');

my $cachefile = $x->cachefilename;

ok(-r $cachefile, 'file created');

my $y = XHTML::Instrumented->new(
    name => 'test',
    path => 'examples',
);

$output = $y->instrument(
    content_tag => 'body',
    control => {},
);

is_xml($output, $cmp, 'test');

unlink 'examples/test.cxi' or die $!;

ok(!-r 'examples/test.cxi', 'file deleted');
