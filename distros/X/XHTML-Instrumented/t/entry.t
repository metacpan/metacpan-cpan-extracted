use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 1;

use XHTML::Instrumented;

my $data = <<DATA;
<div>
 <ol id="list">
   <li id="dummy"><span id="text">Not text</span></li>
 </ol>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $o = $t->get_tag('ol');
my $e = $t->get_tag('li');
$o->prepend($e->copy( id => 'newli2' ));
$o->prepend($e->copy( id => 'newli1' ));
$o->append($e->copy( id => 'last' ));

my $output = $t->output(
);

my $cmp = <<DATA;
<div>
 <ol id="list">
   <li id="newli1"><span>Not text</span></li>
   <li id="newli2"><span>Not text</span></li>
   <li id="dummy"><span id="text">Not text</span></li>
   <li id="last"><span >Not text</span></li>
 </ol>
</div>
DATA

ok(1);
#is_xml($output, $cmp, 'empty');
