package WWW::Authentik::API;

# ABSTRACT: authentik REST API v3 with idempotent ensure methods

use Moo;
with 'WWW::Authentik::Role::HTTP';
use Scalar::Util qw( blessed );
use Types::Standard qw( InstanceOf Int Str );
use URI::Escape qw( uri_escape_utf8 );
use WWW::Authentik::Diff;
use WWW::Authentik::Error;
use WWW::Authentik::Error::Validation;
use namespace::autoclean;

our $VERSION = '0.001';


has base_url => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has token => (
  is       => 'ro',
  isa      => Str,
  required => 1
);


has ua => (
  is       => 'ro',
  isa      => InstanceOf['LWP::UserAgent'],
  required => 1
);


has page_size => (
  is      => 'ro',
  isa     => Int,
  default => 100
);


# what counts as an identifier rather than a readable name, per field; see
# resolvable_fields below. Named methods, not lexicals, so that
# Net::Async::Authentik asks the same two questions instead of writing the
# patterns out a second time.
my $UUID    = qr{\A[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\z};
my $INTEGER = qr{\A[0-9]+\z};

sub uuid_pattern    { $UUID }
sub integer_pattern { $INTEGER }


sub diff_class { 'WWW::Authentik::Diff' }


####  transport

sub api_url { $_[0]->base_url.'/api/v3' }


sub call {
  my ( $self, $method, $path, $body ) = @_;
  $path = '/'.$path unless $path =~ m{\A/};
  my %arg = defined $body ? ( json => $body ) : ();
  return $self->send_request( $method, $self->api_url.$path, %arg, bearer => $self->token );
}


sub _data { $_[0]->call( @_[ 1 .. $#_ ] )->{data} }
sub _done { $_[0]->call( @_[ 1 .. $#_ ] ); 1 }
sub _esc  { uri_escape_utf8( $_[1] ) }

sub _query {
  my ( $self, %query ) = @_;
  return '' unless %query;
  return '?'.join '&', map { $self->_esc($_).'='.$self->_esc( $query{$_} ) }
    grep { defined $query{$_} } sort keys %query;
}

sub _paged {
  my ( $self, $path, %query ) = @_;
  my $page_size = delete $query{page_size} // $self->page_size;
  my ( @all, %seen );
  my $page = 1;
  # a broken answer whose next points at a page already fetched would loop
  # for ever; %seen is the floor under that
  while ( defined $page && $page > 0 && !$seen{$page}++ ) {
    my $data = $self->_data( GET => $path.$self->_query( %query, page => $page, page_size => $page_size ) );
    last unless ref $data eq 'HASH';
    push @all, @{ $data->{results} || [] };
    $page = ref $data->{pagination} eq 'HASH' ? $data->{pagination}{next} : 0;
  }
  return \@all;
}

sub _missing {
  my ( $self, $error ) = @_;
  return 1 if blessed $error && $error->isa('WWW::Authentik::Error::API') && $error->is_not_found;
  die $error;
}

sub _find_one {
  my ( $self, $list, $key, $value ) = @_;
  my ( $found ) = grep { defined $_->{$key} && $_->{$key} eq $value } @$list;
  return $found;
}

# a finder called with nothing would otherwise fetch every object and compare
# each one against undef, warning once per row and finding nothing
sub _need {
  my ( $self, $what, $value ) = @_;
  WWW::Authentik::Error::Validation->throw( message => $what.' is needed' )
    unless defined $value && length $value;
  return $value;
}

sub _detail {
  my ( $self, $path ) = @_;
  my $object = eval { $self->_data( GET => $path ) };
  return $object if $object;
  $self->_missing($@);
  return;
}

####  instance

sub version  { $_[0]->_data( GET => '/admin/version/' ) }
sub config   { $_[0]->_data( GET => '/root/config/' ) }
sub settings { $_[0]->_data( GET => '/admin/settings/' ) }
sub me       { $_[0]->_data( GET => '/core/users/me/' ) }


####  users

sub list_users  { my ( $self, %q ) = @_; $self->_paged( '/core/users/', %q ) }
sub get_user    { $_[0]->_data( GET => '/core/users/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_user { $_[0]->_data( POST => '/core/users/', $_[1] ) }
sub update_user { $_[0]->_data( PATCH => '/core/users/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_user { $_[0]->_done( DELETE => '/core/users/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_user {
  my ( $self, $username ) = @_;
  $self->_need( 'find_user: a username', $username );
  return $self->_find_one( $self->list_users( username => $username ), 'username', $username );
}

sub set_password {
  my ( $self, $pk, $password ) = @_;
  return $self->_done( POST => '/core/users/'.$self->_esc($pk).'/set_password/', { password => $password } );
}

sub create_service_account {
  my ( $self, %arg ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'create_service_account needs a name' ) unless defined $arg{name};
  return $self->_data( POST => '/core/users/service_account/',
    { name => $arg{name}, create_group => $arg{create_group} ? \1 : \0,
      exists $arg{expiring} ? ( expiring => $arg{expiring} ) : () } );
}

sub list_authenticators {
  my ( $self, $pk ) = @_;
  return $self->_data( GET => '/authenticators/admin/all/'.$self->_query( user => $pk ) );
}


####  groups

sub list_groups  { my ( $self, %q ) = @_; $self->_paged( '/core/groups/', %q ) }
sub get_group    { $_[0]->_data( GET => '/core/groups/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_group { $_[0]->_data( POST => '/core/groups/', $_[1] ) }
sub update_group { $_[0]->_data( PATCH => '/core/groups/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_group { $_[0]->_done( DELETE => '/core/groups/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_group {
  my ( $self, $name ) = @_;
  $self->_need( 'find_group: a name', $name );
  return $self->_find_one( $self->list_groups( name => $name ), 'name', $name );
}

sub add_user_to_group {
  my ( $self, $uuid, $pk ) = @_;
  return $self->_done( POST => '/core/groups/'.$self->_esc($uuid).'/add_user/', { pk => $pk } );
}

sub remove_user_from_group {
  my ( $self, $uuid, $pk ) = @_;
  return $self->_done( POST => '/core/groups/'.$self->_esc($uuid).'/remove_user/', { pk => $pk } );
}


####  tokens

sub list_tokens  { my ( $self, %q ) = @_; $self->_paged( '/core/tokens/', %q ) }
sub get_token    { $_[0]->_data( GET => '/core/tokens/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_token { $_[0]->_data( POST => '/core/tokens/', $_[1] ) }
sub update_token { $_[0]->_data( PATCH => '/core/tokens/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_token { $_[0]->_done( DELETE => '/core/tokens/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_token {
  my ( $self, $identifier ) = @_;
  $self->_need( 'find_token: an identifier', $identifier );
  return $self->_detail( '/core/tokens/'.$self->_esc($identifier).'/' );
}

sub view_token_key { $_[0]->_data( GET => '/core/tokens/'.$_[0]->_esc( $_[1] ).'/view_key/' ) }

sub set_token_key {
  my ( $self, $identifier, $key ) = @_;
  return $self->_done( POST => '/core/tokens/'.$self->_esc($identifier).'/set_key/', { key => $key } );
}


####  applications

sub list_applications  { my ( $self, %q ) = @_; $self->_paged( '/core/applications/', %q ) }
sub create_application { $_[0]->_data( POST => '/core/applications/', $_[1] ) }
sub update_application { $_[0]->_data( PATCH => '/core/applications/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_application { $_[0]->_done( DELETE => '/core/applications/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_application {
  my ( $self, $slug ) = @_;
  $self->_need( 'find_application: a slug', $slug );
  return $self->_detail( '/core/applications/'.$self->_esc($slug).'/' );
}

sub check_access {
  my ( $self, $slug, %opt ) = @_;
  return $self->_data( GET => '/core/applications/'.$self->_esc($slug).'/check_access/'
    .$self->_query( defined $opt{for_user} ? ( for_user => $opt{for_user} ) : () ) );
}


####  oauth2 providers

sub list_oauth2_providers  { my ( $self, %q ) = @_; $self->_paged( '/providers/oauth2/', %q ) }
sub get_oauth2_provider    { $_[0]->_data( GET => '/providers/oauth2/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_oauth2_provider { $_[0]->_data( POST => '/providers/oauth2/', $_[1] ) }
sub update_oauth2_provider { $_[0]->_data( PATCH => '/providers/oauth2/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_oauth2_provider { $_[0]->_done( DELETE => '/providers/oauth2/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_oauth2_provider {
  my ( $self, $name ) = @_;
  $self->_need( 'find_oauth2_provider: a name', $name );
  return $self->_find_one( $self->list_oauth2_providers( name => $name ), 'name', $name );
}

sub provider_setup_urls { $_[0]->_data( GET => '/providers/oauth2/'.$_[0]->_esc( $_[1] ).'/setup_urls/' ) }

sub preview_user {
  my ( $self, $pk, $user_pk ) = @_;
  return $self->_data( GET => '/providers/oauth2/'.$self->_esc($pk).'/preview_user/'
    .$self->_query( defined $user_pk ? ( for_user => $user_pk ) : () ) );
}


####  scope mappings

sub list_scope_mappings  { my ( $self, %q ) = @_; $self->_paged( '/propertymappings/provider/scope/', %q ) }
sub get_scope_mapping    { $_[0]->_data( GET => '/propertymappings/provider/scope/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_scope_mapping { $_[0]->_data( POST => '/propertymappings/provider/scope/', $_[1] ) }
sub update_scope_mapping { $_[0]->_data( PATCH => '/propertymappings/provider/scope/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_scope_mapping { $_[0]->_done( DELETE => '/propertymappings/provider/scope/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_scope_mapping {
  my ( $self, $name ) = @_;
  $self->_need( 'find_scope_mapping: a name', $name );
  return $self->_find_one( $self->list_scope_mappings( name => $name ), 'name', $name );
}

sub find_scope_mappings_by_scope {
  my ( $self, @scopes ) = @_;
  my @found;
  for my $scope (@scopes) {
    my ( $mapping ) = @{ $self->list_scope_mappings( scope_name => $scope ) };
    WWW::Authentik::Error::Validation->throw( message => 'no scope mapping for the scope "'.$scope.'"' )
      unless $mapping;
    push @found, $mapping;
  }
  return \@found;
}

sub test_property_mapping {
  my ( $self, $uuid, %arg ) = @_;
  return $self->_data( POST => '/propertymappings/all/'.$self->_esc($uuid).'/test/', { %arg } );
}


####  flows

sub list_flows  { my ( $self, %q ) = @_; $self->_paged( '/flows/instances/', %q ) }
sub create_flow { $_[0]->_data( POST => '/flows/instances/', $_[1] ) }
sub update_flow { $_[0]->_data( PATCH => '/flows/instances/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_flow { $_[0]->_done( DELETE => '/flows/instances/'.$_[0]->_esc( $_[1] ).'/' ) }

sub find_flow {
  my ( $self, $slug ) = @_;
  $self->_need( 'find_flow: a slug', $slug );
  return $self->_detail( '/flows/instances/'.$self->_esc($slug).'/' );
}

sub export_flow {
  my ( $self, $slug ) = @_;
  return $self->call( GET => '/flows/instances/'.$self->_esc($slug).'/export/' )->{content};
}


####  stages

sub stage_types { $_[0]->_data( GET => '/stages/all/types/' ) }
sub list_stages { my ( $self, %q ) = @_; $self->_paged( '/stages/all/', %q ) }

sub find_stage {
  my ( $self, $name ) = @_;
  $self->_need( 'find_stage: a name', $name );
  return $self->_find_one( $self->list_stages( name => $name ), 'name', $name );
}

sub _stage_path {
  my ( $self, $type ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'a stage type is needed, for example password or authenticator/validate' )
    unless defined $type && length $type;
  WWW::Authentik::Error::Validation->throw( message => '/stages/all/ can only be read: name the stage type, for example password' )
    if $type eq 'all';
  $type =~ s{\A/}{};
  $type =~ s{/\z}{};
  return '/stages/'.$type.'/';
}

sub get_stage    { my ( $self, $type, $uuid ) = @_; $self->_data( GET => $self->_stage_path($type).$self->_esc($uuid).'/' ) }
sub create_stage { my ( $self, $type, $rep ) = @_; $self->_data( POST => $self->_stage_path($type), $rep ) }
sub update_stage { my ( $self, $type, $uuid, $rep ) = @_; $self->_data( PATCH => $self->_stage_path($type).$self->_esc($uuid).'/', $rep ) }
sub delete_stage { my ( $self, $type, $uuid ) = @_; $self->_done( DELETE => $self->_stage_path($type).$self->_esc($uuid).'/' ) }


####  flow stage bindings

sub list_bindings {
  my ( $self, %q ) = @_;
  # authentik wants the flow's UUID in target and answers a slug with a field
  # error, so flow => $slug is the readable way in
  $q{target} = $self->_flow_pk( delete $q{flow} ) if defined $q{flow};
  return $self->_paged( '/flows/bindings/', %q );
}

sub _flow_pk {
  my ( $self, $flow ) = @_;
  return $flow if $flow =~ $UUID;
  my $found = $self->find_flow($flow)
    or WWW::Authentik::Error::Validation->throw( message => 'no flow "'.$flow.'"' );
  return $found->{pk};
}
sub get_binding    { $_[0]->_data( GET => '/flows/bindings/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_binding { $_[0]->_data( POST => '/flows/bindings/', $_[1] ) }
sub update_binding { $_[0]->_data( PATCH => '/flows/bindings/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }
sub delete_binding { $_[0]->_done( DELETE => '/flows/bindings/'.$_[0]->_esc( $_[1] ).'/' ) }


####  brands, certificates, blueprints

sub list_brands   { my ( $self, %q ) = @_; $self->_paged( '/core/brands/', %q ) }
sub current_brand { $_[0]->_data( GET => '/core/brands/current/' ) }
sub update_brand  { $_[0]->_data( PATCH => '/core/brands/'.$_[0]->_esc( $_[1] ).'/', $_[2] ) }

sub list_certificates { my ( $self, %q ) = @_; $self->_paged( '/crypto/certificatekeypairs/', %q ) }

sub find_certificate {
  my ( $self, $name ) = @_;
  $self->_need( 'find_certificate: a name', $name );
  return $self->_find_one( $self->list_certificates( name => $name ), 'name', $name );
}

sub list_blueprints  { my ( $self, %q ) = @_; $self->_paged( '/managed/blueprints/', %q ) }
sub get_blueprint    { $_[0]->_data( GET => '/managed/blueprints/'.$_[0]->_esc( $_[1] ).'/' ) }
sub create_blueprint { $_[0]->_data( POST => '/managed/blueprints/', $_[1] ) }
sub apply_blueprint  { $_[0]->_data( POST => '/managed/blueprints/'.$_[0]->_esc( $_[1] ).'/apply/', {} ) }
sub delete_blueprint { $_[0]->_done( DELETE => '/managed/blueprints/'.$_[0]->_esc( $_[1] ).'/' ) }


####  resolve

sub resolvable_fields {
  return {
    provider            => { force => 'provider_name',            raw => $INTEGER, find => 'find_oauth2_provider', what => 'oauth2 provider' },
    authorization_flow  => { force => 'authorization_flow_slug',  raw => $UUID,    find => 'find_flow',            what => 'flow' },
    invalidation_flow   => { force => 'invalidation_flow_slug',   raw => $UUID,    find => 'find_flow',            what => 'flow' },
    authentication_flow => { force => 'authentication_flow_slug', raw => $UUID,    find => 'find_flow',            what => 'flow' },
    configure_flow      => { force => 'configure_flow_slug',      raw => $UUID,    find => 'find_flow',            what => 'flow' },
    flow_device_code    => { force => 'flow_device_code_slug',    raw => $UUID,    find => 'find_flow',            what => 'flow' },
    signing_key         => { force => 'signing_key_name',         raw => $UUID,    find => 'find_certificate',     what => 'certificate' },
    encryption_key      => { force => 'encryption_key_name',      raw => $UUID,    find => 'find_certificate',     what => 'certificate' },
    user                => { force => 'user_name',                raw => $INTEGER, find => 'find_user',            what => 'user' },
    groups              => { force => 'group_names',              raw => $UUID,    find => 'find_group',           what => 'group', list => 1 },
    property_mappings   => { force => 'property_mapping_names',   raw => $UUID,    find => 'find_scope_mapping',   what => 'scope mapping', list => 1 },
    configuration_stages => { force => 'configuration_stage_names', raw => $UUID,  find => 'find_stage',           what => 'stage', list => 1 }
  };
}

sub resolve {
  my ( $self, $rep ) = @_;
  my %out    = %$rep;
  my $fields = $self->resolvable_fields;
  if ( exists $out{scopes} ) {
    WWW::Authentik::Error::Validation->throw( message => 'give either scopes or property_mappings, not both' )
      if exists $out{property_mappings} || exists $out{property_mapping_names};
    my $scopes = delete $out{scopes};
    # an undef here is a mistake in the caller, and a costly one: taking it
    # for an empty list would strip every mapping off the provider
    WWW::Authentik::Error::Validation->throw( message => 'scopes is undef: give a list of scope names, '
      .'or an empty list to take every mapping away' )
      unless defined $scopes;
    WWW::Authentik::Error::Validation->throw( message => 'scopes takes a list of scope names' )
      unless ref $scopes eq 'ARRAY';
    $out{property_mappings} = [ map { $_->{pk} } @{ $self->find_scope_mappings_by_scope(@$scopes) } ];
  }
  for my $field ( sort keys %$fields ) {
    my $spec   = $fields->{$field};
    my $forced = exists $out{ $spec->{force} };
    WWW::Authentik::Error::Validation->throw( message => 'give either '.$field.' or '.$spec->{force}.', not both' )
      if $forced && exists $out{$field};
    next unless $forced || exists $out{$field};
    my $value = $forced ? delete $out{ $spec->{force} } : $out{$field};
    # the forced form says "look this name up", so an undef there is a
    # mistake, not a wish to leave the field alone
    WWW::Authentik::Error::Validation->throw( message => $spec->{force}.' is undef: give a name to look up, '
      .'or '.$field.' to set the identifier itself' )
      if $forced && !defined $value;
    next unless defined $value;
    $out{$field} = $spec->{list}
      ? [ map { $self->_resolve_one( $field, $spec, $_, $forced ) } @{ ref $value eq 'ARRAY' ? $value : [$value] } ]
      : $self->_resolve_one( $field, $spec, $value, $forced );
  }
  return \%out;
}

sub _resolve_one {
  my ( $self, $field, $spec, $value, $forced ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'cannot set '.$field.': expected '.$spec->{what}
    .' as a name or an identifier, got a '.lc( ref $value ).' reference' )
    if ref $value;
  return $value if !$forced && $value =~ $spec->{raw};
  my $find  = $spec->{find};
  my $found = $self->$find($value);
  WWW::Authentik::Error::Validation->throw( message => 'cannot set '.$field.': no '.$spec->{what}.' named "'.$value.'"' )
    unless $found;
  return $found->{pk};
}


####  ensure

sub _ensure {
  my ( $self, %arg ) = @_;
  my $current = $arg{find}->();
  unless ($current) {
    my $object = $arg{create}->();
    $arg{after_create}->($object) if $arg{after_create};
    return { object => $object, changed => 'created' };
  }
  my $changes = $self->diff_class->changes( $current, $arg{wanted} );
  return { object => $current, changed => '' } unless %$changes;
  return { object => $arg{update}->( $current, $changes ), changed => 'updated' };
}

sub ensure_user {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_user needs a username' ) unless defined $rep{username};
  my $wanted   = $self->resolve( \%rep );
  my $password = delete $wanted->{password};
  return $self->_ensure(
    wanted => $wanted,
    find   => sub { $self->find_user( $rep{username} ) },
    create => sub { $self->create_user($wanted) },
    # a password is set when the user is created and never again, so running a
    # setup twice does not reset it; call set_password to change one
    after_create => sub { $self->set_password( $_[0]{pk}, $password ) if defined $password },
    update => sub { $self->update_user( $_[0]{pk}, $_[1] ) }
  );
}

sub ensure_group {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_group needs a name' ) unless defined $rep{name};
  my $wanted = $self->resolve( \%rep );
  return $self->_ensure(
    wanted => $wanted,
    find   => sub { $self->find_group( $rep{name} ) },
    create => sub { $self->create_group($wanted) },
    update => sub { $self->update_group( $_[0]{pk}, $_[1] ) }
  );
}

sub ensure_token {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_token needs an identifier' ) unless defined $rep{identifier};
  # authentik ignores expires and sets it from default_token_duration, so a
  # wanted value could never be reached and would report updated for ever
  WWW::Authentik::Error::Validation->throw( message => 'ensure_token cannot set expires: authentik ignores it and '
    .'sets the expiry from the instance setting default_token_duration. Use expiring to say whether it expires at all.' )
    if exists $rep{expires};
  my $wanted = $self->resolve( \%rep );
  my $key    = delete $wanted->{key};
  return $self->_ensure(
    wanted => $wanted,
    find   => sub { $self->find_token( $rep{identifier} ) },
    create => sub { $self->create_token($wanted) },
    # like a password: the key is put on the token when it is created, never after
    after_create => sub { $self->set_token_key( $rep{identifier}, $key ) if defined $key },
    update => sub { $self->update_token( $rep{identifier}, $_[1] ) }
  );
}

sub ensure_application {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_application needs a slug' ) unless defined $rep{slug};
  my $wanted = $self->resolve( \%rep );
  return $self->_ensure(
    wanted => $wanted,
    find   => sub { $self->find_application( $rep{slug} ) },
    create => sub { $self->create_application($wanted) },
    update => sub { $self->update_application( $rep{slug}, $_[1] ) }
  );
}

sub ensure_oauth2_provider {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_oauth2_provider needs a name' ) unless defined $rep{name};
  my $wanted = $self->resolve( \%rep );
  return $self->_ensure(
    wanted => $wanted,
    find   => sub { $self->find_oauth2_provider( $rep{name} ) },
    create => sub {
      # authentik defaults grant_types to an empty list, and a provider with
      # an empty list answers every token request with invalid_grant. Which
      # grants were meant is not something this client guesses.
      WWW::Authentik::Error::Validation->throw( message => 'ensure_oauth2_provider needs grant_types to create a provider: '
        .'authentik would store an empty list, and such a provider answers every token request with invalid_grant' )
        unless ref $wanted->{grant_types} eq 'ARRAY' && @{ $wanted->{grant_types} };
      $self->create_oauth2_provider($wanted);
    },
    update => sub { $self->update_oauth2_provider( $_[0]{pk}, $_[1] ) }
  );
}

sub ensure_scope_mapping {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_scope_mapping needs a name' ) unless defined $rep{name};
  my $wanted = $self->resolve( \%rep );
  return $self->_ensure(
    wanted => $wanted,
    find   => sub { $self->find_scope_mapping( $rep{name} ) },
    create => sub { $self->create_scope_mapping($wanted) },
    update => sub { $self->update_scope_mapping( $_[0]{pk}, $_[1] ) }
  );
}

sub ensure_flow {
  my ( $self, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_flow needs a slug' ) unless defined $rep{slug};
  my $wanted = $self->resolve( \%rep );
  return $self->_ensure(
    wanted => $wanted,
    find   => sub { $self->find_flow( $rep{slug} ) },
    create => sub { $self->create_flow($wanted) },
    update => sub { $self->update_flow( $rep{slug}, $_[1] ) }
  );
}

sub ensure_stage {
  my ( $self, $type, %rep ) = @_;
  WWW::Authentik::Error::Validation->throw( message => 'ensure_stage needs a name' ) unless defined $rep{name};
  $self->_stage_path($type);   # refuses 'all' and a missing type
  my $wanted = $self->resolve( \%rep );
  return $self->_ensure(
    wanted => $wanted,
    find   => sub {
      my $stage = $self->find_stage( $rep{name} ) or return;
      # a stage name is unique across all types, so a name that belongs to
      # another type is a clash, not something to create or update
      my $whole = eval { $self->get_stage( $type, $stage->{pk} ) };
      return $whole if $whole;
      $self->_missing($@);
      WWW::Authentik::Error::Validation->throw( message => 'ensure_stage: there already is a stage named "'
        .$rep{name}.'", but not of the type '.$type.' ('.( $stage->{component} // 'unknown component' ).'). '
        .'Stage names are unique across all types in authentik.' );
    },
    create => sub { $self->create_stage( $type, $wanted ) },
    update => sub { $self->update_stage( $type, $_[0]{pk}, $_[1] ) }
  );
}

sub ensure_binding {
  my ( $self, %arg ) = @_;
  for (qw( flow stage order )) {
    WWW::Authentik::Error::Validation->throw( message => 'ensure_binding needs '.$_ ) unless defined $arg{$_};
  }
  my %wanted = %arg;
  my $flow   = eval { $self->_flow_pk( delete $wanted{flow} ) }
    or WWW::Authentik::Error::Validation->throw( message => 'ensure_binding: no flow "'.$arg{flow}.'"' );
  my $stage  = $wanted{stage};
  unless ( $stage =~ $UUID ) {
    my $found = $self->find_stage($stage)
      or WWW::Authentik::Error::Validation->throw( message => 'ensure_binding: no stage "'.$stage.'"' );
    $stage = $found->{pk};
  }
  @wanted{qw( target stage )} = ( $flow, $stage );
  return $self->_ensure(
    wanted => \%wanted,
    # a flow binds a stage at most once here; the order is what ensure moves
    find   => sub { $self->_find_one( $self->list_bindings( target => $flow, stage => $stage ), 'stage', $stage ) },
    create => sub { $self->create_binding( \%wanted ) },
    update => sub { $self->update_binding( $_[0]{pk}, $_[1] ) }
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Authentik::API - authentik REST API v3 with idempotent ensure methods

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $api = WWW::Authentik->new( base_url => $url, token => $token )->api;

    # one call, one endpoint
    my $user = $api->find_user('alice');
    my $new  = $api->create_group( { name => 'staff' } );

    # wanted state, as often as you like
    my $r = $api->ensure_user( username => 'alice', name => 'Alice', group_names => ['staff'] );
    print $r->{changed};        # 'created', 'updated' or ''
    print $r->{object}{pk};

=head1 DESCRIPTION

authentik's REST API v3 for the whole instance. There is no realm; what a
call reaches is decided by the API token.

The basic methods are one endpoint each. C<get_*> and C<find_*> return the
representation as a hash (C<find_*> returns nothing when there is no match),
C<list_*> an array reference with every match, C<create_*> and C<update_*> the
representation authentik answered with, and C<delete_*> true.

A C<list_*> walks authentik's pagination for you, asking for L</page_size>
objects at a time and following C<pagination.next> until it is 0. It stops
when a page comes round a second time, so an answer whose C<next> points
backwards ends the walk instead of running for ever.

Writing is C<PATCH>. authentik's C<PUT> wants the required fields but leaves
everything else alone, so it replaces nothing that C<PATCH> would not; there
is no reason to use it.

Every failure is a L<WWW::Authentik::Error::API>. Note that a duplicate is
B<400> with a field error, not 409, and that a refused token is B<403>, not
401.

The C<ensure_*> methods are what makes a setup repeatable. Each looks the
object up by its readable key, creates it when it is missing, otherwise
writes only what differs, and returns
C<< { object => \%rep, changed => 'created' | 'updated' | '' } >>. Only the
keys given are compared; nothing is ever deleted.

Where authentik wants an identifier and a person knows a name,
L</resolve> looks it up. Which form counts as the identifier is fixed per
field and never guessed; see there.

=head2 base_url

Required. The authentik URL without C</api/v3>.

=head2 token

Required. The API token, sent as a bearer token with every call.

=head2 ua

Required. The L<LWP::UserAgent> to use.

=head2 page_size

How many objects a C<list_*> asks for per request. Default 100.

=head2 uuid_pattern

=head2 integer_pattern

The two shapes L</resolve> takes for an identifier rather than a name: a
UUID and a run of digits. L<Net::Async::Authentik::API> uses these so the
distinction is made in one place.

=head2 diff_class

The class the C<ensure_*> methods compare with, L<WWW::Authentik::Diff>.
L<Net::Async::Authentik> uses the same one.

=head2 api_url

    print $api->api_url;   # https://id.example.org/api/v3

=head2 call

    my $result = $api->call( GET => '/core/users/?username=alice' );
    my $result = $api->call( POST => '/core/groups/', { name => 'staff' } );

One request against the API. Returns what
L<WWW::Authentik::Role::HTTP/send_request> returns. The way to reach an
endpoint this class has no method for. Mind the trailing slash: authentik
answers a path without one with 404, and this method adds nothing.

=head2 version

    print $api->version->{version_current};   # 2026.8.3

=head2 config

The instance's public configuration.

=head2 settings

The instance settings, among them C<default_token_duration>, which decides
how long a new token lives.

=head2 me

Who the API token belongs to.

=head2 list_users

    my $users = $api->list_users( type => 'internal' );

=head2 find_user

    my $user = $api->find_user('alice') or die 'no such user';

By C<username>, exactly and case-sensitively: authentik lets C<Alice> and
C<alice> exist side by side.

=head2 get_user

=head2 create_user

    my $user = $api->create_user( { username => 'alice', name => 'Alice' } );

=head2 update_user

=head2 delete_user

=head2 set_password

    $api->set_password( $user->{pk}, $password );

authentik accepts any password here; a password policy only applies inside a
flow.

=head2 create_service_account

    my $account = $api->create_service_account( name => 'provisioner' );
    print $account->{token};   # handed out once, and only here

Creates a user of type C<service_account> together with an app-password
token. That token is the C<password> for
L<WWW::Authentik::OIDC/client_credentials_token> with a username.

=head2 list_authenticators

    my $devices = $api->list_authenticators( $user->{pk} );

The authenticator devices of a user, as a plain list. Creating a TOTP device
over the API is not possible: C<POST /authenticators/admin/totp/> answers 500
in authentik 2026.8.3. Enrolment goes through the TOTP setup flow.

=head2 list_groups

=head2 find_group

    my $group = $api->find_group('staff');

=head2 get_group

=head2 create_group

=head2 update_group

=head2 delete_group

=head2 add_user_to_group

    $api->add_user_to_group( $group->{pk}, $user->{pk} );

=head2 remove_user_from_group

Removing someone who is not a member answers 204 as well.

=head2 list_tokens

=head2 find_token

    my $token = $api->find_token('provisioner');

By C<identifier>, which is also the address of the detail endpoint.

=head2 get_token

=head2 create_token

    my $token = $api->create_token( { identifier => 'provisioner', intent => 'api', expiring => \0 } );

C<expires> cannot be chosen: authentik ignores it and sets the expiry from
the instance setting C<default_token_duration>. C<< expiring => \0 >> is how
a token is made to live for ever.

=head2 update_token

=head2 delete_token

=head2 view_token_key

    my $key = $api->view_token_key('provisioner')->{key};

=head2 set_token_key

    $api->set_token_key( 'provisioner', $key );

Puts a key of your choosing on a token, so a setup can know it without
reading it back.

=head2 list_applications

=head2 find_application

    my $app = $api->find_application('my-app');

By slug, which is the address of the detail endpoint. Returns nothing when
there is none.

=head2 create_application

    my $app = $api->create_application( { name => 'My App', slug => 'my-app', provider => $provider->{pk} } );

An application holds at most one provider, and a provider belongs to at most
one application.

=head2 update_application

=head2 delete_application

=head2 check_access

    my $access = $api->check_access('my-app');
    my $access = $api->check_access( 'my-app', for_user => $user->{pk} );

Whether the application's policies let someone in:
C<< { passing => 1, messages => [], log_messages => [] } >>.

Without C<for_user> the answer is about the user the API token belongs to. A
C<for_user> that no user has is a plain field error
(C<< 400 {"for_user": "User not found"} >>), so a stale id cannot pass for an
answer — with one exception worth knowing: C<< for_user => 1 >> is accepted
on 2026.8.3 because primary key 1 is authentik's internal C<AnonymousUser>,
which L</get_user> and L</list_users> both deny the existence of.

=head2 list_oauth2_providers

=head2 find_oauth2_provider

    my $provider = $api->find_oauth2_provider('my-app');

By C<name>, which is unique.

=head2 get_oauth2_provider

=head2 create_oauth2_provider

    my $provider = $api->create_oauth2_provider( {
      name               => 'my-app',
      authorization_flow => $flow->{pk},
      invalidation_flow  => $other->{pk},
      redirect_uris      => [ { matching_mode => 'strict', url => 'https://app.example.org/cb' } ],
      grant_types        => [qw( authorization_code refresh_token )],
    } );

C<name>, C<authorization_flow>, C<invalidation_flow> and C<redirect_uris> are
required. Without C<grant_types> authentik stores an empty list, and such a
provider answers every token request with C<invalid_grant>;
L</ensure_oauth2_provider> refuses to create one.

=head2 update_oauth2_provider

=head2 delete_oauth2_provider

=head2 provider_setup_urls

    my $urls = $api->provider_setup_urls( $provider->{pk} );

The OpenID endpoints of the provider. C<issuer>, C<provider_info>, C<jwks>
and C<logout> are undef until the provider belongs to an application.

=head2 preview_user

    my $preview = $api->preview_user( $provider->{pk}, $user->{pk} );

What a token for this user would contain, without issuing one.

=head2 list_scope_mappings

=head2 find_scope_mapping

    my $mapping = $api->find_scope_mapping("authentik default OAuth Mapping: OpenID 'email'");

By C<name>, which is unique. C<scope_name> is not: several mappings may offer
the same scope.

=head2 find_scope_mappings_by_scope

    my $mappings = $api->find_scope_mappings_by_scope(qw( openid email profile ));

One mapping per scope name, in the order the names were given. A scope
without a mapping is a validation error naming it. When several mappings
offer the same scope the first authentik lists wins.

=head2 get_scope_mapping

=head2 create_scope_mapping

    my $mapping = $api->create_scope_mapping( { name => 'amr', scope_name => 'amr',
      expression => 'return {"amr": request.context.get("amr", [])}' } );

C<name>, C<scope_name> and C<expression> are required, and the expression is
compiled when it arrives: a syntax error comes back as a field error on
C<expression>.

=head2 update_scope_mapping

=head2 delete_scope_mapping

=head2 test_property_mapping

    my $result = $api->test_property_mapping( $mapping->{pk}, user => $user->{pk} );

=head2 list_flows

=head2 find_flow

    my $flow = $api->find_flow('default-authentication-flow');

By slug. The C<pk> in the answer is the UUID everything else refers to.

=head2 create_flow

    my $flow = $api->create_flow( { name => 'Probe', slug => 'probe', title => 'Probe',
      designation => 'authentication' } );

=head2 update_flow

=head2 delete_flow

=head2 export_flow

    my $yaml = $api->export_flow('default-authentication-flow');

The flow as a blueprint. authentik answers YAML with a C<text/html> content
type, so this returns the body as a string, not a structure.

=head2 stage_types

All 25 stage types authentik offers, each with its C<component> and
C<model_name>.

=head2 list_stages

    my $stages = $api->list_stages;

Every stage of every type, in the reduced representation C</stages/all/>
gives out: C<pk>, C<name>, C<component> and C<meta_model_name>, without the
fields of its type. Use L</get_stage> with the type for the whole thing.

=head2 find_stage

    my $stage = $api->find_stage('default-authentication-mfa-validation');

By C<name>, which is unique across all stage types.

=head2 get_stage

    my $stage = $api->get_stage( 'authenticator/validate', $uuid );

C<$type> is the path under C</stages/>: C<password>, C<identification>,
C<user_login>, C<authenticator/validate>, C<authenticator/totp>, C<consent>
and so on. C<all> is refused, because that endpoint can only be read.

=head2 create_stage

    my $stage = $api->create_stage( password => { name => 'probe-password',
      backends => ['authentik.core.auth.InbuiltBackend'] } );

=head2 update_stage

=head2 delete_stage

Deleting a stage deletes the bindings that point at it.

=head2 list_bindings

    my $bindings = $api->list_bindings( flow => 'my-flow' );
    my $bindings = $api->list_bindings( target => $flow->{pk} );

C<flow> takes a slug or a UUID and is turned into C<target>. C<target> itself
goes through as it is, and authentik answers a slug there with a field
error.

=head2 get_binding

=head2 create_binding

    my $binding = $api->create_binding( { target => $flow->{pk}, stage => $stage->{pk}, order => 20 } );

C<target>, C<stage> and C<order> together are unique.

=head2 update_binding

=head2 delete_binding

=head2 list_brands

=head2 current_brand

    my $brand = $api->current_brand;

The brand that applies to this request, as C<flow_device_code> and the other
flows it names — what a device flow needs for a person to be able to approve
it.

B<This is the public view, and it cannot be written back.> It has neither
C<brand_uuid> nor C<domain>, so there is nothing to hand L</update_brand>.
To change a brand, take it from L</list_brands>:

    my ( $brand ) = grep { $_->{default} } @{ $api->list_brands };
    $api->update_brand( $brand->{brand_uuid}, { flow_device_code => $flow->{pk} } );

=head2 update_brand

    $api->update_brand( $brand->{brand_uuid}, { flow_device_code => $flow->{pk} } );

A brand is addressed by C<brand_uuid>, not by C<pk>.

=head2 list_certificates

=head2 find_certificate

    my $cert = $api->find_certificate('authentik Self-signed Certificate');

=head2 list_blueprints

=head2 get_blueprint

=head2 create_blueprint

    my $blueprint = $api->create_blueprint( { name => 'probe', content => $yaml } );

The YAML is validated when it arrives; an unknown model is a field error on
C<content>.

=head2 apply_blueprint

    $api->apply_blueprint( $blueprint->{pk} );

Asks authentik to apply it. The worker does that in the background, so the
answer still says C<< status => 'unknown' >>; read the blueprint again a
moment later to see C<successful>.

=head2 delete_blueprint

=head2 resolvable_fields

The table L</resolve> works from: field name to the identifier form, the key
that forces a lookup, and the method that does it.

=head2 resolve

    my $rep = $api->resolve( { authorization_flow => 'default-authentication-flow' } );
    # { authorization_flow => '57b03d1d-...' }

authentik wants identifiers where a person knows a name. This turns the
names into identifiers, and it never guesses: for every field, one shape
counts as the identifier and everything else is a name.

    field                 identifier is          forced lookup
    --------------------- ---------------------- ---------------------------
    provider              an integer             provider_name
    user                  an integer             user_name
    authorization_flow    a UUID                 authorization_flow_slug
    invalidation_flow     a UUID                 invalidation_flow_slug
    authentication_flow   a UUID                 authentication_flow_slug
    configure_flow        a UUID                 configure_flow_slug
    flow_device_code      a UUID                 flow_device_code_slug
    signing_key           a UUID                 signing_key_name
    encryption_key        a UUID                 encryption_key_name
    groups                UUIDs                  group_names
    property_mappings     UUIDs                  property_mapping_names
    configuration_stages  UUIDs                  configuration_stage_names

So a provider named C<123> cannot be reached through C<provider>, because
C<< provider => '123' >> is the provider with the primary key 123. Write
C<< provider_name => '123' >>; the forced form never looks at the shape of
the value. The same goes for a flow whose slug happens to look like a UUID.
Giving both forms of one field is a validation error, and so is a name
nothing matches.

C<scopes> is the one field with no counterpart in authentik: a list of scope
names that becomes C<property_mappings>. Giving C<scopes> together with
C<property_mappings> is a validation error.

=head2 ensure_user

    my $r = $api->ensure_user( username => 'alice', name => 'Alice',
      email => 'alice@example.org', password => $pw, group_names => ['staff'] );

Found by C<username>. C<password> is not a field of the user: it is set once,
right after the user is created, and never touched again, so a setup that
runs twice does not reset it. Call L</set_password> to change one.

=head2 ensure_group

Found by C<name>.

=head2 ensure_token

    my $r = $api->ensure_token( identifier => 'provisioner', intent => 'api',
      expiring => \0, user_name => 'akadmin', key => $key );

Found by C<identifier>. C<key> is like C<password>: put on the token when it
is created, never after. C<expires> is refused, because authentik ignores it.

=head2 ensure_application

    my $r = $api->ensure_application( slug => 'my-app', name => 'My App', provider_name => 'my-app' );

Found by C<slug>.

=head2 ensure_oauth2_provider

    my $r = $api->ensure_oauth2_provider(
      name                    => 'my-app',
      authorization_flow_slug => 'default-provider-authorization-implicit-consent',
      invalidation_flow_slug  => 'default-provider-invalidation-flow',
      client_type             => 'confidential',
      grant_types             => [qw( authorization_code refresh_token )],
      redirect_uris           => [ { matching_mode => 'strict', url => 'https://app.example.org/cb' } ],
      scopes                  => [qw( openid email profile )],
      signing_key_name        => 'authentik Self-signed Certificate',
    );

Found by C<name>. Creating one without a non-empty C<grant_types> is refused:
authentik would store an empty list and the provider would answer every token
request with C<invalid_grant>. Updating an existing provider does not need
them.

C<redirect_uris> may be written without C<redirect_uri_type>; authentik adds
it, and the comparison knows that. C<property_mappings> come back in
authentik's own order, and the comparison treats them as a set, so a second
run reports no change.

=head2 ensure_scope_mapping

Found by C<name>.

=head2 ensure_flow

Found by C<slug>.

=head2 ensure_stage

    my $r = $api->ensure_stage( 'authenticator/validate',
      name                  => 'default-authentication-mfa-validation',
      not_configured_action => 'deny',
    );

Found by C<name>, which is unique across all stage types; read, created and
written through the typed endpoint. Note that
C<< not_configured_action => 'configure' >> needs C<configuration_stages> in
the same write, which happens by itself here because every differing key goes
out in one C<PATCH>.

=head2 ensure_binding

    my $r = $api->ensure_binding( flow => 'probe-flow', stage => 'probe-password', order => 20 );

C<flow> takes a slug or a UUID, C<stage> a name or a UUID. A flow binds a
given stage once: a second call with another C<order> moves the binding
instead of adding one. Bind a stage twice with L</create_binding>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-authentik/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
