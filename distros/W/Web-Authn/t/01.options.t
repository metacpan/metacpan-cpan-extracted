#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/01.options.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Web::Authn qw(
        generate_registration_options
        generate_authentication_options
        options_to_json
        base64url_to_bytes
        bytes_to_base64url
        generate_challenge
    );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

# NOTE: functional interface
subtest 'functional interface' => sub
{
    my $reg = generate_registration_options(
        rp_id     => 'example.com',
        rp_name   => 'Example Co',
        user_name => 'bob',
    );
    ok( $reg->{rp}->{id} eq 'example.com', 'rp id' );
    ok( length( $reg->{challenge} ) == 64, 'default challenge is 64 bytes' );
    ok( length( $reg->{user}->{id} ) == 64, 'default user handle is 64 bytes' );
    is( $reg->{attestation}, 'none', 'default attestation none' );
    ok( @{$reg->{pub_key_cred_params}} >= 3, 'default algs include EdDSA ES256 RS256' );

    my $json = options_to_json( $reg );
    like( $json, qr/"challenge"/, 'options json has challenge' );
    like( $json, qr/"pubKeyCredParams"/, 'camelCase pubKeyCredParams' );
    like( $json, qr/"displayName"/, 'camelCase displayName' );

    my $auth = generate_authentication_options( rp_id => 'example.com' );
    is( $auth->{user_verification}, 'preferred', 'default UV preferred' );
    my $aj = options_to_json( $auth );
    like( $aj, qr/"rpId":"example.com"/, 'auth options rpId' );

    my $b = generate_challenge(16);
    is( length( $b ), 16, 'custom challenge length' );
    is( base64url_to_bytes( bytes_to_base64url( $b ) ), $b, 'b64url roundtrip' );

    no warnings 'Web::Authn';
    my $bad = generate_registration_options( rp_id => '', rp_name => 'x', user_name => 'y' );
    ok( !defined( $bad ), 'empty rp_id returns undef' );
    ok( Web::Authn->error, 'error object set' );
    like( Web::Authn->error->message, qr/rp_id/, 'error message mentions rp_id' );
    isa_ok( Web::Authn->error, 'Web::Authn::Exception' );
};

# NOTE: object-oriented interface
subtest 'object-oriented interface' => sub
{
    my $authn = Web::Authn->new(
        rp_id           => 'example.com',
        rp_name         => 'Example Co',
        expected_origin => 'https://example.com',
    );
    isa_ok( $authn, 'Web::Authn' );

    my $reg = $authn->generate_registration_options( user_name => 'bob' );
    ok( $reg, 'generate_registration_options' ) or diag( $authn->error );
    ok( $reg->{rp}->{id} eq 'example.com', 'rp id from object' );
    ok( length( $reg->{challenge} ) == 64, 'default challenge is 64 bytes' );
    ok( length( $reg->{user}->{id} ) == 64, 'default user handle is 64 bytes' );
    is( $reg->{attestation}, 'none', 'default attestation none' );
    ok( @{$reg->{pub_key_cred_params}} >= 3, 'default algs include EdDSA ES256 RS256' );

    my $json = $authn->options_to_json( $reg );
    like( $json, qr/"challenge"/, 'options json has challenge' );
    like( $json, qr/"pubKeyCredParams"/, 'camelCase pubKeyCredParams' );
    like( $json, qr/"displayName"/, 'camelCase displayName' );

    my $auth = $authn->generate_authentication_options;
    is( $auth->{user_verification}, 'preferred', 'default UV preferred' );
    my $aj = $authn->options_to_json( $auth );
    like( $aj, qr/"rpId":"example.com"/, 'auth options rpId' );

    my $b = $authn->generate_challenge(16);
    is( length( $b ), 16, 'custom challenge length' );
    is( $authn->base64url_to_bytes( $authn->bytes_to_base64url( $b ) ), $b, 'b64url roundtrip' );

    my $authn2 = Web::Authn->new;
    no warnings 'Web::Authn';
    my $bad = $authn2->generate_registration_options( rp_id => '', rp_name => 'x', user_name => 'y' );
    ok( !defined( $bad ), 'empty rp_id returns undef' );
    if( ok( $authn2->error, 'error object set' ) )
    {
        like( $authn2->error->message, qr/rp_id/, 'error message mentions rp_id' );
        isa_ok( $authn2->error, 'Web::Authn::Exception' );
    }

    my $fatal = Web::Authn->new( rp_id => 'example.com', rp_name => 'X', fatal => 1 );
    eval { $fatal->generate_registration_options( user_name => '' ) };
    ok( $@, 'fatal mode dies' );
    isa_ok( $@, 'Web::Authn::Exception' );

    my $fn = Web::Authn::generate_registration_options(
        rp_id     => 'example.com',
        rp_name   => 'Example Co',
        user_name => 'bob',
    );
    ok( $fn->{rp}->{id} eq 'example.com', 'functional wrapper' );
};

# NOTE: constructor aliases and unknown arguments
subtest 'constructor aliases and unknown arguments' => sub
{
    my $authn = Web::Authn->new(
        rp_id   => 'example.com',
        rp_name => 'Angels, Inc',
        origins => [ 'https://www.angels-inc.test' ],
        timeout => 120_000,
        debug   => 1,
    );
    ok( $authn, 'new() accepts origins and debug' ) or diag( Web::Authn->error );
    is( $authn->{expected_origin}->[0], 'https://www.angels-inc.test', 'origins aliased to expected_origin' );
    ok( $authn->{debug}, 'debug stored' );

    my $one = Web::Authn->new(
        rp_id  => 'example.com',
        origin => 'https://example.com',
    );
    is( $one->{expected_origin}, 'https://example.com', 'origin alias' );

    no warnings 'Web::Authn';
    my $bad = Web::Authn->new(
        rp_id   => 'example.com',
        rp_name => 'X',
        rpId    => 'typo',
    );
    ok( !defined( $bad ), 'unknown argument rejected' );
    like( Web::Authn->error->message, qr/Unknown argument/, 'error mentions unknown argument' );
    like( Web::Authn->error->message, qr/'rpId'/, 'error names the bad key' );

    my $ok = Web::Authn->new(
        rp_id           => 'example.com',
        rp_name         => 'Example Co',
        expected_origin => 'https://example.com',
    );
    no warnings 'Web::Authn';
    my $bad_opts = $ok->generate_registration_options(
        user_name => 'bob',
        userName  => 'typo',
    );
    ok( !defined( $bad_opts ), 'unknown generate_registration_options argument rejected' );
    like( $ok->error->message, qr/'userName'/, 'generate_registration_options names the bad key' );

    my $bad_auth = $ok->generate_authentication_options( rpID => 'x' );
    ok( !defined( $bad_auth ), 'unknown generate_authentication_options argument rejected' );
    like( $ok->error->message, qr/'rpID'/, 'generate_authentication_options names the bad key' );

    my $bad_ver = $ok->verify_registration_response(
        credential         => {},
        expected_challenge => 'x',
        origin             => 'https://example.com',
        challenge          => 'typo-not-a-key',
    );
    ok( !defined( $bad_ver ), 'unknown verify_registration_response argument rejected' );
    like( $ok->error->message, qr/'challenge'/, 'verify_registration_response names the bad key' );

    my $again = $ok->new( rpId => 'typo' );
    ok( !defined( $again ), 'new() on instance rejects unknown argument' );
    like( $ok->error->message, qr/'rpId'/, 'error stored on the instance' );
};

done_testing;

__END__
