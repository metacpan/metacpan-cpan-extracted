package WebService::Whistle::Pet::Tracker::API;
use strict;
use warnings;
use JSON::XS qw{};
use HTTP::Tiny qw{};

our $VERSION = '0.03';
our $PACKAGE = __PACKAGE__;
our $API_URL = 'https://app.whistle.com/api';

=head1 NAME

WebService::Whistle::Pet::Tracker::API - Perl interface to access the Whistle Pet Tracker Web Service

=head1 SYNOPSIS

  use WebService::Whistle::Pet::Tracker::API;
  my $ws   = WebService::Whistle::Pet::Tracker::API->new(email=>$email, password=>$password);
  my $pets = $ws->pets; #isa ARRAY of HASHes
  foreach my $pet (@$pets) {
    print JSON::XS->new->pretty->encode($pet);
  }

=head1 DESCRIPTION

Perl interface to access the Whistle Pet Tracker Web Service.  All methods return JSON payloads that are converted to Perl data structures.  Methods that require authentication will request a token and cache it for the duration of the object.

=head1 CONSTRUCTORS
 
=head2 new
 
  my $ws = WebService::Whistle::Pet::Tracker::API->new(email=>$email, password=>$password);
 
=cut
 
sub new {
  my $this  = shift;
  my $class = ref($this) ? ref($this) : $this;
  my $self  = {};
  bless $self, $class;
  %$self    = @_ if @_;
  return $self;
}

=head1 PROPERTIES

=head2 email

Sets and returns the registered Whistle account email

=cut

sub email {
  my $self         = shift;
  $self->{'email'} = shift if @_;
  die("Error: Whistle API: email required") unless $self->{'email'};
  return $self->{'email'};
}

=head2 password

Sets and returns the registered Whistle account password

=cut

sub password {
  my $self            = shift;
  $self->{'password'} = shift if @_;
  die("Error: Whistle API: password required") unless $self->{'password'};
  return $self->{'password'};
}

=head1 METHODS

=head2 pets

Returns a list of pets as an array reference

  my $pets = $ws->pets;

=cut

sub pets {
  my $self = shift;
  return $self->api('/pets')->{'pets'};
}

=head2 device

Returns device data for the given device id

  my $device        = $ws->device('WXX-ABC123');
  my $battery_level = $device->{'battery_level'}; #0-100 charge level

=cut

sub device {
  my $self          = shift;
  my $serial_number = shift or die("Error: Whistle API: Device serial number required.");
  return $self->api("/devices/$serial_number")->{'device'};
}

=head2 pet_dailies

Returns dailies for the given pet id

  my $pet_dailies = $ws->pet_dailies($pet_id);

=cut

sub pet_dailies {
  my $self   = shift;
  my $pet_id = shift or die("Error: Whistle API: pet id required");
  return $self->api("/pets/$pet_id/dailies")->{'dailies'}; #https://app.whistle.com/api/pets/123456789/dailies
}

=head2 pet_daily_items

Returns the daily items for the given pet id and day number

  my $pet_daily_items = $ws->pet_daily_items($pet_id, $day_number);

=cut

sub pet_daily_items {
  my $self       = shift;
  my $pet_id     = shift or die("Error: Whistle API: pet id required");
  my $day_number = shift or die("Error: Whistle API: day number required");
  return $self->api("/pets/$pet_id/dailies/$day_number/daily_items")->{'daily_items'};
}

=head2 pet_stats

Returns pet stats for the given pet id

  my $pet_stats = $ws->pet_stats(123456789);

=cut

sub pet_stats {
  my $self   = shift;
  my $pet_id = shift or die("Error: Whistle API: pet id required");
  return $self->api("/pets/$pet_id/stats")->{'stats'};
}

=head2 places

Returns registered places as an array reference

  my $places = $ws->places;

=cut

sub places {shift->api('/places')}; #this api call returns an array instead of a hash like other calls

=head1 METHODS (API)

=head2 api

Returns the decoded JSON data from the given web service end point

  my $data = $ws->api('/end_point');

=cut

sub api {
  my $self             = shift;
  my $api_destination  = shift or die("Error: Whistle API: api destination required");
  my $url              = $API_URL. $api_destination;
  my $response         = $api_destination eq '/login'
                       ? $self->ua->post_form($url, [email => $self->email, password => $self->password])
                       : $self->ua->get($url, {
                                               headers => {
                                                           Accept        => 'application/vnd.whistle.com.v6+json',
                                                           Authorization => 'Bearer '. $self->auth_token,
                                                          },
                                              }
                                       );
  print JSON::XS->new->pretty->encode({response => $response}) if $self->{'DEBUG'};
  my $status           = $response->{'status'};
  my $reason           = $response->{'reason'};
  if ($api_destination eq '/login') {
    die("Error: Whistle API: login failed\n") if $status eq 422;
    die("Error: Whistle API: request unsuccessful - request: $api_destination, status: $status $reason\n") unless $status eq 201;
  } else {
    die("Error: Whistle API: request unsuccessful - request: $api_destination, status: $status $reason\n") unless $status eq 200;
  }
  my $response_content = $response->{'content'};
  local $@;
  my $response_decoded = eval{JSON::XS::decode_json($response_content)};
  my $error            = $@;
  die("Error: Whistle API: invalid JSON - request: $api_destination, status: $status $reason, content: $response_content\n") if $error;
  print JSON::XS->new->pretty->encode({response_decoded => $response_decoded}) if $self->{'DEBUG'};
  return $response_decoded;
}

=head2 login

Calls the login service, caches, and returns the response.

=cut

sub login {
  my $self         = shift;
  $self->{'login'} = shift if @_;
  $self->{'login'} = $self->api('/login') unless defined $self->{'login'};
  return $self->{'login'};
}

=head2 auth_token

Retrieves the authentication token from the login end point

=cut

sub auth_token {shift->login->{'auth_token'}};

=head1 ACCESSORS
 
=head2 ua
 
Returns an L<HTTP::Tiny> web client user agent
 
=cut
 
sub ua {
  my $self = shift;
  unless ($self->{'ua'}) {
    my %settinges = (
                     keep_alive => 0,
                     agent      => "Mozilla/5.0 (compatible; $PACKAGE/$VERSION; See rt.cpan.org 35173)",
                    );
    $self->{'ua'} = HTTP::Tiny->new(%settinges);
  }
  return $self->{'ua'};
}

=head1 SEE ALSO

=over

=item Python - L<https://github.com/RobertD502/whistleaio>

=item NodeJS (old api) - L<https://github.com/martzcodes/node-whistle>

=back

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2023 Michael R. Davis

=cut

1;
