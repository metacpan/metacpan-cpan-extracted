package FakeKeycloak;

# An in-memory stand-in for the parts of Keycloak 26 that WWW::Keycloak talks
# to, answering the way the real one was observed to answer: 201 with a
# Location header and no body when something is created, 409 with
# errorMessage for a duplicate, 404 with error for something missing, 401
# for a token it does not know, masked values when an authenticator
# configuration is read.
#
#   my $fake = FakeKeycloak->new;
#   my $kc   = WWW::Keycloak->new( base_url => $fake->base, realm => 'r', username => 'admin', password => 'admin', ua => $fake );

use strict;
use warnings;
use parent 'LWP::UserAgent';
use Crypt::JWT qw( encode_jwt );
use Crypt::PK::RSA;
use HTTP::Response;
use JSON::MaybeXS;
use URI;
use URI::Escape ();

my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub new {
  my ( $class, %arg ) = @_;
  my $self = $class->SUPER::new;
  my $key  = Crypt::PK::RSA->new;
  $key->generate_key( 256, 65537 );
  %$self = (
    %$self,
    base       => 'http://kc.test',
    now        => $arg{now} || sub { time },
    expires_in => $arg{expires_in} // 300,
    key        => $key,
    kid        => 'key-1',
    tokens     => {},
    logins     => [],
    requests   => [],
    seq        => 0,
    realms     => {}
  );
  $self->add_realm('master');
  return $self;
}

sub base     { $_[0]{base} }
sub logins   { $_[0]{logins} }
sub requests { $_[0]{requests} }
sub realm    { $_[0]{realms}{ $_[1] } }

# what a Keycloak restart does to the admin tokens it handed out
sub forget_tokens { $_[0]{tokens} = {} }

sub rotate_key {
  my ( $self ) = @_;
  my $key = Crypt::PK::RSA->new;
  $key->generate_key( 256, 65537 );
  $self->{key} = $key;
  $self->{kid} = 'rotated-'.++$self->{seq};
  return;
}

sub add_realm {
  my ( $self, $name, %rep ) = @_;
  $self->{realms}{$name} = {
    rep     => { realm => $name, enabled => JSON::MaybeXS::true, accessTokenLifespan => 300, %rep },
    clients => {},
    scopes  => {},
    users   => {},
    mappers => {},
    configs => {},
    flows   => {
      'browser' => [
        { id => 'e-cookie', providerId => 'auth-cookie', level => 0 },
        { id => 'e-forms', displayName => 'forms', level => 0 },
        { id => 'e-pwd', providerId => 'auth-username-password-form', level => 1 },
        { id => 'e-otp', providerId => 'auth-otp-form', level => 2 }
      ],
      'direct grant' => [
        { id => 'e-dg-pwd', providerId => 'direct-grant-validate-password', level => 0 },
        { id => 'e-dg-otp', providerId => 'direct-grant-validate-otp', level => 1 }
      ]
    }
  };
  return;
}

sub sign {
  my ( $self, $claims, %opt ) = @_;
  return encode_jwt( payload => $claims, alg => $opt{alg} // 'RS256', key => $opt{key} // $self->{key}, extra_headers => { kid => $opt{kid} // $self->{kid} } );
}

sub _id { 'id-'.++$_[0]{seq} }

sub _reply {
  my ( $self, $status, $data, %header ) = @_;
  my $response = HTTP::Response->new( $status, $status < 300 ? 'OK' : 'Error' );
  $response->header( %header ) if %header;
  if ( defined $data ) {
    $response->header( 'Content-Type' => 'application/json' );
    $response->content( $JSON->encode($data) );
  }
  return $response;
}

sub request {
  my ( $self, $request ) = @_;
  push @{ $self->{requests} }, $request;
  my $uri  = URI->new( $request->uri );
  my $path = $uri->path;
  my %query = $uri->query_form;
  my $body;
  if ( length( $request->content // '' ) ) {
    $body = ( $request->header('Content-Type') // '' ) =~ /json/ ? $JSON->decode( $request->content ) : { URI->new( 'http:?'.$request->content )->query_form };
  }
  my $method = $request->method;

  if ( $path =~ m{\A/realms/([^/]+)/(.*)\z} ) {
    my ( $realm, $rest ) = ( $1, $2 );
    return $self->_reply( 404, { error => 'Realm does not exist' } ) unless $self->{realms}{$realm};
    return $self->_oidc( $realm, $rest, $method, $body, $request );
  }
  return $self->_reply( 404, { error => 'not found' } ) unless $path =~ m{\A/admin/(.*)\z};
  my $admin = $1;
  my ( $bearer ) = ( $request->header('Authorization') // '' ) =~ /\ABearer (.+)\z/;
  return $self->_reply( 401, { error => 'HTTP 401 Unauthorized' } ) unless $bearer && $self->{tokens}{$bearer};

  return $self->_reply( 200, { systemInfo => { version => '26.8.0' } } ) if $admin eq 'serverinfo';
  if ( $admin eq 'realms' && $method eq 'POST' ) {
    return $self->_reply( 409, { errorMessage => 'Realm '.$body->{realm}.' already exists' } ) if $self->{realms}{ $body->{realm} };
    $self->add_realm( $body->{realm}, %$body );
    return $self->_reply( 201, undef, Location => $self->{base}.'/admin/realms/'.$body->{realm} );
  }
  $admin =~ m{\Arealms/([^/]+)(.*)\z} or return $self->_reply( 404, { error => 'not found' } );
  my ( $name, $rest ) = ( URI::Escape::uri_unescape($1), $2 );
  my $realm = $self->{realms}{$name} or return $self->_reply( 404, { error => 'Realm not found.' } );
  return $self->_admin( $name, $realm, $rest, $method, $body, \%query );
}

sub _oidc {
  my ( $self, $realm, $rest, $method, $body, $request ) = @_;
  my $issuer = $self->{base}.'/realms/'.$realm;
  if ( $rest eq '.well-known/openid-configuration' ) {
    return $self->_reply( 200, {
      issuer                        => $issuer,
      token_endpoint                => $issuer.'/protocol/openid-connect/token',
      userinfo_endpoint             => $issuer.'/protocol/openid-connect/userinfo',
      introspection_endpoint        => $issuer.'/protocol/openid-connect/token/introspect',
      end_session_endpoint          => $issuer.'/protocol/openid-connect/logout',
      device_authorization_endpoint => $issuer.'/protocol/openid-connect/auth/device',
      jwks_uri                      => $issuer.'/protocol/openid-connect/certs'
    } );
  }
  if ( $rest eq 'protocol/openid-connect/certs' ) {
    return $self->_reply( 200, { keys => [ { %{ $self->{key}->export_key_jwk( 'public', 1 ) }, kid => $self->{kid}, use => 'sig', alg => 'RS256' } ] } );
  }
  if ( $rest eq 'protocol/openid-connect/token' ) {
    push @{ $self->{logins} }, { realm => $realm, %$body };
    my $grant = $body->{grant_type} // '';
    if ( $grant eq 'password' ) {
      return $self->_reply( 400, { error => 'invalid_grant', error_description => 'Invalid user credentials' } )
        unless ( $body->{username} // '' ) eq 'admin' && ( $body->{password} // '' ) eq 'admin';
    }
    elsif ( $grant eq 'client_credentials' ) {
      return $self->_reply( 401, { error => 'unauthorized_client', error_description => 'Invalid client or Invalid client credentials' } )
        unless ( $body->{client_secret} // '' ) eq 'secret';
    }
    elsif ( $grant eq 'refresh_token' ) {
      return $self->_reply( 400, { error => 'invalid_grant', error_description => 'Invalid refresh token' } )
        unless $body->{refresh_token} && $self->{tokens}{ 'refresh:'.$body->{refresh_token} };
    }
    elsif ( $grant eq 'urn:ietf:params:oauth:grant-type:device_code' ) {
      return $self->_reply( 400, { error => 'authorization_pending', error_description => 'The authorization request is still pending' } );
    }
    else {
      return $self->_reply( 400, { error => 'unsupported_grant_type', error_description => 'Unsupported grant_type' } );
    }
    my $access  = 'at-'.$self->_id;
    my $refresh = 'rt-'.$self->_id;
    $self->{tokens}{$access} = 1;
    $self->{tokens}{ 'refresh:'.$refresh } = 1;
    return $self->_reply( 200, { access_token => $access, expires_in => $self->{expires_in}, refresh_token => $refresh, refresh_expires_in => 1800, token_type => 'Bearer' } );
  }
  if ( $rest eq 'protocol/openid-connect/auth/device' ) {
    return $self->_reply( 200, { device_code => 'dc', user_code => 'ABCD-EFGH', verification_uri => $issuer.'/device', verification_uri_complete => $issuer.'/device?user_code=ABCD-EFGH', expires_in => 600, interval => 5 } );
  }
  if ( $rest eq 'protocol/openid-connect/userinfo' ) {
    my ( $bearer ) = ( $request->header('Authorization') // '' ) =~ /\ABearer (.+)\z/;
    return $self->_reply( 401, { error => 'invalid_token' } ) unless ( $bearer // '' ) eq 'user-token';
    return $self->_reply( 200, { sub => 'u-1', preferred_username => 'alice' } );
  }
  if ( $rest eq 'protocol/openid-connect/token/introspect' ) {
    return $self->_reply( 200, { active => ( $body->{token} // '' ) eq 'user-token' ? JSON::MaybeXS::true : JSON::MaybeXS::false } );
  }
  if ( $rest eq 'protocol/openid-connect/logout' ) {
    return $self->_reply( 204 );
  }
  return $self->_reply( 404, { error => 'not found' } );
}

sub _admin {
  my ( $self, $name, $realm, $rest, $method, $body, $query ) = @_;
  my $created = sub { $self->_reply( 201, undef, Location => $self->{base}.'/admin/realms/'.$name.$_[0] ) };

  if ( $rest eq '' ) {
    return $self->_reply( 200, { %{ $realm->{rep} } } ) if $method eq 'GET';
    if ( $method eq 'PUT' ) { %{ $realm->{rep} } = ( %{ $realm->{rep} }, %$body ); return $self->_reply(204) }
    if ( $method eq 'DELETE' ) { delete $self->{realms}{$name}; return $self->_reply(204) }
  }

  # clients
  if ( $rest eq '/clients' ) {
    if ( $method eq 'GET' ) {
      return $self->_reply( 200, [ grep { !defined $query->{clientId} || $_->{clientId} eq $query->{clientId} } map { { %$_ } } sort { $a->{id} cmp $b->{id} } values %{ $realm->{clients} } ] );
    }
    return $self->_reply( 409, { errorMessage => 'Client '.$body->{clientId}.' already exists' } )
      if grep { $_->{clientId} eq $body->{clientId} } values %{ $realm->{clients} };
    my $id = $self->_id;
    $realm->{clients}{$id} = { publicClient => JSON::MaybeXS::false, enabled => JSON::MaybeXS::true, attributes => {}, %$body, id => $id };
    $realm->{clients}{$id}{$_} = [ sort @{ $body->{$_} } ] for grep { ref $body->{$_} eq 'ARRAY' } qw( redirectUris webOrigins );
    return $created->( '/clients/'.$id );
  }
  if ( $rest =~ m{\A/clients/([^/]+)(.*)\z} ) {
    my ( $id, $sub ) = ( $1, $2 );
    my $client = $realm->{clients}{$id} or return $self->_reply( 404, { error => 'Could not find client' } );
    if ( $sub eq '' ) {
      return $self->_reply( 200, { %$client } ) if $method eq 'GET';
      if ( $method eq 'PUT' ) {
        # a client update ignores the scope lists, and Keycloak keeps URI lists sorted
        my %new = ( %$body, id => $id );
        $new{$_} = $client->{$_} for grep { exists $client->{$_} } qw( defaultClientScopes optionalClientScopes );
        delete @new{ grep { !exists $client->{$_} } qw( defaultClientScopes optionalClientScopes ) };
        $new{$_} = [ sort @{ $new{$_} } ] for grep { ref $new{$_} eq 'ARRAY' } qw( redirectUris webOrigins );
        $realm->{clients}{$id} = \%new;
        return $self->_reply(204);
      }
      if ( $method eq 'DELETE' ) { delete $realm->{clients}{$id}; return $self->_reply(204) }
    }
    return $self->_reply( 200, { type => 'secret', value => 'client-secret-'.$id } ) if $sub eq '/client-secret';
    return $self->_reply( 200, { username => 'service-account-'.$client->{clientId} } ) if $sub eq '/service-account-user';
    if ( $sub =~ m{\A/default-client-scopes/(.+)\z} ) { push @{ $client->{defaultClientScopes} }, $1; return $self->_reply(204) }
    return $self->_mappers( $name, 'clients', $id, $sub, $method, $body ) if $sub =~ m{\A/protocol-mappers/models};
  }

  # client scopes
  if ( $rest eq '/client-scopes' ) {
    return $self->_reply( 200, [ map { { %$_ } } sort { $a->{id} cmp $b->{id} } values %{ $realm->{scopes} } ] ) if $method eq 'GET';
    return $self->_reply( 409, { errorMessage => 'Client Scope '.$body->{name}.' already exists' } )
      if grep { $_->{name} eq $body->{name} } values %{ $realm->{scopes} };
    my $id = $self->_id;
    $realm->{scopes}{$id} = { %$body, id => $id };
    return $created->( '/client-scopes/'.$id );
  }
  if ( $rest =~ m{\A/client-scopes/([^/]+)(.*)\z} ) {
    my ( $id, $sub ) = ( $1, $2 );
    my $scope = $realm->{scopes}{$id} or return $self->_reply( 404, { error => 'Could not find client scope' } );
    if ( $sub eq '' ) {
      return $self->_reply( 200, { %$scope } ) if $method eq 'GET';
      if ( $method eq 'PUT' ) { $realm->{scopes}{$id} = { %$body, id => $id }; return $self->_reply(204) }
      if ( $method eq 'DELETE' ) { delete $realm->{scopes}{$id}; return $self->_reply(204) }
    }
    return $self->_mappers( $name, 'client-scopes', $id, $sub, $method, $body ) if $sub =~ m{\A/protocol-mappers/models};
  }
  if ( $rest =~ m{\A/default-default-client-scopes/(.+)\z} ) { push @{ $realm->{rep}{defaultDefaultClientScopes} }, $1; return $self->_reply(204) }

  # users
  if ( $rest eq '/users' ) {
    if ( $method eq 'GET' ) {
      return $self->_reply( 200, [ grep { !defined $query->{username} || $_->{username} eq lc $query->{username} } map { my %u = %$_; delete $u{credentials}; \%u } sort { $a->{id} cmp $b->{id} } values %{ $realm->{users} } ] );
    }
    my $username = lc $body->{username};
    return $self->_reply( 409, { errorMessage => 'User exists with same username' } )
      if grep { $_->{username} eq $username } values %{ $realm->{users} };
    my $id = $self->_id;
    $realm->{users}{$id} = { enabled => JSON::MaybeXS::false, %$body, username => $username, defined $body->{email} ? ( email => lc $body->{email} ) : (), id => $id, credentials => [ map { { %$_, id => $self->_id } } @{ $body->{credentials} || [] } ] };
    return $created->( '/users/'.$id );
  }
  if ( $rest =~ m{\A/users/([^/]+)(.*)\z} ) {
    my ( $id, $sub ) = ( $1, $2 );
    my $user = $realm->{users}{$id} or return $self->_reply( 404, { error => 'User not found' } );
    if ( $sub eq '' ) {
      if ( $method eq 'GET' ) { my %u = %$user; delete $u{credentials}; return $self->_reply( 200, \%u ) }
      if ( $method eq 'PUT' ) {
        my %b = %$body;
        delete $b{credentials};
        # the user profile: a PUT that carries attributes drops the profile
        # fields it does not name, and attribute values are lists of strings
        if ( exists $b{attributes} ) {
          delete @{$user}{ grep { !exists $b{$_} } qw( email firstName lastName ) };
          $b{attributes} = { map { $_ => ref $b{attributes}{$_} eq 'ARRAY' ? $b{attributes}{$_} : [ $b{attributes}{$_} ] } keys %{ $b{attributes} || {} } };
        }
        %$user = ( %$user, %b, id => $id );
        return $self->_reply(204);
      }
      if ( $method eq 'DELETE' ) { delete $realm->{users}{$id}; return $self->_reply(204) }
    }
    if ( $sub eq '/reset-password' ) {
      $user->{credentials} = [ ( grep { $_->{type} ne 'password' } @{ $user->{credentials} } ), { %$body, id => $self->_id } ];
      return $self->_reply(204);
    }
    return $self->_reply( 200, [ map { { id => $_->{id}, type => $_->{type} } } @{ $user->{credentials} } ] ) if $sub eq '/credentials';
    if ( $sub =~ m{\A/credentials/(.+)\z} ) { my $cid = $1; $user->{credentials} = [ grep { $_->{id} ne $cid } @{ $user->{credentials} } ]; return $self->_reply(204) }
    return $self->_reply( 200, [] ) if $sub eq '/sessions';
    return $self->_reply(204) if $sub eq '/logout';
  }

  # authentication
  return $self->_reply( 200, [ map { { alias => $_, builtIn => JSON::MaybeXS::true } } sort keys %{ $realm->{flows} } ] ) if $rest eq '/authentication/flows';
  if ( $rest =~ m{\A/authentication/flows/([^/]+)/(executions|copy)\z} ) {
    my ( $alias, $what ) = ( URI::Escape::uri_unescape($1), $2 );
    my $flow = $realm->{flows}{$alias} or return $self->_reply( 404, { error => 'Flow not found' } );
    return $self->_reply( 200, [ map { { %$_ } } @$flow ] ) if $what eq 'executions';
    $realm->{flows}{ $body->{newName} } = [ map { { %$_, id => $_->{id}.'-copy' } } @$flow ];
    return $created->( '/authentication/flows/'.$alias.'/copy/'.$self->_id );
  }
  if ( $rest =~ m{\A/authentication/executions/([^/]+)/config\z} ) {
    my $execution_id = $1;
    my ( $execution ) = grep { $_->{id} eq $execution_id } map { @$_ } values %{ $realm->{flows} };
    return $self->_reply( 404, { error => 'Illegal execution' } ) unless $execution;
    my $id = $self->_id;
    $realm->{configs}{$id} = { %$body, id => $id };
    $execution->{authenticationConfig} = $id;
    return $created->( '/authentication/config/'.$id );
  }
  if ( $rest =~ m{\A/authentication/config/([^/]+)\z} ) {
    my $config = $realm->{configs}{$1} or return $self->_reply( 404, { error => 'Could not find authenticator config' } );
    return $self->_reply( 200, { %$config, config => { map { $_ => '**********' } keys %{ $config->{config} } } } ) if $method eq 'GET';
    %$config = ( %$body, id => $config->{id} );
    return $self->_reply(204);
  }
  return $self->_reply( 200, { properties => [] } ) if $rest =~ m{\A/authentication/config-description/};
  if ( $rest =~ m{\A/partial-export} ) { return $self->_reply( 200, { realm => $name, clients => [ values %{ $realm->{clients} } ] } ) }
  if ( $rest eq '/partialImport' ) {
    my $added = 0;
    for my $user ( @{ $body->{users} || [] } ) { my $id = $self->_id; $realm->{users}{$id} = { %$user, username => lc $user->{username}, id => $id }; $added++ }
    return $self->_reply( 200, { added => $added, skipped => 0, overwritten => 0 } );
  }
  return $self->_reply( 404, { error => 'not found: '.$method.' '.$rest } );
}

sub _mappers {
  my ( $self, $name, $kind, $owner, $sub, $method, $body ) = @_;
  my $realm   = $self->{realms}{$name};
  my $mappers = $realm->{mappers}{ $kind.'/'.$owner } ||= {};
  if ( $sub eq '/protocol-mappers/models' ) {
    return $self->_reply( 200, [ map { { %$_ } } sort { $a->{id} cmp $b->{id} } values %$mappers ] ) if $method eq 'GET';
    return $self->_reply( 409, { errorMessage => 'Protocol mapper exists with same name' } ) if grep { $_->{name} eq $body->{name} } values %$mappers;
    my $id = $self->_id;
    $mappers->{$id} = { config => {}, %$body, id => $id };
    return $self->_reply( 201, undef, Location => $self->{base}.'/admin/realms/'.$name.'/'.$kind.'/'.$owner.'/protocol-mappers/models/'.$id );
  }
  $sub =~ m{\A/protocol-mappers/models/(.+)\z} or return $self->_reply( 404, { error => 'not found' } );
  my $mapper = $mappers->{$1} or return $self->_reply( 404, { error => 'Model not found' } );
  if ( $method eq 'PUT' ) { %$mapper = ( %$body, id => $mapper->{id} ); return $self->_reply(204) }
  if ( $method eq 'DELETE' ) { delete $mappers->{ $mapper->{id} }; return $self->_reply(204) }
  return $self->_reply( 200, { %$mapper } );
}

1;
