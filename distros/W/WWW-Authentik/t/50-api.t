#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeAuthentik;
use WWW::Authentik;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

my $fake = FakeAuthentik->new;
my $api  = WWW::Authentik->new( base_url => $fake->base, token => $fake->token, ua => $fake )->api;

subtest 'transport' => sub {
  is( $api->api_url, $fake->base.'/api/v3', 'api_url' );
  my $result = $api->call( GET => '/core/users/me/' );
  is( $result->{status}, 200, 'a call comes back' );
  is( $result->{data}{user}{username}, 'akadmin', 'with the data' );
  is( $api->call( GET => 'core/users/me/' )->{status}, 200, 'a leading slash is added' );

  # authentik answers a path without the trailing slash with 404, and call()
  # adds nothing: a raw caller gets what it asked for
  isa_ok( error_of { $api->call( GET => '/core/users' ) }, 'WWW::Authentik::Error::API', 'a path without a trailing slash' );

  my $sent = $fake->requests->[0];
  is( $sent->[0], 'GET', 'the method' );
  like( $sent->[1], qr{\A/api/v3/core/users/me/}, 'the path' );
};

subtest 'instance' => sub {
  is( $api->version->{version_current}, '2026.8.3', 'version' );
  is( $api->settings->{default_token_duration}, 'days=1', 'settings' );
  ok( $api->config, 'config' );
  is( $api->me->{user}{username}, 'akadmin', 'me' );
};

subtest 'pagination' => sub {
  my $many = FakeAuthentik->new;
  $many->add( users => { username => sprintf( 'bulk-%03d', $_ ), name => 'Bulk '.$_ } ) for 1 .. 25;
  my $small = WWW::Authentik::API->new( base_url => $many->base, token => $many->token, ua => $many, page_size => 10 );
  my $all = $small->list_users;
  is( scalar @$all, 26, 'every user, over three pages' );
  is( scalar @{ $many->requests }, 3, 'in three requests' );

  is( scalar @{ $small->list_users( username => 'bulk-001' ) }, 1, 'a filter narrows it' );
  is( scalar @{ $small->list_users( username => 'nobody' ) }, 0, 'and can find nothing' );

  # an answer whose next points at a page already fetched must not loop
  $many->break_pagination;
  my $guarded = $small->list_users;
  cmp_ok( scalar @$guarded, '>', 0, 'a broken pagination still returns' );
  cmp_ok( scalar @$guarded, '<=', 26, 'and does not run away' );
};

subtest 'users' => sub {
  my $user = $api->create_user( { username => 'alice', name => 'Alice', email => 'alice@example.org', attributes => { dept => 'x' } } );
  ok( $user->{pk}, 'create_user gives the object back, with its pk' );
  is( $user->{type}, 'internal', 'with the defaults authentik fills in' );

  my $duplicate = error_of { $api->create_user( { username => 'alice', name => 'Alice again' } ) };
  is( $duplicate->http_status, 400, 'a duplicate is 400, not 409' );
  is_deeply( $duplicate->field_errors, { username => ['This field must be unique.'] }, 'with a field error' );

  is( $api->find_user('alice')->{pk}, $user->{pk}, 'find_user' );
  is( $api->find_user('Alice'), undef, 'which is case sensitive, the way authentik stores names' );
  is( $api->find_user('nobody'), undef, 'and finds nothing when there is nothing' );
  is( $api->get_user( $user->{pk} )->{username}, 'alice', 'get_user' );
  ok( error_of { $api->get_user(999999) }->is_not_found, 'and 404 for an unknown pk' );

  my $patched = $api->update_user( $user->{pk}, { name => 'Alice B', attributes => { site => 'y' } } );
  is( $patched->{name}, 'Alice B', 'update_user writes' );
  is( $patched->{email}, 'alice@example.org', 'and leaves what it was not told about' );
  is_deeply( $patched->{attributes}, { site => 'y' }, 'but attributes are replaced as a whole' );

  ok( $api->set_password( $user->{pk}, 'a-password' ), 'set_password' );
  is( $fake->passwords->{ $user->{pk} }, 'a-password', 'and it arrived' );

  my $account = $api->create_service_account( name => 'provisioner' );
  ok( $account->{token}, 'create_service_account hands the token out' );
  is( $api->find_user('provisioner')->{type}, 'service_account', 'and makes a service account' );
  isa_ok( error_of { $api->create_service_account }, 'WWW::Authentik::Error::Validation', 'without a name' );

  is_deeply( $api->list_authenticators( $user->{pk} ), [], 'list_authenticators' );

  ok( $api->delete_user( $user->{pk} ), 'delete_user' );
  ok( error_of { $api->delete_user( $user->{pk} ) }->is_not_found, 'and it is gone' );
};

subtest 'groups' => sub {
  my $group = $api->create_group( { name => 'staff', attributes => { a => 'b' } } );
  ok( $group->{pk}, 'create_group' );
  is_deeply( error_of { $api->create_group( { name => 'staff' } ) }->field_errors,
    { name => ['Group with this name already exists.'] }, 'a duplicate' );
  is( $api->find_group('staff')->{pk}, $group->{pk}, 'find_group' );
  is( $api->get_group( $group->{pk} )->{name}, 'staff', 'get_group' );

  my $user = $api->create_user( { username => 'bob', name => 'Bob' } );
  ok( $api->add_user_to_group( $group->{pk}, $user->{pk} ), 'add_user_to_group' );
  is_deeply( $api->get_group( $group->{pk} )->{users}, [ $user->{pk} ], 'and he is in' );
  ok( $api->remove_user_from_group( $group->{pk}, $user->{pk} ), 'remove_user_from_group' );
  ok( $api->remove_user_from_group( $group->{pk}, $user->{pk} ), 'which does not mind a second time' );
  is_deeply( $api->get_group( $group->{pk} )->{users}, [], 'and he is out' );

  is( $api->update_group( $group->{pk}, { attributes => { a => 'c' } } )->{attributes}{a}, 'c', 'update_group' );
  ok( $api->delete_group( $group->{pk} ), 'delete_group' );
  $api->delete_user( $user->{pk} );
};

subtest 'tokens' => sub {
  my $token = $api->create_token( { identifier => 'provisioner', intent => 'api', expiring => \0 } );
  ok( $token->{pk}, 'create_token' );
  is_deeply( error_of { $api->create_token( { identifier => 'provisioner' } ) }->field_errors,
    { identifier => ['Token with this identifier already exists.'] }, 'a duplicate' );
  is( $api->find_token('provisioner')->{intent}, 'api', 'find_token by identifier' );
  is( $api->find_token('nope'), undef, 'and nothing for an unknown one' );
  ok( $api->view_token_key('provisioner')->{key}, 'view_token_key' );
  ok( $api->set_token_key( 'provisioner', 'a-key-of-my-own' ), 'set_token_key' );
  is( $api->view_token_key('provisioner')->{key}, 'a-key-of-my-own', 'and it stuck' );
  is( $api->update_token( 'provisioner', { description => 'x' } )->{description}, 'x', 'update_token' );
  ok( $api->delete_token('provisioner'), 'delete_token' );
};

subtest 'applications and providers' => sub {
  my $flow = $api->find_flow('default-provider-authorization-implicit-consent');
  ok( $flow->{pk}, 'the seeded flows are there' );

  my $bare = error_of { $api->create_oauth2_provider( { name => 'probe' } ) };
  is_deeply( [ sort keys %{ $bare->field_errors } ], [qw( authorization_flow invalidation_flow redirect_uris )],
    'a provider needs its flows and redirect URIs' );

  my $provider = $api->create_oauth2_provider( {
    name => 'probe', authorization_flow => $flow->{pk}, invalidation_flow => $flow->{pk},
    redirect_uris => [ { matching_mode => 'strict', url => 'https://app.example.org/cb' } ],
    grant_types => ['authorization_code']
  } );
  ok( $provider->{client_id} && $provider->{client_secret}, 'authentik generates the client credentials' );
  is( $provider->{redirect_uris}[0]{redirect_uri_type}, 'authorization', 'and fills in redirect_uri_type' );
  is( $api->find_oauth2_provider('probe')->{pk}, $provider->{pk}, 'find_oauth2_provider' );
  is( $api->get_oauth2_provider( $provider->{pk} )->{name}, 'probe', 'get_oauth2_provider' );

  my $bad_grant = error_of { $api->update_oauth2_provider( $provider->{pk}, { grant_types => ['banana'] } ) };
  is_deeply( $bad_grant->field_errors, { 'grant_types.0' => ['"banana" is not a valid choice.'] },
    'a nested field error is flattened' );

  my $app = $api->create_application( { name => 'Probe App', slug => 'probe-app', provider => $provider->{pk} } );
  is( $app->{slug}, 'probe-app', 'create_application' );
  is( $api->find_application('probe-app')->{provider}, $provider->{pk}, 'find_application' );
  is( $api->find_application('nope'), undef, 'and nothing for an unknown slug' );
  is_deeply( error_of { $api->create_application( { name => 'Second', slug => 'second', provider => $provider->{pk} } ) }->field_errors,
    { provider => ['Application with this provider already exists.'] }, 'a provider belongs to one application' );

  my $urls = $api->provider_setup_urls( $provider->{pk} );
  is( $urls->{issuer}, $fake->base.'/application/o/probe-app/', 'provider_setup_urls knows the application' );
  ok( $api->preview_user( $provider->{pk}, 1 )->{preview}, 'preview_user' );
  ok( $api->check_access('probe-app')->{passing}, 'check_access' );

  ok( $api->delete_application('probe-app'), 'delete_application' );
  ok( $api->delete_oauth2_provider( $provider->{pk} ), 'delete_oauth2_provider' );
};

subtest 'scope mappings' => sub {
  my $mappings = $api->list_scope_mappings;
  is( scalar @$mappings, 4, 'the default scope mappings' );
  my $found = $api->find_scope_mappings_by_scope(qw( openid email ));
  is( scalar @$found, 2, 'find_scope_mappings_by_scope' );
  is( $found->[0]{scope_name}, 'openid', 'in the order the scopes were given' );
  isa_ok( error_of { $api->find_scope_mappings_by_scope('no-such-scope') }, 'WWW::Authentik::Error::Validation', 'an unknown scope' );

  my $mapping = $api->create_scope_mapping( { name => 'probe', scope_name => 'probe', expression => 'return {}' } );
  ok( $mapping->{pk}, 'create_scope_mapping' );
  is( $api->find_scope_mapping('probe')->{pk}, $mapping->{pk}, 'find_scope_mapping' );
  is( $api->update_scope_mapping( $mapping->{pk}, { description => 'x' } )->{description}, 'x', 'update_scope_mapping' );
  ok( $api->test_property_mapping( $mapping->{pk}, user => 1 )->{successful}, 'test_property_mapping' );
  ok( $api->delete_scope_mapping( $mapping->{pk} ), 'delete_scope_mapping' );
};

subtest 'flows, stages and bindings' => sub {
  my $flow = $api->create_flow( { name => 'Probe', slug => 'probe-flow', title => 'Probe', designation => 'authentication' } );
  ok( $flow->{pk}, 'create_flow' );
  is( $api->find_flow('probe-flow')->{title}, 'Probe', 'find_flow' );
  like( $api->export_flow('probe-flow'), qr/\Aversion: 1/, 'export_flow gives the YAML as a string' );

  ok( scalar @{ $api->stage_types }, 'stage_types' );
  my $stage = $api->create_stage( password => { name => 'probe-password', backends => ['authentik.core.auth.InbuiltBackend'] } );
  ok( $stage->{pk}, 'create_stage' );
  is_deeply( error_of { $api->create_stage( user_login => { name => 'probe-password' } ) }->field_errors,
    { name => ['stage with this name already exists.'] }, 'a stage name is unique across the types' );
  is( $api->find_stage('probe-password')->{pk}, $stage->{pk}, 'find_stage' );
  is( $api->get_stage( password => $stage->{pk} )->{failed_attempts_before_cancel}, undef, 'get_stage through the typed endpoint' );
  is( $api->update_stage( password => $stage->{pk}, { failed_attempts_before_cancel => 3 } )->{failed_attempts_before_cancel},
    3, 'update_stage' );

  # /stages/all/ can only be read
  my $refused = error_of { $api->update_stage( all => $stage->{pk}, {} ) };
  isa_ok( $refused, 'WWW::Authentik::Error::Validation', 'writing through /stages/all/' );
  like( "$refused", qr{can only be read}, 'and says so' );
  isa_ok( error_of { $api->get_stage( undef, 'x' ) }, 'WWW::Authentik::Error::Validation', 'without a type' );

  my $binding = $api->create_binding( { target => $flow->{pk}, stage => $stage->{pk}, order => 20 } );
  ok( $binding->{pk}, 'create_binding' );
  is_deeply( error_of { $api->create_binding( { target => $flow->{pk}, stage => $stage->{pk}, order => 20 } ) }->field_errors,
    { non_field_errors => ['The fields target, stage, order must make a unique set.'] }, 'target, stage and order are unique' );
  is( scalar @{ $api->list_bindings( target => $flow->{pk} ) }, 1, 'list_bindings by target' );
  # authentik wants the UUID; a slug is the readable way in
  is( scalar @{ $api->list_bindings( flow => 'probe-flow' ) }, 1, 'list_bindings by flow slug' );
  is( scalar @{ $api->list_bindings( flow => $flow->{pk} ) }, 1, 'and by flow UUID' );
  isa_ok( error_of { $api->list_bindings( flow => 'no-such-flow' ) },
    'WWW::Authentik::Error::Validation', 'an unknown flow slug' );
  is( $api->update_binding( $binding->{pk}, { order => 30 } )->{order}, 30, 'update_binding' );
  is_deeply( $api->find_flow('probe-flow')->{stages}, [ $stage->{pk} ], 'the flow lists the stage' );

  ok( $api->delete_binding( $binding->{pk} ), 'delete_binding' );
  ok( $api->delete_stage( password => $stage->{pk} ), 'delete_stage' );
  ok( $api->delete_flow('probe-flow'), 'delete_flow' );
};

subtest 'brands, certificates and blueprints' => sub {
  ok( $api->current_brand, 'current_brand' );
  ok( scalar @{ $api->list_brands }, 'list_brands' );
  # the public view cannot be written back; the list is where the key is
  my ( $brand ) = grep { $_->{default} } @{ $api->list_brands };
  ok( $brand && $brand->{brand_uuid}, 'the list carries the brand_uuid' );
  is( $api->update_brand( $brand->{brand_uuid}, { branding_title => 'Probe' } )->{branding_title}, 'Probe', 'update_brand' );

  is( $api->find_certificate('authentik Self-signed Certificate')->{private_key_available}, 1, 'find_certificate' );
  is( $api->find_certificate('nope'), undef, 'and nothing for an unknown one' );

  my $blueprint = $api->create_blueprint( { name => 'probe', content => "version: 1\n" } );
  is( $blueprint->{status}, 'unknown', 'a new blueprint has not run yet' );
  is( $api->apply_blueprint( $blueprint->{pk} )->{status}, 'successful', 'apply_blueprint' );
  is( $api->get_blueprint( $blueprint->{pk} )->{status}, 'successful', 'get_blueprint' );
  ok( $api->delete_blueprint( $blueprint->{pk} ), 'delete_blueprint' );
};

done_testing;
