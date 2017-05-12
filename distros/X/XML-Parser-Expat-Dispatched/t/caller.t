use Test::More;

BEGIN {
  plan (tests => 4);
  use_ok 't::testparser2'
}

my @handler_names = qw| Start_foo Start End End_test Char_handler|;
t::testparser2->init(@handler_names);

my $p = new_ok 't::testparser2';
$p->parse(<<'EOXML');
<tests>
<foo></foo>
<bar>Whatever</bar>
<test></test>
</tests>
EOXML

subtest 'check what the caller is', sub{
  plan tests => 2;
  foreach(qw|XML::Parser::Expat::Dispatched XML::Parser::Expat|){
    isa_ok($p,$_, 'Parser');
  }
};

subtest 'check that it is the caller that gets handed down', sub {
  plan tests => scalar @handler_names;
  foreach (@handler_names) {
    is($p,$p->handler_arguments($_), "$_ gets called with the Parser")
  }
};
