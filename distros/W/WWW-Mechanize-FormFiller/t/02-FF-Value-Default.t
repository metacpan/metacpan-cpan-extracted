use strict;

my @values;
BEGIN {
  @values = (
    ["foo","","foo"],
    [1,"",1],
    ["","",""],
    [0,"",0],
    [undef,"",undef],

    ["foo","foo","foo"],
    [1,"foo","foo"],
    ["","foo","foo"],
    [0,"foo","foo"],
    [undef,"foo","foo"],

    ["foo",1,1],
    [1,1,1],
    ["",1,1],
    [0,1,1],
    [undef,1,1],

    ["foo",0,0],
    [1,0,0],
    ["",0,0],
    [0,0,0],
    [undef,0,0],
  );
};

use Test::More tests => 1 + scalar @values * 3;

use_ok("WWW::Mechanize::FormFiller::Value::Default");
SKIP: {
  eval { require Test::MockObject };
  skip "Need Test::MockObject to do tests on values", scalar @values *3 if $@;

  for my $row (@values) {
    my ($value,$form_value,$expected) = @$row;

    my $input = Test::MockObject->new()->set_always('value',$form_value);

    my $v = WWW::Mechanize::FormFiller::Value::Default->new("foo",$value);
    isa_ok($v,"WWW::Mechanize::FormFiller::Value::Default");
    can_ok($v,"value");
    my $pvalue = $value || "";
    is($v->value($input),$expected,"Fixed returns the correct value for ('$pvalue'/'$form_value')");
  };
};