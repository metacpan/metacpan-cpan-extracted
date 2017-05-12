use strict;

use Test::More;
use Test::XML;
use Test::Warn;

use Data::Dumper;

plan tests => 5;

use XHTML::Instrumented;
use XHTML::Instrumented::Form;

my ($output, $cmp);

my $data = <<DATA;
<div>
  <form name="myform" id="myform">
    <h2>Likely Phrases.</h2>
    <ul id="likely_phrase_loop">
      <li>
        <input type="checkbox" id="likely_phrase_id" name="likely_phrase_ids" value="1"/>
        <a id= "likely_phrase_text" href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
    </ul>
  </form>
</div>
DATA

my $x = XHTML::Instrumented->new(name => \$data, type => '');

$cmp = <<DATA;
<div>
  <form name="myform" id="myform">
    <h2>Likely Phrases.</h2>
    <ul id="likely_phrase_loop">
      <li>
        <input type="checkbox" id="likely_phrase_id" name="likely_phrase_ids" value="1"/>
        <a id= "likely_phrase_text" href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
    </ul>
  </form>
</div>
DATA


warning_is { $output = $x->output() } 'myform is not a form', 'No form.';

is_xml($output, $cmp, 'control');

my $form = XHTML::Instrumented::Form->new();
$form->add_element(type => 'multiselect', name => 'likely_phrase_ids', value => [ '1', '2' ] );

$output = $x->output(
   myform => $form,
);

$form->add_params(likely_phrase_ids => ['1', '2']);

$cmp = <<DATA;
<div>
  <form name="myform" id="myform" method="post">
    <h2>Likely Phrases.</h2>
    <ul id="likely_phrase_loop">
      <li>
        <input type="checkbox" id="likely_phrase_id" name="likely_phrase_ids" value="1"/>
        <a id= "likely_phrase_text" href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
    </ul>
  </form>
</div>
DATA

is_xml($output, $cmp, 'form');

$output = $x->output(
   likely_phrase_loop => $x->loop(),
   myform => $form,
);

$cmp = <<DATA;
<div>
  <form name="myform" id="myform" method="post">
    <h2>Likely Phrases.</h2>
  </form>
</div>
DATA

is_xml($output, $cmp, 'form list');

####
$output = $x->output(
   likely_phrase_loop => $x->loop(
       headers => ['likely_phrase_text', 'likely_phrase_id' ],
       data => [
           [ $x->replace( text => 'one' ),  $form->get_element('likely_phrase_ids', value => '1') ],
           [ $x->replace( text => 'two' ),  $form->get_element('likely_phrase_ids', value => '2') ],
       ],
   ),
   myform => $form,
);

$cmp = <<DATA;
<div>
  <form name="myform" id="myform" method="post">
    <h2>Likely Phrases.</h2>
    <ul id="likely_phrase_loop">
      <li>
        <input type="checkbox" id="likely_phrase_id.1" name="likely_phrase_ids" value="1"/>
        <a id="likely_phrase_text.1" href="./phrase.html" name= "likely_phrase_text">one</a>
      </li>
      <li>
        <input type="checkbox" id="likely_phrase_id.2" name="likely_phrase_ids" value="2"/>
        <a id="likely_phrase_text.2" href="./phrase.html" name= "likely_phrase_text">two</a>
      </li>
    </ul>
  </form>
</div>
DATA

is_xml($output, $cmp, 'form list');


