use strict;

use Test::More;


eval {
  require Test::XML;
  require Test::XML::Order;
};
plan skip_all => "Test::XML::Order required for testing this" if $@;

plan tests => 4;

Test::XML->import();
Test::XML::Order->import();

require_ok( 'XHTML::Instrumented' );

my $data = <<DATA;
<div>
 <div id="row">
   <span id="column">
     <span id="cdata">one</span>
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
		      ],
		      inclusive => 1,
		   ),
);

my $cmp = <<DATA;
<div>
 <div id="row.1">
   <span id="column.1">
     <span id="cdata.1.1">one one</span>
     <span id="cdata.1.2">one two</span>
   </span>
 </div><div id="row.2">
   <span id="column.2">
     <span id="cdata.2.1">two one</span>
   
     <span id="cdata.2.2">two two</span>
   </span>
 </div>
</div>
DATA

is_xml($output, $cmp, 'loop in loop');

$output = $t->output(
    row => $t->loop(  headers => [ 'text', 'column' ], 
		      data => [
		          ['text one', $t->loop( headers => ['cdata'], data => [['one one'], ['one two']], inclusive => 1 )], 
		          ['text two', $t->loop( headers => ['cdata'], data => [['two one'], ['two two']], inclusive => 1 )], 
		      ],
		      inclusive => 1,
		   ),
);

$cmp = <<DATA;
<div>
 <div id="row.1">
   <span id="column.1.1">
     <span id="cdata.1.1">one one</span>
   </span><span id="column.1.2">
     <span id="cdata.1.2">one two</span>
   </span>
 </div><div id="row.2">
   <span id="column.2.1">
     <span id="cdata.2.1">two one</span>
   </span><span id="column.2.2">
     <span id="cdata.2.2">two two</span>
   </span>
 </div>
</div>
DATA

is_xml($output, $cmp, 'loop in loop');
is_xml_in_order($output, $cmp, 'loop in loop');

