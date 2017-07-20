use Test2::V0 -no_srand => 1;
use Test::Script;

subtest 'non-distructive' => sub {

  my @foo = qw( foo bar baz );

  my $bar = Test::Script::_script \@foo;

  is(
    $bar,
    [qw( foo bar baz )],
    'comes out the right'
  ),

  my $command = shift @$bar;

  is(
    \@foo,
    [qw( foo bar baz )],
    '@foo is unchanged',
  );

};

done_testing;
