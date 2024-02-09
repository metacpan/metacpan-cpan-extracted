use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Mock::One;
use Sub::Override;

use WebService::KvKAPI;

sub get_kvk_api {
  my %args = @_;
  $args{api_key} //= 'foobar';
  my $kvk = WebService::KvKAPI->new(%args);
  isa_ok($kvk, 'WebService::KvKAPI');
  return $kvk;
}

my $client = get_kvk_api();

my $override = Sub::Override->new(
  'OpenAPI::Client::WebService__KvKAPI__BasicProfile_kvkapi_yml::getBasisprofielByKvkNummer'
    => sub {
    return 1;
  }
);

my %tests = (
    getResults => {
        method => 'search',
        module => 'Search',
        args => {naam => 'foo'},
        rv   => { naam => 'foo' },
    },
    getBasisprofielByKvkNummer => {
        method => 'get_basic_profile',
        module => 'BasicProfile',
        args => 1234567,
        rv => { kvkNummer => '01234567' },
    },
    getHoofdvestiging => {
        method => 'get_main_location',
        module => 'BasicProfile',
        args => 1234567,
        rv => { kvkNummer => '01234567' },
    },
    getVestigingen => {
        method => 'get_locations',
        module => 'BasicProfile',
        args => 1234567,
        rv => { kvkNummer => '01234567' },
    },
    getEigenaar => {
        method => 'get_owner',
        module => 'BasicProfile',
        args => 1234567,
        rv => { kvkNummer => '01234567' },
    },
    getVestigingByVestigingsnummer => {
        method => 'get_location_profile',
        module => 'LocationProfile',
        args => 1234567,
        rv => { vestigingsnummer => '000001234567' },
    },
);

my $args;
foreach my $operation (keys %tests) {
  $override->override(
    sprintf(
      "OpenAPI::Client::WebService__KvKAPI__%s_kvkapi_yml::%s",
      $tests{$operation}{module}, $operation
    ),
    => sub {
      my $client = shift;
      $args = shift;
      $args->{operation} = $operation;
      return Test::Mock::One->new(
        'X-Mock-Strict' => 1,
        error           => undef,
        res             => { json => \{ 'foo' => 'bar' } },
      );
    }
  );

  my $method = $tests{$operation}{method};
  can_ok($client, $method);
  my $params = $tests{$operation}{args};
  if (ref $params eq 'HASH') {
      $client->$method(%{$params});
  }
  elsif (ref $params eq 'ARRAY') {
      $client->$method(@{$params});
  }
  else {
      $client->$method($params);
  }

  cmp_deeply(
    $args,
    { %{ $tests{$operation}{rv} }, operation => $operation },
    "... and called $method correctly"
  );
}

done_testing;
