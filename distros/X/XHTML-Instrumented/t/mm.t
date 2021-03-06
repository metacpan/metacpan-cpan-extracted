use strict;

use Test::More;

eval {
  require Test::XML;
  require Test::XML::Order;
};
plan skip_all => "Test::XML::Order required for testing this" if $@;

use Data::Dumper;

plan tests => 3;

Test::XML->import();
Test::XML::Order->import();

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <div id="row">
   <span id="column">
     <a id="cdata">one</a>
   </span>
 </div>
</div>
DATA

my $t = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $t->output(
    row => $t->loop(  headers => [ 'text', 'column' ], 
		      data => [
		          ['text one', $t->loop( headers => ['cdata'], data => [['one one'], ['one two']] )], 
		          ['text two', $t->loop( headers => ['cdata'], data => [['two one'], ['two two']] )], 
		      ]
		   ),
);

my $cmp = <<DATA;
<div>
  <div id="row">
    <span id="column.1">
      <a id="cdata.1.1">one one</a>
      <a id="cdata.1.2">one two</a>
    </span>
    <span id="column.2">
      <a id="cdata.2.1">two one</a>
      <a id="cdata.2.2">two two</a>
    </span>
  </div>
</div>
DATA

is_xml($output, $cmp, 'loop in loop');
is_xml_in_order($output, $cmp, 'loop in loop');

