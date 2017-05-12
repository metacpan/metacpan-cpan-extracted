use strict;


use Test::More tests => 1 + 3 + 3;

use_ok("WWW::Mechanize::FormFiller::Value::Random");

SKIP: {
  eval { require Test::MockObject };
  skip "Need Test::MockObject to do tests on values", 3+3
    if $@;

  my @values = ("foo","bar","baz");
  my $value;
  
  my $input = Test::MockObject->new()->set_always('value',$value);
  my $v = WWW::Mechanize::FormFiller::Value::Random->new("foo","bar");
  isa_ok($v,"WWW::Mechanize::FormFiller::Value::Random");
  can_ok($v,"value");
  is($v->value($input),"bar","Single argument list returns single argument");

  $input = Test::MockObject->new()->set_always('value',$value);
  $v = WWW::Mechanize::FormFiller::Value::Random->new("foo",@values);
  isa_ok($v,"WWW::Mechanize::FormFiller::Value::Random");
  can_ok($v,"value");
  like($v->value($input),"/" . join("|",@values)."/","Multiple arguments return one of the list");
};