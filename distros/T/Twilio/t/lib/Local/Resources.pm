package Local::Resources;

use 5.016;
use warnings;

use Twilio::Domain;
use Twilio::Http::FakeClient;
use Twilio::InstanceResource;
use Twilio::ListResource;
use Twilio::Page;
use Twilio::Rest::Client;
use Twilio::Version;

# The smallest resource that uses every base class. It stands in for a generated resource,
# so these tests cover the base classes and not one API.
sub build {
  my ($options) = @_;

  my $http = Twilio::Http::FakeClient->new;
  my $client =
    Twilio::Rest::Client->new('ACxx', 'secret', { http_client => $http, %{ $options // {} } });

  my $domain  = Local::Domain->new($client);
  my $version = Local::Version->new($domain);
  return ($http, $version, Local::List->new($version));
}

package Local::Domain;

use parent -norequire, 'Twilio::Domain';

sub new {
  my ($class, $client) = @_;
  my $self = $class->SUPER::new($client);
  $self->{base_url} = 'https://api.twilio.com/';
  return $self;
}

package Local::Version;

use parent -norequire, 'Twilio::Version';

sub new {
  my ($class, $domain) = @_;
  my $self = $class->SUPER::new($domain);
  $self->{version} = '2010-04-01';
  return $self;
}

package Local::List;

use parent -norequire, 'Twilio::ListResource';

sub new {
  my ($class, $version) = @_;
  my $self = $class->SUPER::new($version);
  $self->{solution} = { account_sid => 'ACxx' };
  $self->{uri}      = '/Accounts/ACxx/Items.json';
  return $self;
}

sub page {
  my ($self, $options, $page_size) = @_;
  my $params   = { %{ $options // {} }, PageSize => $page_size };
  my $response = $self->{version}->page('GET', $self->{uri}, { params => $params });
  return Local::Page->new($self->{version}, $response, $self->{solution});
}

package Local::Page;

use parent -norequire, 'Twilio::Page';

sub build_instance {
  my ($self, $payload) = @_;
  return Local::Instance->new($self->{version}, $payload, $self->{solution});
}

package Local::KeyedPage;

use parent -norequire, 'Local::Page';

sub records_key { return 'items' }

package Local::Instance;

use parent -norequire, 'Twilio::InstanceResource';

sub sid { return $_[0]{properties}{sid} }

1;
