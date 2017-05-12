use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 6;

require_ok( 'XHTML::Instrumented' );
require_ok( 'XHTML::Instrumented::Form' );

my $data = <<DATA;
<div>
   <input type="text" name="remove_me" id="remove_me" />
   <input type="text" name="dont_remove_me" id="dont_remove_me" />
</div>
DATA

my $cmp = <<DATA;
<div>
   <input type="text" name="remove_me" id="remove_me" />
   <input type="text" name="dont_remove_me" id="dont_remove_me" />
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $output = $x->output(
);

is_xml($output, $cmp, 'control');

$cmp = <<DATA;
<div>
   <input type="text" name="dont_remove_me" id="dont_remove_me" />
</div>
DATA

$output = $x->output(
    remove_me => $x->replace(remove => 1),
);

is_xml($output, $cmp, 'simple');

$data = <<DATA;
<div>
 <form name="bob">
   <input type="text" name="remove_me" id="remove_me" />
   <input type="text" name="dont_remove_me" id="dont_remove_me" />
 </form>
</div>
DATA

$cmp = <<DATA;
<div>
 <form method="post" name="bob">
   <input type="text" name="remove_me" id="remove_me" value="" />
   <input type="text" name="dont_remove_me" id="dont_remove_me" value="" />
 </form>
</div>
DATA

$x = XHTML::Instrumented->new(name => \$data, type => '');
$form = XHTML::Instrumented::Form->new();

my $q = $form->add_element(
    name => "remove_me",
    type => 'text',
    remove => 1,
);

$form->add_element(
    name => "dont_remove_me",
    type => 'text',
);

$output = $x->output(
    bob => $form,
);

$cmp = <<DATA;
<div>
 <form method="post" name="bob">
   <input type="text" name="dont_remove_me" id="dont_remove_me" value="" />
 </form>
</div>
DATA

is_xml($output, $cmp, 'form control');

$output = $x->output(
#    remove_me => $x->replace(remove => 1),
    bob => $form,
);

is_xml($output, $cmp, 'simple');

