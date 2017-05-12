use strict;
use warnings;
use Test::More;
use Test::Fatal;


my $xml = <<'EOXML';
<tests>
<foo></foo>
<bar>Test</bar>
<test></test>
<baz />
<handler/>
</tests>
EOXML

BEGIN {
  plan (tests => 4);
  use_ok 't::testparser'
}

my (@good_names, @bad_names);
@good_names = qw|Char_handler Start_handler Endhandler
		 Start_foo  Startbar Start End End_test|;
@bad_names  = qw| start_test EndBar Start_something|;
t::testparser->init(@good_names, @bad_names);

subtest 'basic handler tests' => sub{
  plan tests => 1+ @good_names + @bad_names;
  my $p = new_ok 't::testparser';
  $p->parse($xml);

  foreach (sort @good_names) {
    ok('ARRAY' eq ref $p->handler_arguments($_), "$_ was called");
  }
  foreach (sort @bad_names) {
    ok('ARRAY' ne ref $p->handler_arguments($_), "$_ wasn't called");
  }
};

t::testparser->reset_handlers(@good_names,@bad_names);
push @good_names, qw|Starttests EndBaz Start_Baz|;
@bad_names  = qw| start_test end_tests|;
t::testparser->init(@good_names,@bad_names, sub{lc $_[1]});

subtest 'lowercase tests' => sub{
  plan tests => 1+ @good_names + @bad_names;
  my $p = new_ok 't::testparser';
  $p->parse($xml);

  foreach (sort @good_names) {
    ok('ARRAY' eq ref $p->handler_arguments($_), "$_ was called");
  }
  foreach (sort @bad_names) {
    ok('ARRAY' ne ref $p->handler_arguments($_), "$_ wasn't called");
  }
};

subtest 'dies with wrong handler name' => sub{
  plan tests=> 1;
  t::testparser->init('strange_handler');
  like(exception{t::testparser->new},
       qr/^Unknown Expat handler type:/,
       'new with a strange_handler dies');
}
