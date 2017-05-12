use strict;

my @values;
BEGIN {
  @values = ("foo","bar","","baz",1,0);
};

use Test::More tests => 1 + scalar @values * 7;

use_ok("WWW::Mechanize::FormFiller::Value::Callback");

SKIP: {
  eval { require Test::MockObject };
  skip "Need Test::MockObject to do tests on values", scalar @values *7 if $@;

  my $called;
  my $value;
  my $return_value;

  sub callback {
    my ($ff_value,$form_value) = @_;
    isa_ok($ff_value,"WWW::Mechanize::FormFiller::Value::Callback");
    $called = 1;
    can_ok($form_value, "value");
    is($form_value->value,$value,"Value passed correctly to callback ($value)");
    $return_value;
  };

  my $val;
  for $val (@values) {
    $value = $val;
    undef $called;
    $return_value = $value;

    my $input = Test::MockObject->new()->set_always('value',$value);
    my $v = WWW::Mechanize::FormFiller::Value::Callback->new("foo",\&callback);
    isa_ok($v,"WWW::Mechanize::FormFiller::Value::Callback");
    can_ok($v,"value");
    is($v->value($input),$return_value,"Callback returns the correct value for ('$value')");
    is($called,1,"Callback was called for ($value)");
  };
};