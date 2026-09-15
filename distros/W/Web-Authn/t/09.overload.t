#!perl
##----------------------------------------------------------------------------
## WebAuthn - t/09.overload.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    use Scalar::Util ();
    use Web::Authn;
};

# NOTE: registration options accept stringifiable objects
subtest 'registration options accept stringifiable objects' => sub
{
    my $authn = Web::Authn->new(
        rp_id           => T::Str->new( 'example.com' ),
        rp_name         => T::Str->new( 'Example Co' ),
        expected_origin => T::Str->new( 'https://example.com' ),
        timeout         => T::Str->new( '30000' ),
        fatal           => T::Str->new( '0' ),
    );
    isa_ok( $authn, 'Web::Authn' );
    is( $authn->{rp_id}, 'example.com', 'rp_id stringified' );
    is( $authn->{timeout}, 30000, 'timeout numified' );
    ok( !$authn->{fatal}, 'fatal falsey string' );

    my $uid = T::Str->new( "\x01\x02\x03\x04" );
    my $opts = $authn->generate_registration_options(
        user_name         => T::Str->new( 'bob' ),
        user_display_name => T::Str->new( 'Bob' ),
        user_id           => $uid,
        attestation       => T::Str->new( 'none' ),
    );
    ok( $opts, 'options generated' ) or diag( $authn->error );
    is( $opts->{rp}->{id}, 'example.com', 'rp.id' );
    is( $opts->{user}->{name}, 'bob', 'user.name' );
    is( $opts->{user}->{id}, "\x01\x02\x03\x04", 'user.id bytes' );
    is( $opts->{attestation}, 'none', 'attestation' );

    my $json = $authn->options_to_json( $opts );
    ok( $json, 'options_to_json' );
    unlike( $json, qr/T::Str/, 'JSON has no blessed class' );
    like( $json, qr/"name":"bob"/, 'JSON user name' );
};

# NOTE: authentication options and origin array
subtest 'authentication options and origin array' => sub
{
    my $authn = Web::Authn->new(
        rp_id => T::Str->new( 'example.com' ),
        expected_origin => [
            T::Str->new( 'https://example.com' ),
            T::Str->new( 'https://www.example.com' ),
        ],
    );
    my $opts = $authn->generate_authentication_options(
        user_verification => T::Str->new( 'preferred' ),
        challenge         => T::Str->new( 'A' x 32 ),
    );
    ok( $opts, 'auth options' ) or diag( $authn->error );
    is( $opts->{rp_id}, 'example.com', 'rp_id' );
    is( $opts->{challenge}, 'A' x 32, 'challenge stringified' );
    is( $opts->{user_verification}, 'preferred', 'uv' );

    ok( $authn->_check_origin( $authn->{expected_origin}, 'https://www.example.com', 'InvalidAuthentication' ), 'origin in array' );
};

# NOTE: b64u and maybe_bytes
subtest 'b64u and maybe_bytes' => sub
{
    my $raw = "\x00\x01\x02";
    my $enc = Web::Authn::Parse::b64u_encode( T::Str->new( $raw ) );
    is( $enc, Web::Authn::Parse::b64u_encode( $raw ), 'b64u_encode object' );
    is( Web::Authn::Parse::b64u_decode( T::Str->new( $enc ) ), $raw, 'b64u_decode object' );
    is( Web::Authn::Parse::maybe_bytes( T::Str->new( $raw ) ), $raw, 'maybe_bytes object' );
    is( length( Web::Authn::Parse::generate_challenge( T::Str->new( '16' ) ) ), 16, 'challenge length from object' );
};

# NOTE: Module::Generic::Array lookalike (reftype ARRAY, ref is the class)
subtest 'reftype for array objects' => sub
{
    my $origins = T::Array->new(
        T::Str->new( 'https://example.com' ),
        T::Str->new( 'https://www.example.com' ),
    );
    is( Scalar::Util::reftype( $origins ), 'ARRAY', 'T::Array reftype' );
    isnt( ref( $origins ), 'ARRAY', 'T::Array ref is not ARRAY' );

    my $authn = Web::Authn->new(
        rp_id           => 'example.com',
        rp_name         => 'Example Co',
        expected_origin => $origins,
    );
    isa_ok( $authn, 'Web::Authn' );
    ok( $authn->_check_origin( $authn->{expected_origin}, 'https://www.example.com', 'InvalidAuthentication' ), 'origin array object' );

    my $algs = T::Array->new( -7, -8 );
    my $opts = $authn->generate_registration_options(
        user_name              => 'bob',
        supported_pub_key_algs => $algs,
        exclude_credentials    => T::Array->new({ id => 'YWJj', type => 'public-key' }),
    );
    ok( $opts, 'options with array objects' ) or diag( $authn->error );
    is( scalar( @{ $opts->{pub_key_cred_params} } ), 2, 'algs from array object' );
};

done_testing;

package
    T::Str;  # Hide from MetaCPAN
use overload
    '""' => sub { ${ $_[0] } },
    fallback => 1;
sub new
{
    my( $class, $s ) = @_;
    return( bless( \$s => $class ) );
}

package
    T::Array;
sub new
{
    my $class = shift( @_ );
    return( bless( [ @_ ] => $class ) );
}

__END__
