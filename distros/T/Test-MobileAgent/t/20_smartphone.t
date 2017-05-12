use strict;
use warnings;
use Test::More;
use Test::MobileAgent ':all';
use HTTP::MobileAgent;

BEGIN {
  eval { require HTTP::MobileAgent::Plugin::SmartPhone; 1 }
    or plan skip_all => "requires HTTP::MobileAgent::Plugin::SmartPhone";
}

my @Tests = (
  [iPod => {is_ios => 1, is_ipad => '', is_iphone => '', is_android => ''}],
  [iPhone => {is_ios => 1, is_ipad => '', is_iphone => 1, is_android => ''}],
  [iPad => {is_ios => 1, is_ipad => 1, is_iphone => '', is_android => ''}],
  [Android => {is_ios => '', is_ipad => '', is_iphone => '', is_android => 1}],
);

{
  local %ENV;
  test_mobile_agent("smartphone");
  my $agent = HTTP::MobileAgent->new;
  isa_ok $agent, 'HTTP::MobileAgent';
  isa_ok $agent, 'HTTP::MobileAgent::NonMobile';
  ok $agent->is_smartphone, "is a SmartPhone";
}

for (@Tests) {
  local %ENV;
  test_mobile_agent("smartphone.".$_->[0]);
  my $agent = HTTP::MobileAgent->new;
  isa_ok $agent, 'HTTP::MobileAgent';
  isa_ok $agent, 'HTTP::MobileAgent::NonMobile';
  ok $agent->is_smartphone, "$_->[0] is a SmartPhone";

  for my $method (keys %{$_->[1]}) {
    is $agent->$method => $_->[1]->{$method}, "$method returns correctly";
  }
}

for (@Tests) {
  local %ENV;
  test_mobile_agent(lc $_->[0]);
  my $agent = HTTP::MobileAgent->new;
  isa_ok $agent, 'HTTP::MobileAgent';
  isa_ok $agent, 'HTTP::MobileAgent::NonMobile';
  ok $agent->is_smartphone, "$_->[0] is a SmartPhone";

  for my $method (keys %{$_->[1]}) {
    is $agent->$method => $_->[1]->{$method}, "$method returns correctly";
  }
}

done_testing;
