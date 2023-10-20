package WebService::GarminConnect;

use 5.006;
use warnings FATAL => 'all';
use strict;
use Carp;
use LWP::UserAgent;
use URI;
use JSON;
use Data::Dumper;
use WWW::OAuth;
use WWW::OAuth::Util qw( form_urldecode );
#use LWP::ConsoleLogger::Everywhere ();

our $VERSION = '1.1.1'; # VERSION

=head1 NAME

WebService::GarminConnect - Access data from Garmin Connect

=head1 VERSION

version 1.1.1

=head1 SYNOPSIS

With WebService::GarminConnect, you can search the activities stored on the
Garmin Connect site.

    use WebService::GarminConnect;

    my $gc = WebService::GarminConnect->new( username => 'myuser',
                                             password => 'password' );
    my @activities = $gc->activities( limit => 20 );
    foreach my $a ( @activities ) {
      my $name = $a->{name};
      ...
    }

=head1 FUNCTIONS

=head2 new( %options )

Creates a new WebService::GarminConnect object. One or more options may be
specified:

=over

=item username

(Required) The Garmin Connect username to use for searches.

=item password

(Required) The user's Garmin Connect password.

=item cache_dir

(Optional) Directory where the user's authentication token will be cached.
If not specified, defaults to $HOME/.cache/webservice-garminconnect.

=item searchurl

(Optional) Override the default search URL for Garmin Connect.

=back

=cut

sub new {
  my $self = shift;
  my %options = @_;

  # Check for mandatory options
  foreach my $required_option ( qw( username password ) ) {
    croak "option \"$required_option\" is required"
      unless defined $options{$required_option};
  }

  return bless {
    username  => $options{username},
    password  => $options{password},
    cache_dir => $options{cache_dir},
    searchurl => $options{searchurl} || 'https://connectapi.garmin.com/activitylist-service/activities/search/activities',
  }, $self;
}

sub _login {
  my $self = shift;

  # Bail out if we're already logged in.
  return if defined $self->{is_logged_in};

  my $ua = LWP::UserAgent->new(agent => 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) ' .
                                        'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148');
  $ua->cookie_jar( {} );
  push @{ $ua->requests_redirectable }, 'POST';

  # location for saved access token
  my $cache_path = $self->{cache_dir};
  if (!defined $cache_path) {
    $cache_path = (getpwuid($>))[7]."/.cache";
    -d $cache_path || mkdir $cache_path, 0700;
    $cache_path .= "/webservice-garminconnect";
    -d $cache_path || mkdir $cache_path, 0700;
  }
  # untaint
  $self->{username} =~ m/([a-z0-9+\-_.=\?@]+)/i;
  $cache_path .= "/${1}_oauth";

  # try saved access token
  if (open my $cache_fh, '<', $cache_path) {
    (my $access_token = <$cache_fh>) =~ s/\s+//;

    $ua->default_header('Authorization', 'Bearer ' . $access_token);
    $self->{useragent} = $ua;
    $self->{is_logged_in} = 1;

    # simple api call to validate
    eval { $self->profile };
    return unless $@;
  }

  my %sso_embed_params = (
    id          => 'gauth-widget',
    embedWidget => 'true',
    gauthHost   => 'https://sso.garmin.com/sso',
  );
  my $uri = URI->new('https://sso.garmin.com/sso/embed');
  $uri->query_form(%sso_embed_params);
  my $response = $ua->get($uri);
  croak "Can't retrieve /sso/embed: " . $response->status_line
    unless $response->is_success;

  my %signin_params = (
    id                              => 'gauth-widget',
    embedWidget                     => 'true',
    gauthHost                       => 'https://sso.garmin.com/sso/embed',
    service                         => 'https://sso.garmin.com/sso/embed',
    source                          => 'https://sso.garmin.com/sso/embed',
    redirectAfterAccountLoginUrl    => 'https://sso.garmin.com/sso/embed',
    redirectAfterAccountCreationUrl => 'https://sso.garmin.com/sso/embed',
  );
  $uri = URI->new('https://sso.garmin.com/sso/signin');
  $uri->query_form(%signin_params);
  $response = $ua->get($uri);
  croak "Can't retrieve /sso/signin: " . $response->status_line
    unless $response->is_success;
  # get the CSRF token from the response, it's a hidden form field
  my $csrf_token;
  if ($response->decoded_content =~ /name="_csrf"\s+value="(.+?)"/) {
    $csrf_token = $1;
  } else {
    croak "couldn't find CSRF token";
  }

  # submit login form with email and password
  $response = $ua->post($uri, Referer => "$uri", Content => {
    username => $self->{username},
    password => $self->{password},
    embed    => 'true',
    _csrf    => $csrf_token,
  });
  croak "Can't submit login  page: " . $response->status_line
    unless $response->is_success;
  my $title;
  if ($response->decoded_content =~ m:<title>(.+)</title>:) {
    $title = $1;
  } else {
    croak "couldn't find <title> in login response";
  }
  if ($title ne 'Success') {
    croak "expected post-login <title> of \"Success\", not \"$title\"";
  }
  my $ticket;
  if ($response->decoded_content =~ /embed\?ticket=([^"]+)"/) {
    $ticket = $1;
  } else {
    croak "couldn't find ticket in login response";
  }

  # get oauth1 token, these came from https://thegarth.s3.amazonaws.com/oauth_consumer.json
  # and are what the Garmin Connect mobile app uses. Perhaps we should
  # try to fetch these from there at runtime in case they ever change?
  my $oauth = WWW::OAuth->new(
    client_id => "fc3e99d2-118c-44b8-8ae3-03370dde24c0",
    client_secret => "E08WAR897WEy2knn7aFBrvegVAf0AFdWBBF",
  );


  $uri = 'https://connectapi.garmin.com/oauth-service/oauth/' .
         "preauthorized?ticket=$ticket&login-url=" .
         'https://sso.garmin.com/sso/embed&accepts-mfa-tokens=true';
  $ua->add_handler(request_prepare => sub { $oauth->authenticate($_[0]) });
  $response = $ua->get($uri);
  croak "Can't retrieve oauth1 page: " . $response->status_line
    unless $response->is_success;
  my %response_data = @{form_urldecode($response->content)};
  foreach my $key ( qw( oauth_token oauth_token_secret ) ) {
    if (!defined $response_data{$key}) {
      croak "oauth response didn't include \"$key\"";
    }
  }
  $oauth->token($response_data{oauth_token});
  $oauth->token_secret($response_data{oauth_token_secret});

  $uri = 'https://connectapi.garmin.com/oauth-service/oauth/exchange/user/2.0';
  $response = $ua->post($uri);
  croak "Can't retrieve oauth1 page: " . $response->status_line
    unless $response->is_success;
  my $response_data = decode_json($response->content);
  if (!defined $response_data->{access_token}) {
    croak "couldn't find access token in response";
  }

  # make subsequent calls use the access token in the Authorization header
  $ua->remove_handler('request_prepare');
  my $access_token = $response_data->{access_token};
  $ua->default_header('Authorization', 'Bearer ' . $access_token);

  #$uri = 'https://connectapi.garmin.com/activitylist-service/activities/search/activities?limit=20&start=0';
  #$response = $ua->get($uri);
  #croak "Can't retrieve activity search  page: " . $response->status_line
  #  unless $response->is_success;

  # Record our logged-in status so future calls will skip login.
  $self->{useragent} = $ua;
  $self->{is_logged_in} = 1;

  # save access token
  if (open my $cache_fh, '>', $cache_path) {
    chmod 0600, $cache_fh;
    print $cache_fh $access_token, "\n";
    close $cache_fh;
  }
}

sub _api {
  my $self = shift;
  my ($api, %opts) = @_;
  my $json = JSON->new();

  # Ensure we are logged in
  $self->_login();
  my $ua = $self->{useragent};

  my $url = URI->new($self->{searchurl});
	$url->path($api);
  $url->query_form(%opts);

  my $headers = [
    'NK' => 'NT',
    'X-app-ver' => '4.71.1.4',
    'X-lang' => 'en-US',
    'X-Requested-With' => 'XMLHttpRequest',
  ];
  my $request = HTTP::Request->new('GET', $url, $headers);
  my $response = $ua->request($request);
  croak "Can't make $api request: " . $response->status_line
    unless $response->is_success;

  return $json->decode($response->content);
}

=head2 profile

Returns the user's Garmin Connect profile

=cut

sub profile {
  my $self = shift;
  return $self->_api("/userprofile-service/socialProfile");
}

=head2 activities( %search_criteria )

Returns a list of activities matching the requested criteria. If no criteria
are specified, returns all the user's activities. Possible criteria:

=over

=item limit

(Optional) The maximum number of activities to return. If not specified,
all the user's activities will be returned.

=item pagesize

(Optional) The number of activities to return in each call to Garmin
Connect. (One call to this subroutine may call Garmin Connect several
times to retrieve all the requested activities.) Defaults to 50.

=back

=cut

sub activities {
  my $self = shift;
  my %opts = @_;
  my $json = JSON->new();

  # Ensure we are logged in
  $self->_login();
  my $ua = $self->{useragent};

  # We can only fetch a fixed number of activities at a time.
  my @activities;
  my $start = 0;
  my $pagesize = 50;
  if( defined $opts{pagesize} ) {
    if( $opts{pagesize} > 0 && $opts{pagesize} < 50 ) {
      $pagesize = $opts{pagesize};
    }
  }

  # Special case when the limit is smaller than one page.
  if( defined $opts{limit} ) {
    if( $opts{limit} < $pagesize ) {
      $pagesize = $opts{limit};
    }
  }

  my $data = [];
  do {
    # Make a search request
    $data = $self->_api("/activitylist-service/activities/search/activities", start => $start, limit => $pagesize);

    # Add this set of activities to the list.
    foreach my $activity ( @{$data} ) {
      if( defined $opts{limit} ) {
        # add this activity only if we're under the limit
        if( @activities < $opts{limit} ) {
          push @activities, { activity => $activity };
        } else {
          $data = []; # stop retrieving more activities
          last;
	}
      } else {
        push @activities, { activity => $activity };
      }
    }

    # Increment the start offset for the next request.
    $start += $pagesize;

  } while( @{$data} > 0 );

  return @activities;
}

=head1 AUTHOR

Joel Loudermilk, C<< <joel at loudermilk.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jlouder/garmin-connect-perl/issues>.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::GarminConnect


You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-GarminConnect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-GarminConnect>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-GarminConnect>

=item * GitHub Repository

L<https://github.com/jlouder/garmin-connect-perl>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2023 Joel Loudermilk.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

1; # End of WebService::GarminConnect
