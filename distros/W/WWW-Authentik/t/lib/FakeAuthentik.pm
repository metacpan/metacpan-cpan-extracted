package FakeAuthentik;

# An in-memory stand-in for the parts of authentik 2026.8.3 that
# WWW::Authentik talks to, answering the way the real one was observed to
# answer (design spec, section 8): 201 with the whole object and no Location
# header when something is created, 400 with a field error for a duplicate,
# 403 for a token it does not know, 404 with "No <Model> matches the given
# query.", the OAuth shape at the token endpoint and a bare WWW-Authenticate
# header at the userinfo endpoint.
#
#   my $fake = FakeAuthentik->new;
#   my $ak   = WWW::Authentik->new( base_url => $fake->base, application => 'probe-app',
#                                   token => $fake->token, ua => $fake );

use strict;
use warnings;
use parent 'LWP::UserAgent';
use Crypt::JWT qw( encode_jwt );
use Crypt::PK::RSA;
use HTTP::Response;
use JSON::MaybeXS;
use URI;

my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1, allow_nonref => 1 );

# collection => how it behaves. `path` is the list address, `detail` the field
# the detail address uses, `key` the field a duplicate is recognised by,
# `model` the name authentik puts into a 404, `required` the fields a create
# needs, `duplicate` the message a second create answers with.
my %COLLECTION = (
  users => {
    path => '/api/v3/core/users/', detail => 'pk', key => 'username', model => 'User', pk => 'int',
    required => [qw( username name )], duplicate => 'This field must be unique.',
    defaults => { is_active => \1, attributes => {}, groups => [], path => 'users', type => 'internal' }
  },
  groups => {
    path => '/api/v3/core/groups/', detail => 'pk', key => 'name', model => 'Group', pk => 'uuid',
    required => [qw( name )], duplicate => 'Group with this name already exists.',
    defaults => { is_superuser => \0, attributes => {}, users => [], parent => undef }
  },
  tokens => {
    path => '/api/v3/core/tokens/', detail => 'identifier', key => 'identifier', model => 'Token', pk => 'uuid',
    required => [qw( identifier )], duplicate => 'Token with this identifier already exists.',
    defaults => { intent => 'api', description => '', managed => undef }
  },
  applications => {
    path => '/api/v3/core/applications/', detail => 'slug', key => 'slug', model => 'Application', pk => 'uuid',
    required => [qw( name slug )], duplicate => 'Application with this slug already exists.',
    defaults => { provider => undef, meta_description => '', meta_launch_url => '', policy_engine_mode => 'any', open_in_new_tab => \0 }
  },
  providers => {
    path => '/api/v3/providers/oauth2/', detail => 'pk', key => 'name', model => 'OAuth2Provider', pk => 'int',
    required => [qw( name authorization_flow invalidation_flow redirect_uris )],
    duplicate => 'provider with this name already exists.',
    defaults => { client_type => 'confidential', grant_types => [], property_mappings => [],
      sub_mode => 'hashed_user_id', issuer_mode => 'per_provider', access_token_validity => 'minutes=5',
      refresh_token_validity => 'days=30', signing_key => undef, include_claims_in_id_token => \1 }
  },
  mappings => {
    path => '/api/v3/propertymappings/provider/scope/', detail => 'pk', key => 'name', model => 'ScopeMapping', pk => 'uuid',
    required => [qw( name expression scope_name )], duplicate => 'Property Mapping with this name already exists.',
    defaults => { managed => undef, description => '', component => 'ak-property-mapping-provider-scope-form' }
  },
  flows => {
    path => '/api/v3/flows/instances/', detail => 'slug', key => 'slug', model => 'Flow', pk => 'uuid',
    required => [qw( name slug title designation )], duplicate => 'Flow with this slug already exists.',
    defaults => { authentication => 'none', layout => 'stacked', denied_action => 'message_continue',
      policy_engine_mode => 'any', compatibility_mode => \0, stages => [] }
  },
  bindings => {
    path => '/api/v3/flows/bindings/', detail => 'pk', key => undef, model => 'FlowStageBinding', pk => 'uuid',
    required => [qw( target stage order )],
    defaults => { evaluate_on_plan => \0, re_evaluate_policies => \1, policy_engine_mode => 'any', invalid_response_action => 'retry' }
  },
  stages => {
    path => '/api/v3/stages/', detail => 'pk', key => 'name', model => 'Stage', pk => 'uuid',
    required => [qw( name )], duplicate => 'stage with this name already exists.',
    defaults => {}
  },
  certificates => {
    path => '/api/v3/crypto/certificatekeypairs/', detail => 'pk', key => 'name', model => 'CertificateKeyPair', pk => 'uuid',
    required => [qw( name )], duplicate => 'Certificate-Key Pair with this name already exists.',
    defaults => { private_key_available => \1, managed => undef }
  },
  brands => {
    path => '/api/v3/core/brands/', detail => 'brand_uuid', key => 'domain', model => 'Brand', pk => 'uuid',
    required => [qw( domain )], duplicate => 'Brand with this domain already exists.',
    defaults => { default => \0 }
  },
  blueprints => {
    path => '/api/v3/managed/blueprints/', detail => 'pk', key => 'name', model => 'BlueprintInstance', pk => 'uuid',
    required => [qw( name )], duplicate => 'Blueprint Instance with this name already exists.',
    defaults => { enabled => \1, status => 'unknown', managed_models => [], metadata => {}, context => {} }
  }
);

# fields authentik ignores when they are written
my @READ_ONLY = qw( pk num_pk uid uuid component verbose_name verbose_name_plural meta_model_name
  assigned_application_slug assigned_application_name launch_url date_joined password_change_date
  last_updated client_id is_superuser cache_count export_url pbm_uuid policybindingmodel_ptr_id );

sub new {
  my ( $class, %arg ) = @_;
  my $self = $class->SUPER::new;
  my $key  = Crypt::PK::RSA->new;
  $key->generate_key( 256, 65537 );
  %$self = (
    %$self,
    base          => 'http://ak.test',
    token         => 'fake-api-token',
    now           => $arg{now} || sub { time },
    expires_in    => $arg{expires_in} // 300,
    key           => $key,
    kid           => 'key-1',
    seq           => 0,
    requests      => [],
    writes        => 0,
    passwords     => {},
    data          => { map { $_ => {} } keys %COLLECTION },
    oauth         => { access => {}, refresh => {}, codes => {}, devices => {} },
    break_paging  => 0
  );
  $self->_seed unless $arg{empty};
  return $self;
}

sub base         { $_[0]{base} }
sub token        { $_[0]{token} }
sub requests     { $_[0]{requests} }
sub writes       { $_[0]{writes} }
sub reset_writes { $_[0]{writes} = 0; return }
sub passwords    { $_[0]{passwords} }
sub collection   { $_[0]{data}{ $_[1] } }
sub kid          { $_[0]{kid} }
sub public_key   { JSON::MaybeXS->new->decode( $_[0]{key}->export_key_jwk('public') ) }
sub break_pagination { $_[0]{break_paging} = defined $_[1] ? $_[1] : 1; return }

sub rotate_key {
  my ( $self ) = @_;
  my $key = Crypt::PK::RSA->new;
  $key->generate_key( 256, 65537 );
  $self->{key} = $key;
  $self->{kid} = 'rotated-'.++$self->{seq};
  return;
}

sub _uuid {
  my ( $self ) = @_;
  my $n = ++$self->{seq};
  return sprintf '%08x-%04x-4000-8000-%012x', $n, $n, $n;
}

sub _next_int {
  my ( $self, $name ) = @_;
  my $max = 0;
  for ( values %{ $self->{data}{$name} } ) { $max = $_->{pk} if ( $_->{pk} // 0 ) > $max }
  return $max + 1;
}

# add( users => { username => 'x', name => 'X' } ) seeds an object directly,
# honouring a pk that was given
sub add {
  my ( $self, $name, $rep ) = @_;
  my $spec = $COLLECTION{$name} or die 'no such collection: '.$name;
  my %object = ( %{ $spec->{defaults} || {} }, %$rep );
  my $pk_field = $name eq 'brands' ? 'brand_uuid' : 'pk';
  $object{$pk_field} //= $spec->{pk} eq 'int' ? $self->_next_int($name) : $self->_uuid;
  $self->{data}{$name}{ $object{$pk_field} } = \%object;
  return \%object;
}

sub _seed {
  my ( $self ) = @_;
  $self->add( users => { pk => 1, username => 'akadmin', name => 'authentik Default Admin', email => 'akadmin@example.org' } );
  $self->add( certificates => { name => 'authentik Self-signed Certificate' } );
  $self->add( brands => { domain => 'authentik-default', default => \1 } );
  for my $flow (
    [ 'default-authentication-flow',                     'Welcome to authentik!', 'authentication' ],
    [ 'default-provider-authorization-implicit-consent', 'Authorize Application', 'authorization' ],
    [ 'default-provider-invalidation-flow',              'Logged out of application', 'invalidation' ],
    [ 'default-authenticator-totp-setup',                'Set up Two-Factor authentication', 'stage_configuration' ]
  ) {
    $self->add( flows => { slug => $flow->[0], name => $flow->[1], title => $flow->[1], designation => $flow->[2] } );
  }
  for my $scope (qw( openid email profile offline_access )) {
    $self->add( mappings => {
      name       => "authentik default OAuth Mapping: OpenID '".$scope."'",
      scope_name => $scope,
      managed    => 'goauthentik.io/providers/oauth2/scope-'.$scope,
      expression => 'return {}'
    } );
  }
  $self->add( stages => { name => 'default-authentication-password', _type => 'password',
    component => 'ak-stage-password-form', backends => ['authentik.core.auth.InbuiltBackend'], failed_attempts_before_cancel => 5 } );
  $self->add( stages => { name => 'default-authentication-mfa-validation', _type => 'authenticator/validate',
    component => 'ak-stage-authenticator-validate-form', not_configured_action => 'skip',
    device_classes => [qw( static totp webauthn )], configuration_stages => [] } );
  return;
}

####  signing

sub sign {
  my ( $self, $claims, %opt ) = @_;
  my $alg = $opt{alg} // 'RS256';
  return encode_jwt( payload => $claims, alg => 'none', allow_none => 1 ) if $alg eq 'none';
  return encode_jwt( payload => $claims, alg => $alg, key => '0123456789abcdef0123456789abcdef' ) if $alg =~ /\AHS/;
  my $key = $opt{key} || $self->{key};
  return encode_jwt( payload => $claims, alg => $alg, key => $key,
    extra_headers => { kid => $opt{kid} // ( $opt{key} ? 'unknown-kid' : $self->{kid} ), typ => 'JWT' } );
}

sub issuer_for { $_[0]{base}.'/application/o/'.$_[1].'/' }

sub claims_for {
  my ( $self, %arg ) = @_;
  my $now = $self->{now}->();
  return {
    iss       => $arg{iss} // $self->issuer_for( $arg{slug} // 'probe-app' ),
    sub       => $arg{sub} // 'fake-subject',
    aud       => $arg{aud} // 'fake-client-id',
    exp       => $arg{exp} // $now + $self->{expires_in},
    iat       => $now,
    auth_time => $arg{auth_time} // $now,
    acr       => 'goauthentik.io/providers/oauth2/default',
    jti       => 'jti-'.++$self->{seq},
    preferred_username => $arg{username} // 'probe-alice',
    ( $arg{amr}   ? ( amr   => $arg{amr} )   : () ),
    ( $arg{scope} ? ( scope => $arg{scope} ) : () )
  };
}

####  transport

sub request {
  my ( $self, $request ) = @_;
  my $uri    = URI->new( $request->uri );
  my $path   = $uri->path;
  my $method = $request->method;
  my $body   = length( $request->content // '' ) ? eval { $JSON->decode( $request->content ) } : undef;
  push @{ $self->{requests} }, [ $method, $path.( $uri->query ? '?'.$uri->query : '' ), $body ];
  $self->{writes}++ if $method ne 'GET' && $method ne 'HEAD';
  my %query = $uri->query_form;
  my $response = eval {
    return $self->_api( $request, $method, $path, \%query, $body ) if $path =~ m{\A/api/v3/};
    return $self->_oidc( $request, $method, $path, \%query ) if $path =~ m{\A/application/o/};
    return $self->_json( 404, { detail => 'Not found.' } );
  };
  return $response if $response;
  return $self->_json( 500, { detail => 'the fake authentik broke: '.$@ } );
}

sub _json {
  my ( $self, $status, $data, @header ) = @_;
  my $response = HTTP::Response->new( $status, 'Status '.$status, [ 'Content-Type' => 'application/json; charset=utf-8', @header ] );
  $response->content( defined $data ? $JSON->encode($data) : '' );
  return $response;
}

sub _empty {
  my ( $self, $status, @header ) = @_;
  my $response = HTTP::Response->new( $status, 'Status '.$status, [@header] );
  $response->content('');
  return $response;
}

sub _raw {
  my ( $self, $status, $content, $type ) = @_;
  my $response = HTTP::Response->new( $status, 'Status '.$status, [ 'Content-Type' => $type ] );
  $response->content($content);
  return $response;
}

sub _missing { my ( $self, $model ) = @_; $self->_json( 404, { detail => 'No '.$model.' matches the given query.' } ) }

####  the API

sub _api {
  my ( $self, $request, $method, $path, $query, $body ) = @_;
  my $auth = $request->header('Authorization') // '';
  return $self->_json( 403, { detail => 'Authentication credentials were not provided.' } ) unless length $auth;
  my ( $bearer ) = $auth =~ /\ABearer (.+)\z/;
  return $self->_json( 403, { detail => 'Token invalid/expired' } )
    unless defined $bearer && $bearer eq $self->{token};
  return $self->_json( 400, { detail => 'JSON parse error - Input data was truncated' } )
    if length( $request->content // '' ) && !defined $body && $method ne 'DELETE';
  return $self->_json( 404, { detail => 'Not found.' } ) unless $path =~ m{/\z};

  return $self->_json( 200, { version_current => '2026.8.3', version_latest => '2026.8.3', outdated => \0 } )
    if $path eq '/api/v3/admin/version/';
  return $self->_json( 200, { default_token_duration => 'days=1', default_token_length => 60 } )
    if $path eq '/api/v3/admin/settings/';
  return $self->_json( 200, { capabilities => [], cache_timeout => 300 } )
    if $path eq '/api/v3/root/config/';
  return $self->_json( 200, { user => $self->{data}{users}{1} } )
    if $path eq '/api/v3/core/users/me/';

  if ( $path eq '/api/v3/core/users/service_account/' && $method eq 'POST' ) {
    my $user = $self->add( users => { username => $body->{name}, name => $body->{name}, type => 'service_account',
      path => 'goauthentik.io/service-accounts' } );
    my $key = 'svc-token-'.$user->{pk};
    $self->add( tokens => { identifier => 'service-account-'.$body->{name}.'-password', intent => 'app_password',
      user => $user->{pk}, _key => $key } );
    return $self->_json( 200, { username => $user->{username}, user_pk => $user->{pk}, user_uid => 'uid-'.$user->{pk}, token => $key } );
  }
  if ( $path =~ m{\A/api/v3/core/users/([^/]+)/set_password/\z} && $method eq 'POST' ) {
    return $self->_missing('User') unless $self->{data}{users}{$1};
    $self->{passwords}{$1} = $body->{password};
    return $self->_empty(204);
  }
  if ( $path =~ m{\A/api/v3/core/groups/([^/]+)/(add_user|remove_user)/\z} && $method eq 'POST' ) {
    my $group = $self->{data}{groups}{$1} or return $self->_missing('Group');
    my @users = grep { $_ ne $body->{pk} } @{ $group->{users} || [] };
    push @users, $body->{pk} if $2 eq 'add_user';
    $group->{users} = \@users;
    return $self->_empty(204);
  }
  if ( $path =~ m{\A/api/v3/core/tokens/([^/]+)/(view_key|set_key)/\z} ) {
    my ( $token ) = grep { $_->{identifier} eq $1 } values %{ $self->{data}{tokens} };
    return $self->_missing('Token') unless $token;
    return $self->_json( 200, { key => $token->{_key} // 'generated-key-'.$token->{identifier} } ) if $2 eq 'view_key';
    $token->{_key} = $body->{key};
    return $self->_empty(204);
  }
  if ( $path =~ m{\A/api/v3/core/applications/([^/]+)/check_access/\z} ) {
    my ( $app ) = grep { $_->{slug} eq $1 } values %{ $self->{data}{applications} };
    return $self->_missing('Application') unless $app;
    return $self->_json( 200, { passing => \1, messages => [], log_messages => [] } );
  }
  if ( $path =~ m{\A/api/v3/providers/oauth2/([^/]+)/setup_urls/\z} ) {
    my $provider = $self->{data}{providers}{$1} or return $self->_missing('OAuth2Provider');
    my ( $app ) = grep { ( $_->{provider} // '' ) eq $provider->{pk} } values %{ $self->{data}{applications} };
    my $slug = $app && $app->{slug};
    return $self->_json( 200, {
      issuer        => $slug ? $self->issuer_for($slug) : undef,
      authorize     => $self->{base}.'/application/o/authorize/',
      token         => $self->{base}.'/application/o/token/',
      user_info     => $self->{base}.'/application/o/userinfo/',
      provider_info => $slug ? $self->issuer_for($slug).'.well-known/openid-configuration' : undef,
      logout        => $slug ? $self->issuer_for($slug).'end-session/' : undef
    } );
  }
  if ( $path =~ m{\A/api/v3/providers/oauth2/([^/]+)/preview_user/\z} ) {
    my $provider = $self->{data}{providers}{$1} or return $self->_missing('OAuth2Provider');
    return $self->_json( 200, { preview => $self->claims_for } );
  }
  if ( $path =~ m{\A/api/v3/propertymappings/all/([^/]+)/test/\z} && $method eq 'POST' ) {
    return $self->_missing('PropertyMapping') unless $self->{data}{mappings}{$1};
    return $self->_json( 200, { result => '{}', successful => \1 } );
  }
  if ( $path =~ m{\A/api/v3/flows/instances/([^/]+)/export/\z} ) {
    my ( $flow ) = grep { $_->{slug} eq $1 } values %{ $self->{data}{flows} };
    return $self->_missing('Flow') unless $flow;
    return $self->_raw( 200, "version: 1\nentries:\n- model: authentik_flows.flow\n  attrs:\n    slug: ".$flow->{slug}."\n", 'text/html; charset=utf-8' );
  }
  if ( $path =~ m{\A/api/v3/managed/blueprints/([^/]+)/apply/\z} && $method eq 'POST' ) {
    my $blueprint = $self->{data}{blueprints}{$1} or return $self->_missing('BlueprintInstance');
    $blueprint->{status}       = 'successful';
    $blueprint->{last_applied} = 'applied';
    return $self->_json( 200, $blueprint );
  }
  if ( $path eq '/api/v3/stages/all/types/' ) {
    return $self->_json( 200, [
      { name => 'Password Stage', component => 'ak-stage-password-form', model_name => 'passwordstage' },
      { name => 'Authenticator Validation Stage', component => 'ak-stage-authenticator-validate-form', model_name => 'authenticatorvalidatestage' }
    ] );
  }
  if ( $path eq '/api/v3/authenticators/admin/all/' ) {
    return $self->_json( 200, [] );
  }
  if ( $path eq '/api/v3/core/brands/current/' ) {
    my ( $brand ) = grep { $_->{default} } values %{ $self->{data}{brands} };
    # the public view: no brand_uuid and no domain, so it cannot be written back
    return $self->_json( 200, { map { $_ => $brand->{$_} }
      grep { !/\A(brand_uuid|domain|default|attributes)\z/ } keys %$brand } );
  }
  return $self->_json( 405, { detail => 'Method "'.$method.'" not allowed.' } )
    if $path =~ m{\A/api/v3/stages/all/[^/]+/\z} && $method ne 'GET';

  # the stage collection lives under one path per type
  if ( $path =~ m{\A/api/v3/stages/(.+?)/?\z} ) {
    my $rest = $1;
    my ( $type, $id );
    if ( $rest eq 'all' ) { $type = undef }
    elsif ( $rest =~ m{\A(all)/([^/]+)\z} ) { ( $type, $id ) = ( undef, $2 ) }
    elsif ( $rest =~ m{\A(.+)/([0-9a-f]{8}-[0-9a-f-]+)\z} ) { ( $type, $id ) = ( $1, $2 ) }
    else { $type = $rest }
    return $self->_stages( $method, $type, $id, $query, $body );
  }

  for my $name ( sort keys %COLLECTION ) {
    next if $name eq 'stages';
    my $spec = $COLLECTION{$name};
    next unless index( $path, $spec->{path} ) == 0;
    my $rest = substr $path, length $spec->{path};
    return $self->_collection( $name, $method, $query, $body ) unless length $rest;
    $rest =~ s{/\z}{};
    return $self->_detail( $name, $method, $rest, $body ) unless $rest =~ m{/};
  }
  return $self->_json( 404, { detail => 'Not found.' } );
}

sub _pk_field { $_[1] eq 'brands' ? 'brand_uuid' : 'pk' }

sub _collection {
  my ( $self, $name, $method, $query, $body ) = @_;
  my $spec = $COLLECTION{$name};
  return $self->_list( $name, [ values %{ $self->{data}{$name} } ], $query ) if $method eq 'GET';
  return $self->_json( 405, { detail => 'Method "'.$method.'" not allowed.' } ) unless $method eq 'POST';
  return $self->_create( $name, $body );
}

sub _create {
  my ( $self, $name, $body ) = @_;
  my $spec = $COLLECTION{$name};
  my %missing = map { $_ => ['This field is required.'] } grep { !defined $body->{$_} } @{ $spec->{required} };
  return $self->_json( 400, \%missing ) if %missing;
  if ( defined $spec->{key} && grep { ( $_->{ $spec->{key} } // '' ) eq $body->{ $spec->{key} } } values %{ $self->{data}{$name} } ) {
    return $self->_json( 400, { $spec->{key} => [ $spec->{duplicate} ] } );
  }
  if ( my $error = $self->_validate( $name, $body, {} ) ) { return $error }
  my $object = $self->add( $name, { %$body } );
  $self->_shape( $name, $object );
  return $self->_json( 201, $object );
}

sub _detail {
  my ( $self, $name, $method, $id, $body ) = @_;
  my $spec   = $COLLECTION{$name};
  my $field  = $spec->{detail};
  my ( $object ) = grep { defined $_->{$field} && $_->{$field} eq $id } values %{ $self->{data}{$name} };
  return $self->_missing( $spec->{model} ) unless $object;
  if ( $method eq 'GET' ) {
    $self->_shape( $name, $object );
    return $self->_json( 200, $object );
  }
  if ( $method eq 'DELETE' ) {
    delete $self->{data}{$name}{ $object->{ $self->_pk_field($name) } };
    return $self->_empty(204);
  }
  return $self->_json( 405, { detail => 'Method "'.$method.'" not allowed.' } ) unless $method eq 'PATCH' || $method eq 'PUT';
  my %write = %$body;
  delete @write{@READ_ONLY};
  if ( my $error = $self->_validate( $name, { %$object, %write }, $object ) ) { return $error }
  %$object = ( %$object, %write );
  $self->_shape( $name, $object );
  return $self->_json( 200, $object );
}

# the rules authentik enforces beyond "required" and "unique"
sub _validate {
  my ( $self, $name, $wanted, $current ) = @_;
  if ( $name eq 'providers' && $wanted->{grant_types} ) {
    my %known = map { $_ => 1 } qw( authorization_code implicit hybrid refresh_token client_credentials
      password urn:ietf:params:oauth:grant-type:device_code urn:ietf:params:oauth:grant-type:token-exchange );
    for my $i ( 0 .. $#{ $wanted->{grant_types} } ) {
      next if $known{ $wanted->{grant_types}[$i] };
      return $self->_json( 400, { grant_types => { $i => [ '"'.$wanted->{grant_types}[$i].'" is not a valid choice.' ] } } );
    }
  }
  if ( $name eq 'applications' && defined $wanted->{provider} ) {
    my ( $taken ) = grep { ( $_->{provider} // '' ) eq $wanted->{provider} && $_ != $current } values %{ $self->{data}{applications} };
    return $self->_json( 400, { provider => ['Application with this provider already exists.'] } ) if $taken;
  }
  if ( $name eq 'bindings' ) {
    my ( $taken ) = grep {
      $_ != $current && ( $_->{target} // '' ) eq ( $wanted->{target} // '' )
        && ( $_->{stage} // '' ) eq ( $wanted->{stage} // '' ) && ( $_->{order} // '' ) eq ( $wanted->{order} // '' )
    } values %{ $self->{data}{bindings} };
    return $self->_json( 400, { non_field_errors => ['The fields target, stage, order must make a unique set.'] } ) if $taken;
  }
  if ( $name eq 'stages' && ( $wanted->{not_configured_action} // '' ) eq 'configure'
    && !( $wanted->{configuration_stages} && @{ $wanted->{configuration_stages} } ) ) {
    return $self->_json( 400, { not_configured_action =>
      ['When "Not configured action" is set to "Configure", you must set a configuration stage.'] } );
  }
  return;
}

# what authentik fills in or reorders before it answers
sub _shape {
  my ( $self, $name, $object ) = @_;
  if ( $name eq 'providers' ) {
    $object->{client_id}     //= 'client-id-'.$object->{pk};
    $object->{client_secret} //= 'client-secret-'.$object->{pk};
    $object->{redirect_uris} = [ map { ref $_ eq 'HASH' ? { redirect_uri_type => 'authorization', %$_ } : $_ } @{ $object->{redirect_uris} || [] } ];
    # authentik hands property_mappings back in its own order
    $object->{property_mappings} = [ reverse @{ $object->{property_mappings} } ] if $object->{property_mappings};
    my ( $app ) = grep { ( $_->{provider} // '' ) eq $object->{pk} } values %{ $self->{data}{applications} };
    $object->{assigned_application_slug} = $app ? $app->{slug} : undef;
    $object->{component} = 'ak-provider-oauth2-form';
  }
  if ( $name eq 'users' ) {
    $object->{uid}  //= 'uid-'.$object->{pk};
    $object->{uuid} //= $self->_uuid;
  }
  if ( $name eq 'flows' ) {
    $object->{stages} = [ map { $_->{stage} }
      sort { ( $a->{order} // 0 ) <=> ( $b->{order} // 0 ) }
      grep { ( $_->{target} // '' ) eq $object->{pk} } values %{ $self->{data}{bindings} } ];
  }
  return;
}

sub _stages {
  my ( $self, $method, $type, $id, $query, $body ) = @_;
  my @all = values %{ $self->{data}{stages} };
  if ( !defined $id ) {
    if ( $method eq 'GET' ) {
      my @list = defined $type ? grep { ( $_->{_type} // '' ) eq $type } @all : @all;
      return $self->_list( 'stages', \@list, $query, defined $type ? 0 : 1 );
    }
    return $self->_json( 405, { detail => 'Method "'.$method.'" not allowed.' } ) unless $method eq 'POST';
    return $self->_json( 404, { detail => 'Not found.' } ) unless defined $type;
    my $response = $self->_create( stages => { %$body, _type => $type } );
    return $response;
  }
  my ( $stage ) = grep { $_->{pk} eq $id } @all;
  # a typed endpoint only knows the stages of its own type
  $stage = undef if $stage && defined $type && ( $stage->{_type} // '' ) ne $type;
  return $self->_missing( defined $type ? _stage_model($type) : 'Stage' ) unless $stage;
  return $self->_json( 200, defined $type ? $stage : { map { $_ => $stage->{$_} } grep { $_ ne '_type' } keys %$stage } )
    if $method eq 'GET';
  return $self->_detail( 'stages', $method, $id, $body );
}

# the model name authentik puts into a 404 of a typed stage endpoint
sub _stage_model {
  my ( $type ) = @_;
  my $name = join '', map { ucfirst } split /[\/_]/, $type;
  return $name.'Stage';
}

sub _list {
  my ( $self, $name, $items, $query, $reduced ) = @_;
  my $spec = $COLLECTION{$name};
  my %filter = %$query;
  my $page      = delete( $filter{page} )      || 1;
  my $page_size = delete( $filter{page_size} ) || 100;
  delete @filter{qw( ordering include_users include_groups for_user )};
  if ( defined( my $search = delete $filter{search} ) ) {
    $items = [ grep { defined $spec->{key} && index( $_->{ $spec->{key} } // '', $search ) >= 0 } @$items ];
  }
  for my $field ( keys %filter ) {
    $items = [ grep { defined $_->{$field} && !ref $_->{$field} && $_->{$field} eq $filter{$field} } @$items ];
  }
  $self->_shape( $name, $_ ) for @$items;
  my $pk_field = $self->_pk_field($name);
  my @sorted = sort { ( $a->{$pk_field} // '' ) cmp ( $b->{$pk_field} // '' ) } @$items;
  my $count  = scalar @sorted;
  my $pages  = $count ? int( ( $count + $page_size - 1 ) / $page_size ) : 1;
  return $self->_json( 404, { detail => 'Invalid page.' } ) if $page > $pages && $count;
  my $from = ( $page - 1 ) * $page_size;
  my @page = @sorted[ $from .. ( $from + $page_size - 1 < $#sorted ? $from + $page_size - 1 : $#sorted ) ];
  @page = () unless $count;
  my $next = $page < $pages ? $page + 1 : 0;
  # a broken answer whose next points backwards, for the loop guard
  $next = 1 if $self->{break_paging};
  # /stages/all/ answers with a reduced representation, without the typed fields
  my @results = $reduced
    ? map { my $s = $_; +{ map { ( $_ => $s->{$_} ) } grep { /\A(pk|name|component|verbose_name|meta_model_name)\z/ } keys %$s } } @page
    : @page;
  return $self->_json( 200, {
    pagination => { next => $next, previous => $page > 1 ? $page - 1 : 0, count => $count,
      current => $page, total_pages => $pages, start_index => $count ? $from + 1 : 0, end_index => $from + scalar @page },
    results => \@results
  } );
}

####  OIDC

sub _application_for {
  my ( $self, $slug ) = @_;
  my ( $app ) = grep { $_->{slug} eq $slug } values %{ $self->{data}{applications} };
  return unless $app && defined $app->{provider};
  return ( $app, $self->{data}{providers}{ $app->{provider} } );
}

sub _provider_by_client_id {
  my ( $self, $client_id ) = @_;
  my ( $provider ) = grep { ( $_->{client_id} // '' ) eq ( $client_id // '' ) } values %{ $self->{data}{providers} };
  return $provider;
}

sub _slug_of {
  my ( $self, $provider ) = @_;
  my ( $app ) = grep { ( $_->{provider} // '' ) eq $provider->{pk} } values %{ $self->{data}{applications} };
  return $app ? $app->{slug} : undef;
}

sub _oauth_error {
  my ( $self, $status, $code, $description ) = @_;
  return $self->_json( $status, { error => $code, error_description => $description, request_id => 'req-'.++$self->{seq} } );
}

sub _oidc {
  my ( $self, $request, $method, $path, $query ) = @_;
  my %form = URI->new( 'http:?'.( $request->content // '' ) )->query_form;

  if ( $path =~ m{\A/application/o/([^/]+)/\.well-known/openid-configuration\z} ) {
    my ( $app, $provider ) = $self->_application_for($1);
    return $self->_empty(404) unless $provider;
    my $issuer = $provider->{issuer_mode} && $provider->{issuer_mode} eq 'global' ? $self->{base}.'/' : $self->issuer_for($1);
    return $self->_json( 200, {
      issuer                        => $issuer,
      authorization_endpoint        => $self->{base}.'/application/o/authorize/',
      token_endpoint                => $self->{base}.'/application/o/token/',
      userinfo_endpoint             => $self->{base}.'/application/o/userinfo/',
      introspection_endpoint        => $self->{base}.'/application/o/introspect/',
      revocation_endpoint           => $self->{base}.'/application/o/revoke/',
      end_session_endpoint          => $self->issuer_for($1).'end-session/',
      device_authorization_endpoint => $self->{base}.'/application/o/device/',
      jwks_uri                      => $self->issuer_for($1).'jwks/',
      grant_types_supported         => $provider->{grant_types},
      response_types_supported      => ['code'],
      id_token_signing_alg_values_supported => ['RS256'],
      subject_types_supported       => ['public'],
      scopes_supported              => [qw( openid email profile offline_access )],
      acr_values_supported          => ['goauthentik.io/providers/oauth2/default'],
      claims_supported              => [qw( sub iss aud exp iat auth_time acr amr nonce email preferred_username )],
      code_challenge_methods_supported => [qw( plain S256 )]
    } );
  }
  if ( $path =~ m{\A/application/o/([^/]+)/jwks/\z} ) {
    my ( $app, $provider ) = $self->_application_for($1);
    return $self->_empty(404) unless $provider;
    return $self->_json( 200, { keys => [ { %{ $self->public_key }, kid => $self->{kid}, use => 'sig', alg => 'RS256' } ] } );
  }
  return $self->_token( $request, \%form ) if $path eq '/application/o/token/';
  return $self->_device( $request, \%form ) if $path eq '/application/o/device/';

  if ( $path eq '/application/o/userinfo/' ) {
    my $bearer = ( $request->header('Authorization') // '' ) =~ /\ABearer (.+)\z/ ? $1 : $form{access_token};
    my $token  = defined $bearer ? $self->{oauth}{access}{$bearer} : undef;
    return $self->_empty( 401, 'WWW-Authenticate' => 'error="invalid_token", error_description="The access token provided is expired, revoked, malformed, or invalid for other reasons"' )
      unless $token && !$token->{revoked};
    return $self->_json( 200, { sub => $token->{claims}{sub}, preferred_username => $token->{claims}{preferred_username},
      email => 'probe@example.org', groups => [] } );
  }
  if ( $path eq '/application/o/introspect/' || $path eq '/application/o/revoke/' ) {
    my ( $id, $secret ) = $self->_client_auth( $request, \%form );
    my $provider = $self->_provider_by_client_id($id);
    return $self->_oauth_error( 401, 'invalid_client', 'Client authentication failed (e.g., unknown client, no client authentication included, or unsupported authentication method)' )
      unless $provider && ( $provider->{client_secret} // '' ) eq ( $secret // '' );
    my $entry = $self->{oauth}{access}{ $form{token} // '' } || $self->{oauth}{refresh}{ $form{token} // '' };
    if ( $path eq '/application/o/revoke/' ) {
      $entry->{revoked} = 1 if $entry;
      return $self->_json( 200, {} );
    }
    return $self->_json( 200, { active => \0 } ) unless $entry && !$entry->{revoked};
    return $self->_json( 200, { %{ $entry->{claims} }, active => \1, scope => $entry->{scope}, client_id => $id } );
  }
  return $self->_empty(404);
}

sub _client_auth {
  my ( $self, $request, $form ) = @_;
  my $auth = $request->header('Authorization') // '';
  if ( $auth =~ /\ABasic (.+)\z/ ) {
    require MIME::Base64;
    my ( $id, $secret ) = split /:/, MIME::Base64::decode_base64($1), 2;
    return ( $id, $secret );
  }
  return ( $form->{client_id}, $form->{client_secret} );
}

sub _issue {
  my ( $self, %arg ) = @_;
  my $claims = $self->claims_for(
    slug     => $arg{slug},
    iss      => $arg{iss},
    aud      => $arg{client_id},
    sub      => $arg{sub} // 'fake-subject',
    username => $arg{username},
    amr      => $arg{amr},
    scope    => $arg{scope}
  );
  my $access = $self->sign( { %$claims, azp => $arg{client_id} } );
  my $id     = $self->sign( { map { $_ => $claims->{$_} } grep { $_ ne 'scope' } keys %$claims } );
  my $refresh = 'refresh-'.++$self->{seq};
  $self->{oauth}{access}{$access}   = { claims => $claims, scope => $arg{scope}, provider => $arg{client_id} };
  $self->{oauth}{refresh}{$refresh} = { claims => $claims, scope => $arg{scope}, provider => $arg{client_id} };
  return { access_token => $access, id_token => $id, refresh_token => $refresh, token_type => 'Bearer',
    expires_in => $self->{expires_in}, scope => $arg{scope} };
}

sub _token {
  my ( $self, $request, $form ) = @_;
  my ( $id, $secret ) = $self->_client_auth( $request, $form );
  my $provider = $self->_provider_by_client_id($id);
  return $self->_oauth_error( 400, 'invalid_client', 'Client authentication failed (e.g., unknown client, no client authentication included, or unsupported authentication method)' )
    unless $provider;
  my $grant = $form->{grant_type} // '';
  my %allowed = map { $_ => 1 } @{ $provider->{grant_types} || [] };
  return $self->_oauth_error( 400, 'unsupported_grant_type', 'The authorization grant type is not supported by the authorization server' )
    unless grep { $_ eq $grant } qw( authorization_code refresh_token client_credentials password urn:ietf:params:oauth:grant-type:device_code );
  my $bad = sub { $self->_oauth_error( 400, 'invalid_grant', 'The provided authorization grant or refresh token is invalid, expired, revoked, does not match the redirection URI used in the authorization request, or was issued to another client' ) };
  return $bad->() unless $allowed{$grant};
  my $slug = $self->_slug_of($provider);
  # issuer_mode decides what goes into iss, in the token as in the discovery
  my $iss = ( $provider->{issuer_mode} // 'per_provider' ) eq 'global'
    ? $self->{base}.'/' : $self->issuer_for( $slug // 'probe-app' );

  if ( $grant eq 'client_credentials' || $grant eq 'password' ) {
    if ( defined $form->{username} ) {
      my ( $token ) = grep { ( $_->{_key} // '' ) eq ( $form->{password} // '' ) } values %{ $self->{data}{tokens} };
      return $bad->() unless $token;
      return $self->_json( 200, $self->_issue( slug => $slug, iss => $iss, client_id => $id, username => $form->{username},
        sub => 'sub-'.$form->{username}, scope => $form->{scope} // 'openid' ) );
    }
    return $bad->() unless ( $provider->{client_secret} // '' ) eq ( $secret // '' );
    return $self->_json( 200, $self->_issue( slug => $slug, iss => $iss, client_id => $id,
      username => 'ak-'.$provider->{name}.'-client_credentials', sub => 'sub-service-account',
      scope => $form->{scope} // 'openid' ) );
  }
  return $bad->() unless ( $provider->{client_secret} // '' ) eq ( $secret // '' );

  if ( $grant eq 'authorization_code' ) {
    my $code = delete $self->{oauth}{codes}{ $form->{code} // '' } or return $bad->();
    return $self->_json( 200, $self->_issue( slug => $slug, iss => $iss, client_id => $id, %$code ) );
  }
  if ( $grant eq 'refresh_token' ) {
    my $entry = delete $self->{oauth}{refresh}{ $form->{refresh_token} // '' };
    return $bad->() unless $entry && !$entry->{revoked};
    return $self->_oauth_error( 400, 'invalid_scope', 'The requested scope is invalid, unknown, malformed, or exceeds the scope granted by the resource owner' )
      if defined $form->{scope} && $form->{scope} ne ( $entry->{scope} // '' );
    return $self->_json( 200, $self->_issue( slug => $slug, iss => $iss, client_id => $id, scope => $entry->{scope},
      sub => $entry->{claims}{sub}, username => $entry->{claims}{preferred_username}, amr => $entry->{claims}{amr} ) );
  }
  my $device = $self->{oauth}{devices}{ $form->{device_code} // '' } or return $bad->();
  return $self->_oauth_error( 400, 'authorization_pending', "The authorization request is still pending as the end user hasn't yet completed the user-interaction steps" )
    unless $device->{approved};
  delete $self->{oauth}{devices}{ $form->{device_code} };
  return $self->_json( 200, $self->_issue( slug => $slug, iss => $iss, client_id => $id, scope => $device->{scope},
    username => 'probe-alice', sub => 'sub-probe-alice', amr => ['pwd'] ) );
}

sub _device {
  my ( $self, $request, $form ) = @_;
  my $provider = $self->_provider_by_client_id( $form->{client_id} );
  return $self->_oauth_error( 400, 'invalid_client', 'Client authentication failed (e.g., unknown client, no client authentication included, or unsupported authentication method)' )
    unless $provider;
  my $n    = ++$self->{seq};
  my $code = 'device-code-'.$n.'-with"quotes"&specials';
  my $user = sprintf '%09d', $n;
  $self->{oauth}{devices}{$code} = { user_code => $user, scope => $form->{scope}, approved => 0 };
  return $self->_json( 200, { device_code => $code, user_code => $user,
    verification_uri => $self->{base}.'/device',
    verification_uri_complete => $self->{base}.'/device?code='.$user,
    expires_in => 60, interval => 5 } );
}

# what a user approving the device flow in a browser does
sub approve_device {
  my ( $self, $user_code ) = @_;
  for my $device ( values %{ $self->{oauth}{devices} } ) {
    next unless $device->{user_code} eq $user_code;
    $device->{approved} = 1;
    return 1;
  }
  return 0;
}

# what the authorization endpoint hands back after a login
sub issue_code {
  my ( $self, %arg ) = @_;
  my $code = 'code-'.++$self->{seq};
  $self->{oauth}{codes}{$code} = { scope => $arg{scope} // 'openid', username => $arg{username} // 'probe-alice',
    sub => $arg{sub} // 'sub-probe-alice', amr => $arg{amr} // ['pwd'] };
  return $code;
}

1;
