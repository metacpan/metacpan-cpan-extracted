#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 15;
use Test::Exception;

use_ok q{Test::FITesque::Fixture};
can_ok q{Test::FITesque::Fixture}, qw(new method_test_count parse_method_string parse_arguments);

Check_fixture_class: {
  use_ok q{Buddha::GoodFixture};
  my $fixture = Buddha::GoodFixture->new();
  isa_ok $fixture, q{Buddha::GoodFixture};
  isa_ok $fixture, q{Test::FITesque::Fixture};
  can_ok $fixture, qw(karma zen dharma);
  
  
  is $fixture->method_test_count('dharma'), undef,  q{No test count for dharma};
  is $fixture->method_test_count('zen'),    3,      q{zen method has count of 3};
  is $fixture->method_test_count('karma'),  1,      q{karma method has count of 1};

  use_ok q{Buddha::ParseMethodFixture};
  my $fixture2 = Buddha::ParseMethodFixture->new({});
  is $fixture2->parse_method_string('one two three'), \&Buddha::ParseMethodFixture::one_two_three,
    q{method string parsed correctly};
  is_deeply [$fixture2->parse_arguments(qw(one two))], [qw(one two)], q{Arguments parsed};
}

Check_bad_fixture: {
  dies_ok {
    require Buddha::BadFixture;
  } "Use of bad attributes handled"; 
  dies_ok {
    require Buddha::BadFixture2;
  } "Use of bad attributes handled"; 
  dies_ok {
    require Buddha::BadFixture3;
  } "Use of bad attributes handled"; 
}
