use strict;

my @tests;
BEGIN{
@tests = (
  # Class, name,args, html index, expected value
  ['Fixed',"text_input_1",["bar"],0,"bar"],
  ['Fixed',"text_input_2",["bar"],1,"bar"],
  ['Fixed',"radio",["0"],2,"0"],
  ['Fixed',"radio",["1"],2,"1"],
  ['Fixed',"radio",["2"],2,"2"],
  ['Fixed',"radio",["3"],2,"3"],
  ['Fixed',"checkbox_1",[""],3,undef],
  ['Fixed',"checkbox_1",["on"],3,"on"],
  ['Fixed',"checkbox_2",[""],4,undef],
  ['Fixed',"checkbox_2",["on"],4,"on"],
  ['Default',"text_input_1",["bar"],0,"bar"],
  ['Default',"text_input_2",["bar"],1,"xxx"],
  ['Default',"radio",["0"],2,"1"],
  ['Default',"radio",["1"],2,"1"],
  ['Default',"radio",["2"],2,"1"],
  ['Default',"radio",["3"],2,"1"],
  ['Default',"checkbox_1",[""],3,"on"],
  ['Default',"checkbox_1",["on"],3,"on"],
  ['Default',"checkbox_2",[""],4,undef], # ??? This is a bit weird, but that's OK at the moment
  ['Default',"checkbox_2",["on"],4,"on"],

  # REs
  ['Fixed',qr/text_input/,["bar"],0,"bar"],
  ['Fixed',qr/text_input/,["bar"],1,"bar"],
);
};

use Test::More tests => 1 + scalar @tests * 3;
BEGIN {
  use_ok("WWW::Mechanize::FormFiller");
};
SKIP: {
  eval { require HTML::Form };
  skip "Need HTML::Form to run the more extensive tests", scalar @tests * 3 if $@;

  # Load the different HTML sets
  my @forms = split /---/, do {
    local $/ = undef;
    <DATA>;
  };

  for my $row (@tests) {
    my ($class,$name,$args,$index,$expected) = @$row;

    my $f = WWW::Mechanize::FormFiller->new();
    isa_ok($f,"WWW::Mechanize::FormFiller");
    my $form = HTML::Form->parse($forms[$index],"http://www.nowhere.org");

    my $filler = $f->add_filler($name,$class,@$args);
    isa_ok($filler, "WWW::Mechanize::FormFiller::Value::$class");
    $f->fill_form($form);
    my @filled_inputs;
    if (ref $name and UNIVERSAL::isa( $name,'Regexp')) {
	    @filled_inputs = grep { $_->name =~ $name } $form->inputs;
    } else {
      @filled_inputs = $form->find_input($name);
    };
    for my $input (@filled_inputs) {
      is($input->value,$expected,"Modified the expected field for page $index/$name ($class:".join(":",@$args).")");
    };
  };
};

__DATA__
<html><head><title>Text box</title></head>
<body>
<form>
  <input type="text" name="text_input_1" value="">
  <input type="text" name="secondary" value="">
</form>
</body>
</html>
---
<html><head><title>Text box (prefilled)</title></head>
<body>
<form>
  <input type="text" name="text_input_2" value="xxx">
</form>
</body>
</html>
---
<html><head><title>Radio box</title></head>
<body>
<form>
  <input type=radio name=radio value="0">
  <input type=radio name=radio value="1" checked>
  <input type=radio name=radio value="2" >
  <input type=radio name=radio value="3" >
</form>
</body>
</html>
---
<html><head><title>Readonly checkbox</title></head>
<body>
<form>
  <input type=checkbox name=checkbox_1 checked=1>
</form>
</body>
</html>
---
<html><head><title>Readonly checkbox</title></head>
<body>
<form>
  <input type=checkbox name=checkbox_2>
</form>
</body>
</html>