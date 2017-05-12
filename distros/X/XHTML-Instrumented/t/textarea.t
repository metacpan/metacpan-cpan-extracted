use strict;
use warnings;

use Test::More tests => 5;
use Test::XML;

use Test::Warn;

require_ok( 'XHTML::Instrumented' );
require_ok( 'XHTML::Instrumented::Form' );

my ($data, $cmp);

$data = <<DATA;
<div>
 <form name="myform">
  <textarea name="textarea"/>
 </form>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

$cmp = <<DATA;
<div>
 <form name="myform">
  <textarea name="textarea">
  </textarea>
 </form>
</div>
DATA

my $output;
warning_is {
    $output = $x->output();
} 'myform is not a form', 'Not a form';

is_xml($output, $cmp, 'no form data');

my $form = XHTML::Instrumented::Form->new();
$form->add_element(type => 'textarea', name => 'textarea', value => 'text');

$output = $x->output(
    myform => $form,
);

$cmp = <<DATA;
<div>
  <form name="myform" method="post">
    <textarea name="textarea">text</textarea>
  </form>
</div>
DATA

is_xml($output, $cmp, 'form data');

