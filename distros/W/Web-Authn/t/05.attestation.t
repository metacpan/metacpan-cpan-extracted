#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/05.attestation.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Web::Authn::Attestation;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

# NOTE: verify_none
subtest 'verify_none' => sub
{
    ok( Web::Authn::Attestation::verify_none( att_stmt => {} ), 'empty attStmt is valid none' );
    ok( Web::Authn::Attestation::verify( fmt => 'none', att_stmt => {} ), 'verify dispatches none' );

    local $@;
    eval { Web::Authn::Attestation::verify_none( att_stmt => { sig => 'nope' } ) };
    ok( $@, 'non-empty attStmt rejected' );
    isa_ok( $@, 'Web::Authn::Exception::InvalidRegistration' );
};

# NOTE: unknown fmt
subtest 'unknown fmt' => sub
{
    local $@;
    eval { Web::Authn::Attestation::verify( fmt => 'not-a-format', att_stmt => {} ) };
    ok( $@, 'unknown fmt dies' );
    like( "$@", qr/Unsupported attestation/i, 'message' );
};

# NOTE: packed missing fields
subtest 'packed missing fields' => sub
{
    local $@;
    eval { Web::Authn::Attestation::verify_packed( att_stmt => {} ) };
    ok( $@, 'packed without sig dies' );

    local $@;
    eval { Web::Authn::Attestation::verify_packed( att_stmt => { sig => 'x' } ) };
    ok( $@, 'packed without alg dies' );
};

# NOTE: fido-u2f missing fields
subtest 'fido-u2f missing fields' => sub
{
    local $@;
    eval { Web::Authn::Attestation::verify_fido_u2f( att_stmt => {} ) };
    ok( $@, 'u2f without sig dies' );
};

# NOTE: apple missing x5c
subtest 'apple missing x5c' => sub
{
    local $@;
    eval { Web::Authn::Attestation::verify_apple( att_stmt => {} ) };
    ok( $@, 'apple without x5c dies' );
};

# NOTE: android-key missing fields
subtest 'android-key missing fields' => sub
{
    local $@;
    eval { Web::Authn::Attestation::verify_android_key( att_stmt => {} ) };
    ok( $@, 'android-key without sig/x5c dies' );
};

# NOTE: tpm missing fields
subtest 'tpm missing fields' => sub
{
    local $@;
    eval { Web::Authn::Attestation::verify_tpm( att_stmt => { sig => 'x' } ) };
    ok( $@, 'tpm incomplete dies' );
};

# NOTE: sha helpers
subtest 'sha helpers' => sub
{
    my $d = 'abc';
    is( length( Web::Authn::Attestation::sha384( $d ) ), 48, 'sha384 length' );
    is( length( Web::Authn::Attestation::sha512( $d ) ), 64, 'sha512 length' );
};

done_testing;

__END__
