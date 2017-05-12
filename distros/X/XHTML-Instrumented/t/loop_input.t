use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 3;

require_ok( 'XHTML::Instrumented' );
require_ok( 'XHTML::Instrumented::Form' );

my $data = <<DATA;
<div>
 <form name="form_1">
   <lable id="lable">This is a lable</lable><input name="bob" id="data"/>
 <div id="list">
   <lable id="llable">text</lable><input id="ldata"/>
 </div>
 </form>
</div>
DATA

my $cmp = <<DATA;
<div>
 <form name="form_1" method="post" >
<lable id="lable">This is a lable</lable><input id="data" name="bob" value="This is bob"/>
<div id="list">
<lable id="llable.1">This is a lable 1</lable><input id="ldata.1" name="bob_1" value="This is bob_1"/>
<lable id="llable.2">This is a lable 2</lable><input id="ldata.2" name="bob_2" value="This is bob_2"/>
</div>
</form>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');
my $f = XHTML::Instrumented::Form->new(name => 'form_1');

$f->add_element(name => 'bob', value => 'This is bob', type => 'text');
$f->add_element(name => 'bob_1', value => 'This is bob_1', type => 'text');
$f->add_element(name => 'bob_2', value => 'This is bob_2', type => 'text');

my $output = $t->output(
    form_1 => $f,
    list => $t->loop(
        headers => [ 'llable', 'ldata' ],
	data => [
	    [ 'This is a lable 1', $t->args(id => 'bob_1', name => "bob_1") ],
	    [ 'This is a lable 2', $t->args(id => 'bob_2', name => "bob_2") ],
	],
    ),
);

is_xml($output, $cmp, 'input test');

