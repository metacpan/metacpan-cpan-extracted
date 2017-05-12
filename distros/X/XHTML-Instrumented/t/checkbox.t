use strict;

use Test::More;
use Test::XML;
use Test::Warn;

use Data::Dumper;

plan tests => 4;

use XHTML::Instrumented;
use XHTML::Instrumented::Form;

my ($output, $cmp);

my $data = <<DATA;
<div>
  <form name="myform" id="myform">
    <h2>Likely Phrases.</h2>
    <ul>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="1"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="2"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="3"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
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
    <ul>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="1"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="2"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="3"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
    </ul>
  </form>
</div>
DATA


warning_is { $output = $x->output() } 'myform is not a form', 'No form.';

is_xml($output, $cmp, 'control');

my $form = XHTML::Instrumented::Form->new();
$form->add_element(type => 'multiselect', name => 'likely_phrase_ids', values => [ '1', '2', '3' ] );

$output = $x->output(
   myform => $form,
);

$cmp = <<DATA;
<div>
  <form name="myform" id="myform" method="post">
    <h2>Likely Phrases.</h2>
    <ul>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="1" checked="checked"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="2" checked="checked"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="3" checked="checked"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
    </ul>
  </form>
</div>
DATA

is_xml($output, $cmp, 'form list');

$form = XHTML::Instrumented::Form->new();
$form->add_element(type => 'multiselect', name => 'likely_phrase_ids');

$form->add_params( likely_phrase_ids => [1, 2, 3] );
$output = $x->output(
   myform => $form,
);

$cmp = <<DATA;
<div>
  <form name="myform" id="myform" method="post">
    <h2>Likely Phrases.</h2>
    <ul>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="1" checked="checked"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="2" checked="checked"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
      <li>
        <input type="checkbox" name="likely_phrase_ids" value="3" checked="checked"/>
        <a href="./phrase.html" name= "likely_phrase_text">Little black sambo and a tiger.</a>
      </li>
    </ul>
  </form>
</div>
DATA

is_xml($output, $cmp, 'form list');


