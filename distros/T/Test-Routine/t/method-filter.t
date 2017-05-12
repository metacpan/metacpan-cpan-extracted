use Test::Routine;
use Test::Routine::Util;
use Test::More;
use Test::Fatal;

my %ran;
my %expected = ( map { $_ => 1 } just => 1..3 );

foreach my $num (1..3) {
  test "this must run $num" => sub { pass "must $num"; $ran{$num}++ };
}

test "just this" => sub { pass "just this"; $ran{just}++ };

subtest 'empty TEST_METHOD' => sub {
  local $ENV{TEST_METHOD} = '';
  run_me 'empty TEST_METHOD';
  is_deeply \%ran, \%expected, 'ran all tests';
};

subtest 'TEST_METHOD set' => sub {
  test "not to run" => sub { fail };

  %ran = ();
  {
    local $ENV{TEST_METHOD} = 'just this';
    run_me 'literal';
  }

  {
    local $ENV{TEST_METHOD} = '.*must.*';
    run_me 'regex';
  }

  is_deeply \%ran, \%expected, "ran each test once";
};

{
  # the whole subtest must be TODO, or it fails with "no tests run" for
  # the subtest created by run_me()
  local $TODO = "Exception gets swallowed somewhere";
  subtest 'invalid regex' => sub {
    local $ENV{TEST_METHOD} = 'invalid++';
    like exception { run_me 'invalid' },
      qr/\A\QTEST_METHOD (invalid++) is not a valid regular expression/,
      "invalid regex throws";
  };
}

done_testing;
