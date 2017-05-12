use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 4;

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <span id="one">two</span>
 <span id="two">one</span>
 <span id="three">three</span>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    one => $t->replace(text => 'one'),
    two => $t->replace(text => 'two'),
);

my $cmp = <<DATA;
<div>
 <span id="one">one</span>
 <span id="two">two</span>
 <span id="three">three</span>
</div>
DATA

is_xml($output, $cmp, 'replace');

$output = $t->output(
    one => $t->replace(text => 'one', args => { style => 'bob;'}),
    two => $t->replace(text => 'two'),
);

$cmp = <<DATA;
<div>
 <span id="one" style="bob;">one</span>
 <span id="two">two</span>
 <span id="three">three</span>
</div>
DATA

is_xml($output, $cmp, 'change args');

$output = $t->output(
    one => $t->replace(text => 'one', args => { style => 'bob;'}),
    two => $t->replace(text => 'xxx', args => { id => 'bob'}),
    three => $t->replace(remove_tag => 1),
);

$cmp = <<DATA;
<div>
 <span id="one" style="bob;">one</span>
 <span id="bob">xxx</span>
 three
</div>
DATA

is_xml($output, $cmp, 'remove tag');
