use Test::More;
use Sub::Override;
use Test::Deep;
use Test::Mock::One;

use WebService::KvKAPI::Search;

sub get_openapi_client {
    my %args = @_;
    $args{api_key} //= 'testsuite';
    return WebService::KvKAPI::Search->new(%args);
}

my $client = get_openapi_client();

my $operation;
my %args;

use Sub::Override;
my $override = Sub::Override->new(
  'WebService::KvKAPI::Search::api_call' => sub {
    shift;
    $operation = shift;
    %args      = @_;
    return { foo => 'bar' };
  }
);


my $res = $client->search(
  kvkNummer        => 1234567,
  rsin             => 9,
  vestigingsnummer => 12,
);

cmp_deeply($res, { foo => 'bar' }, "Got the results from the KvK API");

cmp_deeply(
  \%args,
  {
    kvkNummer        => '01234567',
    rsin             => '000000009',
    vestigingsnummer => '000000000012',
  },
  "Mangled numbers correctly correctly"
);

# Rename v1 namings to v2 style for backward compatibility
my @mywarnings;
local $SIG{__WARN__} = sub { push(@mywarnings, @_) };
$res = $client->search(handelsnaam => 'Foo',);
cmp_deeply(\%args, { naam => 'Foo', }, "Handelsnaam => naam change in v2");
is(@mywarnings, 1, "... shows the correct deprecation warning");
like(
  $mywarnings[0],
  qr/^Deprecated item found in Search: naam has been renamed to handelsnaam/,
  "... and it is the correct one"
);

$override->restore;

my $args;
$override->override(
  "OpenAPI::Client::WebService__KvKAPI__Search_kvkapi_yml::getResults" => sub {
    my $client = shift;
    $args = shift;
    return Test::Mock::One->new(
      'X-Mock-Strict' => 1,
      error           => undef,
      res             => { json => \$args },
    );
  }
);


$res = $client->search(
  type => [qw(foo bar)],
);


cmp_deeply($args, { type => [qw(foo bar)] }, "Changed multiple types to one");

done_testing;
