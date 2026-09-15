#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/07.cose-exception.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Web::Authn;
    use Web::Authn::COSE;
    use Web::Authn::Exception;
    use Web::Authn::NullObject;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

# NOTE: COSE constants and helpers
subtest 'COSE constants and helpers' => sub
{
    is( Web::Authn::COSE::ECDSA_SHA_256, -7, 'ES256' );
    is( Web::Authn::COSE::EDDSA, -8, 'EdDSA' );
    is( Web::Authn::COSE::KTY_EC2, 2, 'kty EC2' );
    ok( Web::Authn::COSE::is_ecdsa( -7 ), 'is_ecdsa ES256' );
    ok( Web::Authn::COSE::is_ecdsa( -35 ), 'is_ecdsa ES384' );
    ok( !Web::Authn::COSE::is_ecdsa( -8 ), 'EdDSA is not ecdsa' );
    ok( Web::Authn::COSE::is_rsa_pkcs( -257 ), 'RS256 pkcs' );
    ok( Web::Authn::COSE::is_rsa_pss( -37 ), 'PS256' );
    is( Web::Authn::COSE::alg_hash_name( -7 ), 'SHA256', 'hash name ES256' );
    my @algs = Web::Authn::COSE::default_supported_algs();
    ok( scalar( grep{ $_ == -7 } @algs ), 'default includes ES256' );
    ok( scalar( grep{ $_ == -8 } @algs ), 'default includes EdDSA' );
};

# NOTE: Exception objects
subtest 'Exception objects' => sub
{
    my $e = Web::Authn::Exception->new( message => 'boom', code => 400 );
    is( $e->message, 'boom', 'message' );
    is( $e->code, 400, 'code' );
    like( $e->as_string, qr/boom/, 'as_string' );
    is( "$e", $e->as_string, 'stringify' );

    isa_ok( Web::Authn::Exception::InvalidRegistration->new( 'x' ), 'Web::Authn::Exception' );
    isa_ok( Web::Authn::Exception::InvalidAuthentication->new( 'x' ), 'Web::Authn::Exception' );
    isa_ok( Web::Authn::Exception::InvalidStructure->new( 'x' ), 'Web::Authn::Exception' );

    local $@;
    eval { Web::Authn::Exception::InvalidRegistration->throw( 'nope' ) };
    ok( $@, 'throw dies' );
    isa_ok( $@, 'Web::Authn::Exception::InvalidRegistration' );
    is( $@->message, 'nope', 'thrown message' );
};

# NOTE: pass_error and NullObject
subtest 'pass_error and NullObject' => sub
{
    my $authn = Web::Authn->new( rp_id => 'example.com', rp_name => 'X' );
    {
        no warnings 'Web::Authn';
        my $bad = $authn->generate_registration_options( user_name => '' );
        ok( !defined( $bad ), 'bad options' );
        my $sink = bless( {}, 'Web::Authn' );
        $sink->{fatal} = 0;
        my $r = $sink->pass_error( $authn->error );
        ok( !defined( $r ), 'pass_error returns undef in scalar' );
        isa_ok( $sink->error, 'Web::Authn::Exception' );
    }

    my $null = Web::Authn::NullObject->new;
    ok( !defined( $null->anything ), 'NullObject swallows methods' );
};

# NOTE: options_to_json_dict
subtest 'options_to_json_dict' => sub
{
    my $authn = Web::Authn->new( rp_id => 'example.com', rp_name => 'X' );
    my $opts = $authn->generate_registration_options(
        user_name           => 'bob',
        user_display_name   => 'Bob',
        exclude_credentials => [ { type => 'public-key', id => 'abc' } ],
        authenticator_selection =>
        {
            resident_key      => 'preferred',
            user_verification => 'required',
        },
    );
    my $dict = $authn->options_to_json_dict( $opts );
    is( $dict->{user}{displayName}, 'Bob', 'displayName' );
    ok( $dict->{excludeCredentials}, 'excludeCredentials' );
    is( $dict->{authenticatorSelection}{userVerification}, 'required', 'UV' );

    my $auth = $authn->generate_authentication_options(
        allow_credentials => [ { type => 'public-key', id => 'abc' } ],
    );
    my $ad = $authn->options_to_json_dict( $auth );
    ok( $ad->{allowCredentials}, 'allowCredentials' );
    is( $ad->{rpId}, 'example.com', 'rpId' );
};

done_testing;

__END__
