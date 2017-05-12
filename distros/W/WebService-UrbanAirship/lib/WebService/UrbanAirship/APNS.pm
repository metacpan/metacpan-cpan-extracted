package WebService::UrbanAirship::APNS;

use 5.006;

use strict;
use warnings FATAL => qw(all);

use WebService::UrbanAirship;

use JSON::XS ();
use HTTP::Request ();
use HTTP::Response ();
use HTTP::Headers ();
use LWP::UserAgent ();
use LWP::Protocol::https ();


#---------------------------------------------------------------------
# globals
#---------------------------------------------------------------------

our $DEBUG   = 0;

our $VERSION = "0.02";

our @ISA     = qw(WebService::UrbanAirship);


#---------------------------------------------------------------------
# constructor
#---------------------------------------------------------------------
sub new {

  my $class = shift;

  my %args = @_;

  foreach my $key (qw(application_key application_secret application_push_secret)) {
    die "missing argument: $key"
      unless $args{$key};
  }

  my $self = {_push_secret => delete $args{application_push_secret},
              _secret      => delete $args{application_secret},
              _key         => delete $args{application_key},
             };

  bless $self, $class;

  $self->_init(%args);

  return $self;
}


#---------------------------------------------------------------------
# private initialization routine
#---------------------------------------------------------------------
sub _init {

  shift->ua;
}


#---------------------------------------------------------------------
# set up the ua object
#---------------------------------------------------------------------
sub ua {

  my $self = shift;

  my %args = @_;

  my $ua = $self->{_ua} ||
           LWP::UserAgent->new(agent             => $self->_agent(),
                               protocols_allowed => [ qw(https) ],
                               timeout           => $self->_timeout(),
                              );

  # set (or reset) the headers
  my $headers = HTTP::Headers->new();

  # all data needs to be JSON
  $headers->content_type('application/json');

  # set the authentication headers here
  $headers->authorization_basic($self->{_key}, $self->{_push_secret});

  $ua->default_headers($headers);

  $self->{_ua} = $ua;

  return $ua;
}



#---------------------------------------------------------------------
# default user-agent string
#---------------------------------------------------------------------
sub _agent {

  return join '/', __PACKAGE__, $VERSION;
}

#---------------------------------------------------------------------
# default timeout
#---------------------------------------------------------------------
sub _timeout {

  return 60;
}


#---------------------------------------------------------------------
# main api...
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# device registration
#---------------------------------------------------------------------

sub register_device {

  my $self  = shift;

  my %args  = @_;

  my $token = delete $args{device_token};

  return unless $token;

  # as a shortcut, tidy the id per urban airship specs...
  
  $token = uc $token;
  $token =~ s/[-\s<>]//g;

  my $json;

  if (scalar keys %args) {

    delete $args{alias} unless $args{alias};
    delete $args{tags} unless $args{tags} && ref $args{tags};

    $json = JSON::XS::encode_json(\%args);

  }

  my $ua = $self->ua;

  my $headers = $ua->default_headers;

  # this API requires the secret key, not the push secret key
  $headers->authorization_basic($self->{_key}, $self->{_secret});

  my $uri = $self->_api_uri;

  $uri->path(join '/', '/api/device_tokens', $token);

  my $request = HTTP::Request->new('PUT',
                                   $uri,
                                   $headers,
                                   $json);

  return $self->_request($request);
}


sub ping_device {

  my $self  = shift;

  my %args  = @_;

  my $token = delete $args{device_token};

  return unless $token;

  # as a shortcut, tidy the id per urban airship specs...

  $token = uc $token;
  $token =~ s/[-\s<>]//g;

  my $ua = $self->ua;

  my $headers = $ua->default_headers;

  # this API requires the secret key, not the push secret key
  $headers->authorization_basic($self->{_key}, $self->{_secret});

  my $uri = $self->_api_uri;

  $uri->path(join '/', '/api/device_tokens', $token);

  my $request = HTTP::Request->new('GET',
                                   $uri,
                                   $headers);

  return $self->_request($request, 1);
}


sub push {

  my $self  = shift;

  my %args  = @_;

  my ($perl, $body) = $self->_craft_single_push(\%args);

  return unless $perl;

  my $json = JSON::XS::encode_json($perl);

  my $uri = $self->_api_uri;

  $uri->path('/api/push/');

  my $request = HTTP::Request->new('POST',
                                   $uri);

  $request->content($json);

  return $self->_request($request, $body);
}

sub batch {

  my $self  = shift;

  my @args = @_;

  my @array;

  foreach my $key (@args) {

    next unless ref $key eq 'HASH';
 
    my ($perl) = $self->_craft_single_push($key, 1);

    next unless $perl;

    CORE::push @array, $perl;
  }

  return unless scalar @array;

  my $json = JSON::XS::encode_json(\@array);

  my $uri = $self->_api_uri;

  $uri->path('/api/push/batch/');

  my $request = HTTP::Request->new('POST',
                                   $uri);

  $request->content($json);

  return $self->_request($request);
}

sub broadcast {

  my $self = shift;

  my %args = @_;

  my $payload = $self->_craft_payload(\%args);

  return unless $payload;

  my $perl = {aps => $payload};

  if (my $exclude = delete $args{exclude_tokens}) {
    $perl->{exclude_tokens} = $exclude
      if ref $exclude && ref $exclude eq 'ARRAY';
  }

  my $json = JSON::XS::encode_json($perl);

  my $uri = $self->_api_uri;

  $uri->path('/api/push/broadcast/');

  my $request = HTTP::Request->new('POST',
                                   $uri);

  $request->content($json);

  return $self->_request($request);
}

sub feedback {

  my $self = shift;

  my %args = @_;

  my $date = delete $args{since};

  return unless $date;

  my $uri = $self->_api_uri;

  $uri->path('/api/device_tokens/feedback/');

  $uri->query(join '=', 'since', $date);

  my $request = HTTP::Request->new('GET',
                                   $uri);

  return $self->_request($request, 1);
}

sub stats {

  my $self = shift;

  my %args = @_;

  my $start  = delete $args{start};
  my $end    = delete $args{end};

  my $format = delete $args{format};

  return unless $start && $end;

  my $uri = $self->_api_uri;

  $uri->path('/api/push/stats/');

  my $query = "start=$start&end=$end";

  $query = join '&', $query, "format=$format" if $format;

  $uri->query($query);

  my $request = HTTP::Request->new('GET',
                                   $uri);

  return $self->_request($request, 1);
}


sub _request {

  my $self    = shift;

  my $request = shift;

  my $body    = shift;

  if ($request->method eq 'GET') {
    $request->headers->remove_header('content-type');
  }

  print STDERR "request: ", $request->as_string
    if $DEBUG;

  my $response = $self->ua->request($request);

  print STDERR "response: ", $response->as_string
    if $DEBUG;

  if ($response->is_success) {

    if ($body) {
      return $response->content;
    }
    else {
      return $response->code;
    }
  }

  return;
}


sub _craft_single_push {

  my $self = shift;

  my %args = %{shift || {}};

  my $batch = shift;

  my $payload = $self->_craft_payload(\%args);

  return unless $payload;

  my $tokens  = delete $args{device_tokens} || [];

  if ($tokens) {
    return unless ref $tokens eq 'ARRAY';
  }

  my $aliases = delete $args{aliases} || [];

  if ($aliases) {
    return unless ref $aliases eq 'ARRAY';
  }

  my $tags = [];

  unless ($batch) {
    $tags = delete $args{tags} || [];

    if ($tags) {
      return unless ref $tags eq 'ARRAY';
    }
  }

  return unless (scalar @$aliases || scalar @$tokens || scalar @$tags);

  my $perl = {};

  if (scalar @$aliases) {
    $perl->{aliases} = $aliases;
  }

  if (scalar @$tokens) {
    $perl->{device_tokens} = $tokens;
  }

  if (scalar @$tags) {
    $perl->{tags} = $tags;
  }

  return unless scalar keys %$perl;

  $perl->{aps} = $payload;

  my $body = 0;

  unless ($batch) {
    if (my $schedule = delete $args{schedule_for}) {
      if (ref $schedule && ref $schedule eq 'ARRAY') {
        $perl->{schedule_for} = $schedule ;
        $body = 1;
      }
    }

    if (my $exclude = delete $args{exclude_tokens}) {
      $perl->{exclude_tokens} = $exclude
        if ref $exclude && ref $exclude eq 'ARRAY';
    }
  }

  return ($perl, $body);
}


sub _craft_payload {

  my $self = shift;

  my %args = %{shift || {}};

  my $badge = eval { int delete $args{badge} };
  my $alert = delete $args{alert};
  my $sound = delete $args{sound};

  my $payload = {};

  $payload->{badge} = $badge if defined $badge;
  $payload->{sound} = $sound if $sound;
  $payload->{alert} = $alert if $alert;

  return unless scalar keys %$payload;

  return $payload;
}


__END__

=head1 NAME 

WebService::UrbanAirship::APNS - routines for Urban Airship Apple Push Notification service

=head1 SYNOPSIS

  # create the object
  my $o = WebService::UrbanAirship::APNS->new(application_key         => 'C9mvZ******************8QGW',
                                              application_secret      => 'DQvNtylF***************MgVG',
                                              application_push_secret => 'HGrBg37****************ylFA');

  # now do something, like register the device
  $o->register_device(device_token => 'FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660',
                      alias        => 'de039f61e64d3300aa0ce521fd6a65f780cc814e',

  # and send a notification
  $o->push(device_token => 'FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660');


=head1 DESCRIPTION

WebService::UrbanAirship::APNS contains useful routines for using the
Apple Push Notification Service for the iPhone provided by Urban
Airship, as described in http://urbanairship.com/docs/push.html

to use these routines you will need to visit http://urbanairship.com/
register with as a developer.  they will provide you with an
application key, and two secret strings which you will need
for these routines to work. 

while the Urban Airship API is fairly straightforward, a simple
wrapper always makes life a bit easier...

=head1 CONSTRUCTOR

=over 4

=item new()

instantiate a new WebService::UrbanAirship::APSN object.

  my $o = WebService::UrbanAirship::APNS->new(application_key         => 'C9mvZ******************8QGW',
                                              application_secret      => 'DQvNtylF***************MgVG',
                                              application_push_secret => 'HGrBg37****************ylFA');

the constructor arguments are as follows

=over 4

=item application_key

the Application Key assigned to your application.
this argument is required.

=item application_secret

the Application Secret assigned to your application.
this argument is required.

=item application_push_secret

the Application Push Secret assigned to your application.
this argument is required.

=back

if the required arguments are not provided the interface
will die with an error.

=back

=head1 METHODS

all methods return false on failure or true on success.  for
some methods the true value can be further distilled to
provided additional details - see each method description
for when this applies.

for the most part, these methods mirror the API described
at http://urbanairship.com/docs/push.html, so it makes
sense to read about the interface there as well.

note that the device token is *not* the device id - you
get the token from within the didRegisterForRemoteNotificationsWithDeviceToken
method from your application delegate.  how you get
the device token from the user device to a place where
you can call these methods is up to you.

=over 4

=item register_device()

registers a device with Urban Airship, which is required for
broadcasts but only recommended for individual pushes.

  my $code = $o->register_device(device_token => $token,
                                 alias        => $alias);

the 'alias' and 'tags' arguments are optional.  'alias' must
be a simple string, while '$tags' much be a reference to an array
of simple strings.

  my $code = $o->register_device(device_token => $token,
                                 tags         => [$tag1, 'tag 2']);

the return value is false on failure, 201 for when the device
is initially created, and 200 for any updates.

parallels http://urbanairship.com/docs/push.html#registration


=item ping_device()

ping Urban Airship for information about a registered device.

  my $code = $o->register_device(device_token => $token);

the return value is false on failure, and interesting json on success.

parallels the GET behavior of http://urbanairship.com/docs/push.html#registration


=item push()

sends a single push to one or more devices and/or aliases

  my $code = $o->push(device_tokens => [$token1, $token2],
                      aliases       => [$alias1],
                      badge         => 1,
                      alert         => 'coolio!',
                      sound         => 'cool.caf');

returns false on error, true on success.  if 'schedule_for'
is included as an argument, a true value will be the scheduled
notifications as json.

both the 'device_tokens' and 'aliases' arguments, if present,
must be references to arrays.  neither is required, but
if the total device tokens between the two is zero the
method will return false without actually trying to do anything.

all of 'badge', 'alert', and 'sound' are optional, but if none
exist the method will return false without actually trying
to do anything.

'schedule_for', 'exclude_tokens', and 'tags' are optional arguments.
if included, each must be an array:

  my $json = $o->push(tags           => [$tag1, $tag2],
                      badge          => 1,
                      schedule_for   => [$iso8601date],
                      exclude_tokens => [$token]);

parallels http://urbanairship.com/docs/push.html#push


=item batch()

sends multiple notifications to multiple devices in a single call

  my $code = $o->batch({ device_tokens => [$token1, $token2],
                         aliases       => [$alias1],
                         badge         => 1,
                       },
                       { aliases       => [$alias2, $alias3],
                         alert         => 'gotcha!',
                       });

returns false on error, true on success.

batch() accepts one or more hash references, each of which has the
same calling semantics as the arguments to push()

parallels http://urbanairship.com/docs/push.html#batch-push


=item broadcast()

sends a notification to every device Urban Airship knows about.

  my $code = $o->broadcast(badge => 3,
                           alert => 'Whoa!',
                           sound => 'annoyme.caf');

returns false on error, true on success.

parallels http://urbanairship.com/docs/push.html#broadcast


=item feedback()

queries Urban Airship for devices which no longer should receive
notifications from your application.

  my $response = $o->feedback(since => $date);

returns false on error, true on success.  if successful,
the return value is a JSON string listing device tokens and
dates.

the 'since' argument should be a properly formatted ISO 8601
date, such as '2009-06-01 13:00:00'.  zero checking is done
of this date for any kind of validity whatsoever - you're entirely
on your own crafting an appropriate date.

parallels http://urbanairship.com/docs/push.html#feedback-service


=item stats()

returns hourly statistics from Urban Airship

  my $response = $o->stats(start  => '2009-06-01 13:00:00',
                           end    => '2009-07-01',
                           format => 'csv');

the 'start' and 'end' arguments are required and must be
properly formatted ISO 8601 dates.  zero checking is done
by this api, blah, blah...

stats() returns false on error, true on success.  if successful,
the return value contains statistics.  by default, the results
are in JSON.  however, the optional 'format' argument can be
used to change response formats.  currently, only 'csv' is
understood by the Urban Airship API.

parallels http://urbanairship.com/docs/push.html#statistics


=back

=head1 DEBUGGING

if you are interested in verbose error messages when something 
doesn't go according to plan you can enable debugging as follows:

  use WebService::UrbanAirship::APNS;
  $WebService::UrbanAirship::APNS::DEBUG = 1;

=head1 SEE ALSO

http://urbanairship.com/docs/push.html

http://developer.apple.com/iphone/library/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Introduction/Introduction.html

=head1 AUTHOR

Geoffrey Young <geoff@modperlcookbook.org>

http://www.modperlcookbook.org/

=head1 COPYRIGHT

Copyright (c) 2009, Geoffrey Young
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
