package WWW::Live::Auth;

use strict;
use warnings;

use WWW::Live::Auth::Utils;
use Carp;

require WWW::Live::Auth::SecretKey;
require WWW::Live::Auth::ApplicationToken;
require WWW::Live::Auth::ConsentToken;
require LWP::UserAgent;
require Crypt::SSLeay; # explicitly require, otherwise you get cryptic https failures with LWP
require CGI;

our $VERSION = '1.0.1';
our $CONSENT_BASE_URL = 'https://consent.live.com/';

sub new {
  my ( $proto, %options ) = @_;
  my $class = ref $proto || $proto;

  my $app_id     = delete $options{'application_id'};
  my $secret_key = delete $options{'secret_key'};
  my $client_ip  = delete $options{'client_ip'};
  if ( $secret_key && !ref $secret_key ) {
    $secret_key = WWW::Live::Auth::SecretKey->new( $secret_key );
  }

  $options{'agent'} ||= __PACKAGE__ . "/$VERSION";
  my $self = bless {
    'secret_key'     => $secret_key,
    'application_id' => $app_id,
    '_ua'            => LWP::UserAgent->new( %options ),
    'debug'          => delete $options{'debug'},
  }, $class;
  $self->{'client_ip'} = $client_ip if ( $client_ip );

  return $self;
}

sub proxy {
  my $self = shift;
  return $self->{'_ua'}->proxy( 'https', shift );
}

sub consent_url {
  my ( $self, %args ) = @_;

  my $offers  = $args{'offers'}      || croak('List of offers is required');
  my $privacy = $args{'privacy_url'} || croak('Privacy policy URL is required');
  my $secret  = $self->{'secret_key'}     || croak('Secret key is required');
  my $app_id  = $self->{'application_id'} || croak('Application ID is required');

  if ( ref $offers ) {
    if ( ref $offers ne 'ARRAY' ) {
      $offers = [ $offers ];
    }
    $offers = join ',', map {
      ref $_ ? $_->offer . '.' . $_->action : $_
    } @{ $offers };
  }

  # https://consent.live.com/Delegation.aspx?RU=...&ps=...&pl=...[&app=...][&mkt=...][&appctx=...]
  my $url = sprintf $CONSENT_BASE_URL.'Delegation.aspx?ps=%s&pl=%s',
                    _escape( $offers ), _escape( $privacy );
  
  if ( $args{'return_url'} ) {
    $url .= '&RU=' . _escape( $args{'return_url'} );
  }

  # Client IP address is optional
  my $app_token = WWW::Live::Auth::ApplicationToken->new(
    $secret->signature_key,
    $app_id,
    $self->{'client_ip'}
  )->as_string;
  $url .= sprintf '&app=%s', $app_token;
  
  if ( $args{'market'} ) {
    $url .= '&mkt=' . _escape( $args{'market'} );
  }
  
  if ( $args{'context'} ) {
    $url .= '&appctx=' . _escape( $args{'context'} );
  }
  
  return $url;
}

sub refresh_url {
  my ( $self, %args ) = @_;
  my $consent_token = $args{'consent_token'} || croak('Consent token is required to construct a refresh URL');
  my $secret  = $self->{'secret_key'}     || croak('Secret key is required to construct a refresh URL');
  my $app_id  = $self->{'application_id'} || croak('Application ID is required to construct a refresh URL');
  
  if ( !ref $consent_token ) {
    $consent_token = WWW::Live::Auth::ConsentToken->new(
      'consent_token' => $consent_token,
      'secret_key'    => $secret,
    );
  }
  
  my $offers = join ',', map { $_->offer.'.'.$_->action } $consent_token->offers;
  
  # https://consent.live.com/RefreshToken.aspx?RU=...&ps=...&reft=...
  my $url = sprintf $CONSENT_BASE_URL.'RefreshToken.aspx?ps=%s&reft=%s',
                    _escape( $offers ),
                    $consent_token->refresh_token;
  
  if ( $args{'return_url'} ) {
    $url .= '&ru=' . _escape( $args{'return_url'} );
  }

  # Client IP address is optional
  my $app_token = WWW::Live::Auth::ApplicationToken->new(
    $secret->signature_key,
    $app_id,
    $self->{'client_ip'}
  )->as_string;
  $url .= sprintf '&app=%s', $app_token;
  
  return $url;
}

sub is_delegated_authentication {
  my ( $self, $cgi ) = @_;
  $cgi ||= CGI->new();

  if ( !$cgi->param('action') || $cgi->param('action') ne 'delauth' ) {
    return 0;
  }

  return 1;
}

sub receive_consent {
  my ( $self, $cgi ) = @_;
  $cgi ||= CGI->new();

  # Check we are processing a delegated authentication response
  if ( ! $self->is_delegated_authentication( $cgi ) ) {
    croak('Unable to process consent - request is not a delegated authentication');
  } elsif ( $cgi->param('ResponseCode') ne 'RequestApproved' ) {
    croak('Authentication denied');
  }
  
  my $consent_token = WWW::Live::Auth::ConsentToken->new(
    'secret_key'    => $self->{'secret_key'},
    'consent_token' => $cgi->param('ConsentToken'),
  );
  
  my $app_context = _unescape( $cgi->param('appctx') );
  
  return $consent_token, $app_context;
}

sub refresh_consent {
  my $self = shift;
  my $url = $self->refresh_url( @_ );
  
  if ( $self->{'debug'} ) {
    warn "About to GET $url";
  }
  
  my $request  = HTTP::Request->new(GET => $url);
  my $response = $self->{'_ua'}->request( $request );
  if ( $response->is_success ) {
    # {"ConsentToken":"delt%3dEwCoARAn ..."}
    my $raw = $response->content;
    
    my ($error, $msg) = $raw =~ m/"error":"(.+)"}(.+)/mxs;
    if ( $error ) {
      croak("Could not refresh consent token: $error - $msg");
    }
    
    my ($consent_token) = $raw =~ m/"ConsentToken":"(.+)"/mxs;
    if ( !$consent_token ) {
      return;
    }
    return WWW::Live::Auth::ConsentToken->new(
      'secret_key'    => $self->{'secret_key'},
      'consent_token' => $consent_token,
    );
    
  } else {
    croak( 'Could not contact Live service: ' . $response->status_line );
  }
}

1;
__END__

=head1 NAME

WWW::Live::Auth - A Microsoft Live authentication client

=head1 VERSION

1.0.0

=head1 DESCRIPTION

Provides delegated authentication functionality for Microsoft Live services.

=head1 SYNOPSIS

  # Construct a client object
  my $client = WWW::Live::Auth->new(
    application_id => $appid,  # string
    secret_key     => $secret, # string or WWW::Live::Auth::SecretKey object
    client_ip      => $ip      # optional
  );

  # Set the proxy (if necessary)
  $client->proxy( 'http://proxy.mycompany.com' );

  # Obtain a URL to which a user may be directed in order to grant consent
  my $url = $client->consent_url(
    offers      => 'ContactsSync.FullSync',                    # required
    privacy_url => 'http://mycompany.com/privacy_policy.html', # required
    return_url  => 'http://mycompany.com/receive_consent.cgi',
    market      => 'en-gb',
    context     => '/interesting.html',
  );

  # Parse an incoming consent notification
  my ( $token, $context ) = $client->receive_consent();

  # Refresh a consent token
  if ( $token->expires < time() ) {
    $token = $client->refresh_consent( consent_token => $token );
  }

=head1 METHODS

=head2 new

  Constructs a new authentication client for the application/client.

  my $client = WWW::Live::Auth->new(
    application_id => $appid,
    secret_key     => $secret,
    client_ip      => $ip,     # optional
  )

  The application ID and secret key are unique to your application. See
  L<http://msdn.microsoft.com/en-us/library/cc287659.aspx> for details.

=head2 proxy

  Passes proxy settings through to LWP::UserAgent. Note the proxy must be
  capable of proxying HTTPS connections.

  $client->proxy( 'http://proxy.mycompany.com' );

=head2 consent_url

  Generates a URL to which a user can be directed in order to grant consent for
  the application to access one or more actions.

  my $url = $client->consent_url(
    offers      => 'ContactsSync.FullSync',                    # required
    privacy_url => 'http://mycompany.com/privacy_policy.html', # required
    return_url  => 'http://mycompany.com/receive_consent.cgi',
    market      => 'en-gb',
    context     => '/interesting.html',
  );

  "Offers" is a comma separated list of actions offered by a resource provider.
  Once the user grants consent by visiting the URL, (s)he will be redirected to
  the return URL, along with a parameter indicating the application context.

=head2 receive_consent

  Extracts the consent token and application context from an incoming HTTP
  request. An optional CGI object may be provided as the source of the data. If
  omitted, one will be created.

  my ( $token, $context ) = $client->receive_consent( $cgi );

=head2 refresh_consent

  Automatically refreshes an expired consent token.

  if ( $token->expires < time() ) {
    $token = $client->refresh_consent(
      consent_token => $token  # required
      return_url    => $url,   # optional
    );
  }

=head2 refresh_url

  Generates a URL used for refreshing consent.

  my $url = $client->refresh_url(
    consent_token => $token,  # required
    return_url    => $url,    # optional
  );

=head1 AUTHOR

Andrew M. Jenkinson <jenkinson@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 Andrew M. Jenkinson.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 DEPENDENCIES

L<LWP::UserAgent>
L<CGI>
L<Crypt::Rijndael>
L<Digest::SHA>
L<MIME::Base64>
L<Carp>

=head1 SEE ALSO

L<WWW::Live::Contacts>

L<LWP::UserAgent>

API Errors<http://msdn.microsoft.com/en-us/library/cc287686.aspx>

=cut
