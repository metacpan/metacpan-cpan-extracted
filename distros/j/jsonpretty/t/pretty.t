use strictures 1;
use Test::More;
use App::JSONPretty;

sub run_test {
  my ($in) = @_;
  my $out = '';
  local (*STDIN, *STDOUT);
  open STDIN, '<', \$in;
  open STDOUT, '>', \$out;
  App::JSONPretty::run();
  $out;
}

is(
  run_test('{ "foo": 1, "bar": 2, }'),
  q'{
   "bar" : 2,
   "foo" : 1
}
',
  'Output ok (simple STDIN test)'
);

{
  local @ARGV = 't/simple.json';
  is(
    run_test(''),
    q'{
   "bar" : 2,
   "foo" : 1
}
',
    'Output ok (simple @ARGV test)'
  );
}

{
  local $@;
  eval { run_test('') };
  like($@, qr/No source data supplied/, 'Error ok for empty data');
}

done_testing;
