use strict;

my @values;
BEGIN {
  @values = ("foo",1,"",0,undef);
};

use Test::More tests => 1 + scalar @values * 3;

use_ok("WWW::Mechanize::FormFiller::Value::Fixed");

for my $value (@values) {
  my $v = WWW::Mechanize::FormFiller::Value::Fixed->new("foo",$value);
  isa_ok($v,"WWW::Mechanize::FormFiller::Value::Fixed");
  can_ok($v,"value");
  my $pvalue = $value ||"";
  is($v->value(undef),$value,"Fixed returns the correct value for $pvalue");
};