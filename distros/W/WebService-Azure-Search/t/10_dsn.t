use strict;
use warnings;
use utf8;
use Test::More;
use WebService::Azure::Search;

my %init_params = (
  service => "service",
  index => "index",
  api => "api",
  admin => "admin",
);

subtest version => sub {
  is $WebService::Azure::Search::VERSION, '0.04';
};

subtest new => sub {
  my $new = WebService::Azure::Search->new(%init_params);
  is $new->{setting}{base}, "https://service.search.windows.net";
  is $new->{setting}{index}, "index";
  is $new->{setting}{api}, "api";
  is $new->{setting}{admin}, "admin";
  is $new->{params}{accept}, "application/json";
  is $new->{params}{url}, "https://service.search.windows.net/indexes/index/docs/index?api-version=api";
};

done_testing;
