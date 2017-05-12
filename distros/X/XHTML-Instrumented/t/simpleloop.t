use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <div id="list"><span id="dummy">Not text</span><br/></div>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    list => $t->loop(
        headers => ['dummy'],
	data => [
	    [ 'test1' ],
	    [ 'test2' ],
	    [ 'test3' ],
         ],
    ),
);

my $cmp = <<DATA;
<div>
 <div id="list">
   <span id="dummy.1">test1</span>
   <br/>
   <span id="dummy.2">test2</span>
   <br/>
   <span id="dummy.3">test3</span>
   <br/>
 </div>
</div>
DATA

TODO: {
local $xTODO = 'bug';
is_xml($output, $cmp, 'simple loop');
}

TODO: {
    local $xTODO = 'bug';
    is($output, <<EOP, 'compare');
<div>
 <div id="list"><span id="dummy.1">test1</span><br/><span id="dummy.2">test2</span><br/><span id="dummy.3">test3</span><br/></div>
</div>
EOP
}

