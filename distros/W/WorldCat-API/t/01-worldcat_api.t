# vi:syntax=perl

use strict;
use warnings;
use lib qw(lib);
use local::lib qw(local);

use Test::Deep;
use Test::Fatal;
use Test::More;
use WorldCat::API;

plan skip_all => q{Can't instantiate WorldCat::API. Do you need a .env?}
  if exception { WorldCat::API->new };

subtest 'find_by_oclc_number returns a valid result' => sub {
  my $api = WorldCat::API->new;
  my $record = $api->find_by_oclc_number('829428');

  isa_ok $record, 'MARC::Record';
};

subtest 'find_by_oclc_number throws 401 on invalid authorization' => sub {
  my $api = WorldCat::API->new(secret => 'invalid');

  my $err = exception { $api->find_by_oclc_number('829428') };
  isa_ok $err, 'HTTP::Response';
  is $err->code, '401';
};

subtest 'find_by_oclc_number returns nil on 404' => sub {
  my $api = WorldCat::API->new;

  ok !$api->find_by_oclc_number('999999999');
};

done_testing;
