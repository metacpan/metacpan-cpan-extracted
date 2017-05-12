use Test::More;
use Test::XML;

use Data::Dumper;

plan tests => 6;

require_ok( 'XHTML::Instrumented' );
require_ok( 'XHTML::Instrumented::Form' );

my $data = <<DATA;
<div>
<form id="myform" name="myform">
<textarea name="textarea"/>
<select name="select">
<option>select</option>
<option>not a</option>
<option>not b</option>
<option>not c</option>
</select>
</form>
</div>
DATA

my $cmp = <<DATA;
<div>
  <form id="myform" name="myform" method="post" action="/bob">
    <input name="a" type="hidden" value="a"/>
    <textarea name="textarea">
test
    </textarea>
    <select name="select">
      <option disabled="disabled" value="A">A</option>
      <option selected="selected" value="B">B</option>
      <option value="C">C</option>
    </select>
  </form>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

my $form = XHTML::Instrumented::Form->new(action => '/bob');
$form->add_element(type => 'select', name => 'select', data => [ { text => 'A', disabled => 1 }, { text => 'B', selected => 1 }, { text => 'C' } ] );
$form->add_element(type => 'textarea', name => 'textarea', value => 'test' );
$form->add_element(type => 'hidden', name => 'a', value => 'a' );

my $output = $x->output(
     myform => $form,
);

is_xml($output, $cmp, 'select');

$data = <<DATA;
<div>
  <form name="myform" method="post">
    <form name="secondform" method="post">
      <textarea>
	bob
      </textarea>
    </form>
  </form>
</div>
DATA


eval {
    $x = XHTML::Instrumented->new(name => \$data, type => '');
}; if ($@) {
    if ($@ =~ /embeded form at line 3/) {
	pass('no ebedded forms');
    } else {
	fail();
    }
} else {
    fail('no ebedded forms') if $@ =~ /embeded form at line 3/;
}

######################################

$form = XHTML::Instrumented::Form->new();
$form->add_element(type => 'text', name => 'name', value => 'default');

$data = <<DATA;
<div>
  <form name="myform" method="post">
    <input name="name" value=""/>
  </form>
</div>
DATA

$cmp = <<DATA;
<div>
  <form name="myform" method="post">
    <input name="name" value="default"/>
  </form>
</div>
DATA

$x = XHTML::Instrumented->new(name => \$data, type => '');

$output = $x->output( myform => $form );

is_xml($output, $cmp, 'text default');

$cmp = <<DATA;
<div>
  <form name="myform" method="post">
    <input name="name" value="bob"/>
  </form>
</div>
DATA

$form->add_params(name => [ 'bob' ]);

$output = $x->output( myform => $form );

is_xml($output, $cmp, 'text params');

