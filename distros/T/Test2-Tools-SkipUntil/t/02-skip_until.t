#!/usr/bin/perl
use Test2::Bundle::More;
use Test2::Tools::SkipUntil 'skip_until';
use Test2::Tools::Exception 'dies';

subtest 'skip_until_2037' => sub {
  my $skipped = 1;
  SKIP: {
    skip_until 'Test2::Tools::SkipUntil test', 2, '2037-01-01';
    pass 'foo';
    pass 'bar';
    undef $skipped;
  }
  ok $skipped, 'skipped 2 tests until 2037-01-01';
};

subtest 'skip_until_1997' => sub {
  my $skipped = 1;
  SKIP: {
    skip_until 'Test2::Tools::SkipUntil test', 2, '1997-01-01';
    pass 'foo';
    pass 'bar';
    undef $skipped;
  }
  ok !defined $skipped, 'didn\'t skip tests as 1997 is in the past';
};

subtest 'skip_until_2037_no_num' => sub {
  my $skipped = 1;
  SKIP: {
    skip_until 'Test2::Tools::SkipUntil test', '2037-01-01';
    pass 'foo';
    pass 'bar';
    undef $skipped;
  }
  ok $skipped, 'skipped tests until 2037-01-01';
};

subtest 'exceptions' => sub {
  ok dies { skip_until(undef) },                      'dies on one arg';
  ok dies { skip_until("foo", undef) },               'dies on two args, undef';
  ok dies { skip_until("foo", undef, "2017-01-01") }, 'dies on three args, middle undef';
  ok dies { skip_until("foo", 1, undef) },            'dies on three args, last undef';
};
done_testing;
