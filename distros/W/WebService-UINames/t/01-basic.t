#!perl

# pragmas
use 5.10.0;
use strict;
use warnings;

# imports
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use WebService::UINames;

my $obj;

subtest 'instance test' => sub {
  eval{ $obj = WebService::UINames->new };
  ok !$@;
  isa_ok $obj, 'WebService::UINames';
};

subtest 'get_name method test' => sub {
  $obj = $obj // WebService::UINames->new;
  my $res = $obj->get_name;
  is ref($res), 'HASH';
};

done_testing();

