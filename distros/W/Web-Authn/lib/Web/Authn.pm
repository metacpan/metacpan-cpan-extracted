##----------------------------------------------------------------------------
## WebAuthn - ~/lib/Web/Authn.pm
## Version v0.2.2
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/09/09
## Modified 2026/09/12
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Web::Authn;
BEGIN
{
    use v5.16.0;
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Exporter );
    use vars qw( $VERSION $ERROR $DEBUG $FATAL_EXCEPTIONS $JSON_CLASS @EXPORT_OK );
    use Digest::SHA qw( sha256 );
    use Scalar::Util ();
    use Wanted;
    use Web::Authn::Attestation;
    use Web::Authn::COSE;
    use Web::Authn::Crypto;
    use Web::Authn::Exception;
    use Web::Authn::NullObject;
    use Web::Authn::Parse;
    our @EXPORT_OK = qw(
        generate_registration_options
        verify_registration_response
        generate_authentication_options
        verify_authentication_response
        options_to_json
        base64url_to_bytes
        bytes_to_base64url
        generate_challenge
        generate_user_handle
    );
    # JSON backend detection: prefer Cpanel::JSON::XS (fastest, most rigorous), fall back
    # to JSON::XS, then JSON::PP (core since Perl 5.14).
    our $JSON_CLASS;
    local $@;
    if( eval{ require Cpanel::JSON::XS; 1 } )
    {
        $JSON_CLASS = 'Cpanel::JSON::XS';
    }
    elsif( eval{ require JSON::XS; 1 } )
    {
        $JSON_CLASS = 'JSON::XS';
    }
    else
    {
        require JSON::PP;
        $JSON_CLASS = 'JSON::PP';
    }
    our $VERSION = 'v0.2.2';
};

use strict;
use warnings;

sub new
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my $args  = $this->_get_args_as_hash( @_ );
    $this->_check_known_args( $args, [qw(
        attestation
        debug
        expected_origin
        expected_origins
        expected_rp_id
        fatal
        origin
        origins
        rp_id
        rp_name
        timeout
        user_verification
    )] ) || return( $this->pass_error );

    my $origin = $args->{expected_origin} // $args->{expected_origins} // $args->{origin} // $args->{origins};
    if( ( Scalar::Util::reftype( $origin ) || '' ) eq 'ARRAY' )
    {
        $origin = [ map{ $this->_plain( $_ ) } @$origin ];
    }
    else
    {
        $origin = $this->_plain( $origin );
    }
    my $self = bless({
        rp_id             => $this->_plain( $args->{rp_id} ),
        rp_name           => $this->_plain( $args->{rp_name} ),
        expected_origin   => $origin,
        expected_rp_id    => $this->_plain( $args->{expected_rp_id} || $args->{rp_id} ),
        attestation       => $this->_plain( $args->{attestation} ) || 'none',
        timeout           => defined( $args->{timeout} ) ? 0 + $this->_plain( $args->{timeout} ) : 60_000,
        user_verification => $this->_plain( $args->{user_verification} ) || 'preferred',
        fatal             => defined( $args->{fatal} ) ? ( $this->_plain( $args->{fatal} ) ? 1 : 0 ) : 0,
        debug             => defined( $args->{debug} ) ? ( $this->_plain( $args->{debug} ) ? 1 : 0 ) : 0,
        error             => undef,
    } => $class );
    return( $self );
}

# For option generation
sub base64url_to_bytes
{
    my $self = __PACKAGE__->_instance( \@_ );
    my $str  = Web::Authn::Parse::maybe_bytes( shift( @_ ) );
    local $@;
    my $out = eval { Web::Authn::Parse::b64u_decode( $str ) };
    return( $self->pass_error( $@ ) ) if( $@ );
    return( $out );
}

# For option generation
sub bytes_to_base64url
{
    my $self = __PACKAGE__->_instance( \@_ );
    my $bin  = Web::Authn::Parse::maybe_bytes( shift( @_ ) );
    return( Web::Authn::Parse::b64u_encode( $bin ) );
}

sub error
{
    my $self = shift( @_ );
    $self = __PACKAGE__ unless( defined( $self ) );
    if( @_ )
    {
        require Web::Authn::Exception;
        my $msg;
        my $opts = {};
        if( @_ == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $opts = $_[0];
            $msg  = $opts->{message};
        }
        else
        {
            $msg = join( '', map{ ( ref( $_ ) eq 'CODE' ) ? $_->() : $_ } @_ );
        }
        my $class = $opts->{class} || 'Web::Authn::Exception';
        my $e = $class->new({
            skip_frames => 1,
            message     => ( defined( $msg ) ? $msg : '' ),
            ( defined( $opts->{code} ) ? ( code => $opts->{code} ) : () ),
        });
        $ERROR = $e;
        $self->{error} = $e if( ref( $self ) );
        if( $self->fatal )
        {
            die( $e );
        }
        else
        {
            warn( $e->message ) if( warnings::enabled( 'Web::Authn' ) );
            rreturn( Web::Authn::NullObject->new ) if( want( 'OBJECT' ) );
            return;
        }
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub fatal
{
    my $this = shift( @_ );
    if( @_ )
    {
        if( ref( $this ) )
        {
            return( $this->_set_get_prop( 'fatal', @_ ) );
        }
        else
        {
            warn( "Cannot call fatal in mutator mode as a class method." ) if( warnings::enabled() );
        }
    }
    return( ref( $this ) ? $this->_set_get_prop( 'fatal' ) : $FATAL_EXCEPTIONS );
}

# For option generation
sub generate_authentication_options
{
    my $self = __PACKAGE__->_instance( \@_ );
    my $args = $self->_get_args_as_hash( @_ );
    $self->_check_known_args( $args, [qw(
        allow_credentials
        challenge
        rp_id
        timeout
        user_verification
    )] ) || return( $self->pass_error );
    my $rp_id = $self->_plain( $args->{rp_id} || $self->{rp_id} );
    unless( defined( $rp_id ) && length( $rp_id ) )
    {
        return( $self->error( 'rp_id cannot be an empty string' ) );
    }
    return({
        rp_id             => $rp_id,
        challenge         => defined( $args->{challenge} ) ? Web::Authn::Parse::maybe_bytes( $args->{challenge} ) : Web::Authn::Parse::generate_challenge(),
        timeout           => defined( $args->{timeout} ) ? 0 + $self->_plain( $args->{timeout} ) : ( $self->{timeout} || 60_000 ),
        allow_credentials => $args->{allow_credentials} || [],
        user_verification => $self->_plain( $args->{user_verification} || $self->{user_verification} ) || 'preferred',
    });
}

# For option generation
sub generate_challenge
{
    my $self = __PACKAGE__->_instance( \@_ );
    my $len  = shift( @_ );
    return( Web::Authn::Parse::generate_challenge( $len ) );
}

# For option generation
sub generate_registration_options
{
    my $self = __PACKAGE__->_instance( \@_ );
    my $args = $self->_get_args_as_hash( @_ );
    $self->_check_known_args( $args, [qw(
        attestation
        authenticator_selection
        challenge
        exclude_credentials
        hints
        rp_id
        rp_name
        supported_pub_key_algs
        timeout
        user_display_name
        user_id
        user_name
    )] ) || return( $self->pass_error );
    my $rp_id     = $self->_plain( $args->{rp_id}   || $self->{rp_id} );
    my $rp_name   = $self->_plain( $args->{rp_name} || $self->{rp_name} );
    my $user_name = $self->_plain( $args->{user_name} );
    unless( defined( $rp_id ) && length( $rp_id ) )
    {
        return( $self->error( 'rp_id cannot be an empty string' ) );
    }
    unless( defined( $rp_name ) && length( $rp_name ) )
    {
        return( $self->error( 'rp_name cannot be an empty string' ) );
    }
    unless( defined( $user_name ) && length( $user_name ) )
    {
        return( $self->error( 'user_name cannot be an empty string' ) );
    }

    my $user_id = $args->{user_id};
    if( defined( $user_id ) )
    {
        local $@;
        $user_id = eval { Web::Authn::Parse::maybe_bytes( $user_id ) };
        if( $@ )
        {
            return( $self->error( 'user_id must be bytes' ) );
        }
    }
    else
    {
        $user_id = Web::Authn::Parse::generate_user_handle();
    }

    my @algs = $args->{supported_pub_key_algs}
        ? @{$args->{supported_pub_key_algs}}
        : Web::Authn::COSE::default_supported_algs();

    my $sel = $args->{authenticator_selection};
    if( $sel && ( ( $self->_plain( $sel->{resident_key} ) || '' ) eq 'required' ) )
    {
        $sel->{require_resident_key} = 1;
    }

    return({
        rp => { name => $rp_name, id => $rp_id },
        user => {
            id           => $user_id,
            name         => $user_name,
            display_name => $self->_plain( $args->{user_display_name} ) || $user_name,
        },
        challenge               => defined( $args->{challenge} ) ? Web::Authn::Parse::maybe_bytes( $args->{challenge} ) : Web::Authn::Parse::generate_challenge(),
        pub_key_cred_params     => [ map{ { type => 'public-key', alg => $_ } } @algs ],
        timeout                 => defined( $args->{timeout} ) ? 0 + $self->_plain( $args->{timeout} ) : ( $self->{timeout} || 60_000 ),
        exclude_credentials     => $args->{exclude_credentials} || [],
        attestation             => $self->_plain( $args->{attestation} || $self->{attestation} ) || 'none',
        authenticator_selection => $sel,
        hints                   => $args->{hints},
    });
}

# For option generation
sub generate_user_handle
{
    my $self = __PACKAGE__->_instance( \@_ );
    return( Web::Authn::Parse::generate_user_handle() );
}

# For option generation
sub options_to_json
{
    my $self = __PACKAGE__->_instance( \@_ );
    my $opts = shift( @_ );
    return( Web::Authn::Parse::options_to_json( $opts ) );
}

# For option generation
sub options_to_json_dict
{
    my $self = __PACKAGE__->_instance( \@_ );
    my $opts = shift( @_ );
    return( Web::Authn::Parse::options_to_json_dict( $opts ) );
}

sub pass_error
{
    my $self = shift( @_ );
    $self = __PACKAGE__ unless( defined( $self ) );
    my $pack = ref( $self ) || $self;
    my $opts = {};
    my( $err, $class, $code );
    no strict 'refs';
    if( scalar( @_ ) )
    {
        if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $opts = $_[0];
        }
        else
        {
            if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' )
            {
                $opts = pop( @_ );
            }
            $err = $_[0];
        }
    }
    $err = $opts->{error} if( !defined( $err ) && CORE::exists( $opts->{error} ) && defined( $opts->{error} ) && CORE::length( $opts->{error} ) );
    $class = $opts->{class} if( CORE::exists( $opts->{class} ) && defined( $opts->{class} ) && CORE::length( $opts->{class} ) );
    $code  = $opts->{code} if( CORE::exists( $opts->{code} ) && defined( $opts->{code} ) && CORE::length( $opts->{code} ) );

    if( !defined( $err ) && ( !scalar( @_ ) || defined( $class ) ) )
    {
        my $error = ref( $self ) ? $self->{error} : length( ${ $pack . '::ERROR' } ) ? ${ $pack . '::ERROR' } : undef;
        unless( defined( $error ) )
        {
            warn( "No error object provided and no previous error set either! It seems the previous method call returned a simple undef" );
        }
        else
        {
            $err = ( defined( $class ) ? bless( $error => $class ) : $error );
            $err->code( $code ) if( defined( $code ) && $err->can( 'code' ) );
        }
    }
    elsif( defined( $err ) &&
           Scalar::Util::blessed( $err ) &&
           ( scalar( @_ ) == 1 || ( scalar( @_ ) == 2 && defined( $class ) ) ) )
    {
        $self->{error} = ${ $pack . '::ERROR' } = ( defined( $class ) ? bless( $err => $class ) : $err );
        $self->{error}->code( $code ) if( defined( $code ) && $self->{error}->can( 'code' ) );
        if( ( ref( $self ) && $self->{fatal} ) ||
            ( defined( ${"${pack}::FATAL_EXCEPTIONS"} ) && ${"${pack}::FATAL_EXCEPTIONS"} ) )
        {
            die( $self->{error} );
        }
    }
    else
    {
        return( $self->error( @_ ) );
    }

    if( want( 'OBJECT' ) )
    {
        rreturn( Web::Authn::NullObject->new );
    }
    return;
}

# NOTE: Authentication verification  (WebAuthn §7.2)
sub verify_authentication_response
{
    my $self = __PACKAGE__->_instance( \@_ );
    my $args = $self->_get_args_as_hash( @_ );
    $self->_check_known_args( $args, [qw(
        credential
        credential_current_sign_count
        credential_public_key
        expected_challenge
        expected_origin
        expected_origins
        expected_rp_id
        origin
        origins
        require_user_verification
    )] ) || return( $self->pass_error );
    my $credential         = $args->{credential};
    my $expected_challenge = Web::Authn::Parse::maybe_bytes( $args->{expected_challenge} );
    my $expected_rp_id     = $self->_plain( $args->{expected_rp_id} || $self->{expected_rp_id} || $self->{rp_id} );
    my $expected_origin    = $args->{expected_origin} // $args->{expected_origins} // $args->{origin} // $args->{origins} // $self->{expected_origin};
    my $cred_pk            = Web::Authn::Parse::maybe_bytes( $args->{credential_public_key} );
    my $current_count      = defined( $args->{credential_current_sign_count} ) ? 0 + $self->_plain( $args->{credential_current_sign_count} ) : undef;
    unless( defined( $credential ) && defined( $expected_challenge ) &&
            defined( $expected_rp_id ) && defined( $expected_origin ) &&
            defined( $cred_pk ) && defined( $current_count ) )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', 'missing required verification arguments' ) );
    }

    unless( ref( $credential ) eq 'HASH'
         && $credential->{raw_id}
         && $credential->{response}
         && $credential->{response}->{authenticator_data}
         && $credential->{response}->{signature} )
    {
        local $@;
        $credential = eval { Web::Authn::Parse::parse_authentication_credential_json( $credential ) };
        return( $self->_caught( 'Web::Authn::Exception::InvalidAuthentication' ) ) if( $@ );
    }

    if( Web::Authn::Parse::b64u_encode( $credential->{raw_id} ) ne $credential->{id} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', 'id and raw_id were not equivalent' ) );
    }
    if( ( $credential->{type} || '' ) ne 'public-key' )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', qq{Unexpected credential type "$credential->{type}", expected "public-key"} ) );
    }

    my $client_data_bytes = $credential->{response}->{client_data_json};
    my $auth_data_bytes   = $credential->{response}->{authenticator_data};
    my $signature_bytes   = $credential->{response}->{signature};

    local $@;
    my $client_data = eval { Web::Authn::Parse::parse_client_data_json( $client_data_bytes ) };
    unless( $client_data )
    {
        return( $self->_caught( 'Web::Authn::Exception::InvalidAuthentication', 'clientDataJSON was malformed' ) );
    }
    if( $client_data->{type} ne 'webauthn.get' )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', qq{Unexpected client data type "$client_data->{type}", expected "webauthn.get"} ) );
    }
    if( $expected_challenge ne $client_data->{challenge} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', 'Client data challenge was not expected challenge' ) );
    }
    $self->_check_origin( $expected_origin, $client_data->{origin}, 'InvalidAuthentication' ) || return( $self->pass_error );

    if( my $tb = $client_data->{token_binding} )
    {
        my $st = $tb->{status} || '';
        unless( $st eq 'supported' || $st eq 'present' )
        {
            return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', qq{Unexpected token_binding status of "$st"} ) );
        }
    }

    my $auth = eval { Web::Authn::Parse::parse_authenticator_data( $auth_data_bytes ) };
    unless( $auth )
    {
        return( $self->_caught( 'Web::Authn::Exception::InvalidAuthentication', 'authenticatorData was malformed' ) );
    }
    if( $auth->{rp_id_hash} ne sha256( $expected_rp_id ) )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', 'Unexpected RP ID hash' ) );
    }
    unless( $auth->{flags}->{up} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', 'User was not present during authentication' ) );
    }
    if( $args->{require_user_verification} && !$auth->{flags}->{uv} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', 'User verification is required but user was not verified during authentication' ) );
    }
    if( ( $auth->{sign_count} > 0 || $current_count > 0 ) && $auth->{sign_count} <= $current_count )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidAuthentication', "Response sign count of $auth->{sign_count} was not greater than current count of $current_count" ) );
    }

    my $signature_base = $auth_data_bytes . sha256( $client_data_bytes );
    my $decoded = eval { Web::Authn::Parse::decode_credential_public_key( $cred_pk ) };
    unless( $decoded )
    {
        return( $self->_caught( 'Web::Authn::Exception::InvalidAuthentication', 'credential public key was malformed' ) );
    }
    if( ( $decoded->{kty} || 0 ) == Web::Authn::COSE::KTY_ML_DSA )
    {
        return( $self->_fail( 'Web::Authn::Exception::UnsupportedAlgorithm', 'ML-DSA verification is not implemented in this release' ) );
    }
    eval
    {
        my $pk = Web::Authn::Crypto::cose_to_public_key( $decoded );
        Web::Authn::Crypto::verify_signature(
            public_key => $pk,
            alg        => $decoded->{alg},
            signature  => $signature_bytes,
            data       => $signature_base,
        );
        1;
    } or return( $self->_caught( 'Web::Authn::Exception::InvalidAuthentication', 'Could not verify authentication signature' ) );

    my $backup = eval { Web::Authn::Parse::parse_backup_flags( $auth->{flags} ) };
    return( $self->_caught( 'Web::Authn::Exception::InvalidAuthentication' ) ) if( $@ );
    return({
        credential_id          => $credential->{raw_id},
        new_sign_count         => $auth->{sign_count},
        credential_device_type => $backup->{credential_device_type},
        credential_backed_up   => $backup->{credential_backed_up},
        user_verified          => $auth->{flags}->{uv} ? 1 : 0,
        user_handle            => $credential->{response}->{user_handle},
    });
}

# NOTE: Registration verification  (WebAuthn §7.1)
sub verify_registration_response
{
    my $self = __PACKAGE__->_instance( \@_ );
    my $args = $self->_get_args_as_hash( @_ );
    $self->_check_known_args( $args, [qw(
        credential
        expected_challenge
        expected_origin
        expected_origins
        expected_rp_id
        origin
        origins
        pem_root_certs_bytes_by_fmt
        require_user_presence
        require_user_verification
        supported_pub_key_algs
    )] ) || return( $self->pass_error );
    my $credential         = $args->{credential};
    my $expected_challenge = Web::Authn::Parse::maybe_bytes( $args->{expected_challenge} );
    my $expected_rp_id     = $self->_plain( $args->{expected_rp_id} || $self->{expected_rp_id} || $self->{rp_id} );
    my $expected_origin    = $args->{expected_origin} // $args->{expected_origins} // $args->{origin} // $args->{origins} // $self->{expected_origin};
    unless( defined( $credential ) && defined( $expected_challenge ) &&
            defined( $expected_rp_id ) && defined( $expected_origin ) )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'missing required verification arguments' ) );
    }

    unless( ref( $credential ) eq 'HASH' && $credential->{response} &&
            $credential->{response}->{client_data_json} && $credential->{raw_id} )
    {
        local $@;
        $credential = eval { Web::Authn::Parse::parse_registration_credential_json( $credential ) };
        return( $self->_caught( 'Web::Authn::Exception::InvalidRegistration' ) ) if( $@ );
    }

    if( Web::Authn::Parse::b64u_encode( $credential->{raw_id} ) ne $credential->{id} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'id and raw_id were not equivalent' ) );
    }
    if( ( $credential->{type} || '' ) ne 'public-key' )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', qq{Unexpected credential type "$credential->{type}", expected "public-key"} ) );
    }

    my $client_data_bytes = $credential->{response}->{client_data_json};
    my $att_obj_bytes     = $credential->{response}->{attestation_object};
    local $@;
    my $client_data = eval { Web::Authn::Parse::parse_client_data_json( $client_data_bytes ) };
    unless( $client_data )
    {
        return( $self->_caught( 'Web::Authn::Exception::InvalidRegistration', 'clientDataJSON was malformed' ) );
    }
    if( $client_data->{type} ne 'webauthn.create' )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', qq{Unexpected client data type "$client_data->{type}", expected "webauthn.create"} ) );
    }
    if( $expected_challenge ne $client_data->{challenge} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'Client data challenge was not expected challenge' ) );
    }
    $self->_check_origin( $expected_origin, $client_data->{origin}, 'InvalidRegistration' ) || return( $self->pass_error );

    if( my $tb = $client_data->{token_binding} )
    {
        my $st = $tb->{status} || '';
        unless( $st eq 'supported' || $st eq 'present' )
        {
            return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', qq{Unexpected token_binding status of "$st"} ) );
        }
    }

    my $att = eval { Web::Authn::Parse::parse_attestation_object( $att_obj_bytes ) };
    unless( $att )
    {
        return( $self->_caught( 'Web::Authn::Exception::InvalidRegistration', 'attestationObject was malformed' ) );
    }
    my $auth = $att->{auth_data};
    if( $auth->{rp_id_hash} ne sha256( $expected_rp_id ) )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'Unexpected RP ID hash' ) );
    }
    my $require_up = exists( $args->{require_user_presence} ) ? $args->{require_user_presence} : 1;
    if( $require_up && !$auth->{flags}->{up} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'User presence was required, but was not present during attestation' ) );
    }
    if( $args->{require_user_verification} && !$auth->{flags}->{uv} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'User verification is required but user was not verified during attestation' ) );
    }
    my $acd = $auth->{attested_credential_data};
    unless( $acd )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'Authenticator did not provide attested credential data' ) );
    }
    unless( $acd->{credential_id} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'Authenticator did not provide a credential ID' ) );
    }
    unless( $acd->{credential_public_key} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'Authenticator did not provide a credential public key' ) );
    }
    unless( $acd->{aaguid} )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', 'Authenticator did not provide an AAGUID' ) );
    }

    local $@;
    my $decoded_pk = eval { Web::Authn::Parse::decode_credential_public_key( $acd->{credential_public_key} ) };
    return( $self->_caught( 'Web::Authn::Exception::InvalidRegistration' ) ) if( $@ );

    my @supported = $args->{supported_pub_key_algs}
        ? @{ $args->{supported_pub_key_algs} }
        : ( Web::Authn::COSE::default_supported_algs(),
            Web::Authn::COSE::ECDSA_SHA_384(), Web::Authn::COSE::ECDSA_SHA_512(),
            Web::Authn::COSE::RSASSA_PKCS1_SHA_384(), Web::Authn::COSE::RSASSA_PKCS1_SHA_512(),
            Web::Authn::COSE::RSASSA_PSS_SHA_256(), Web::Authn::COSE::RSASSA_PSS_SHA_384(),
            Web::Authn::COSE::RSASSA_PSS_SHA_512() );
    unless( grep{ $_ == $decoded_pk->{alg} } @supported )
    {
        return( $self->_fail( 'Web::Authn::Exception::InvalidRegistration', qq{Unsupported credential public key alg "$decoded_pk->{alg}"} ) );
    }

    my $pem_roots = [];
    if( $args->{pem_root_certs_bytes_by_fmt} && $args->{pem_root_certs_bytes_by_fmt}->{ $att->{fmt} } )
    {
        $pem_roots = $args->{pem_root_certs_bytes_by_fmt}->{ $att->{fmt} };
    }
    my $ok = eval
    {
        Web::Authn::Attestation::verify(
            fmt => $att->{fmt}, att_stmt => $att->{att_stmt}, auth_raw => $att->{auth_raw},
            attestation_object => $att_obj_bytes, client_data_json => $client_data_bytes,
            credential_public_key => $acd->{credential_public_key}, credential_id => $acd->{credential_id},
            aaguid => $acd->{aaguid}, rp_id_hash => $auth->{rp_id_hash}, pem_root_certs => $pem_roots,
        );
    };
    unless( $ok )
    {
        return( $self->_caught( 'Web::Authn::Exception::InvalidRegistration', 'Attestation statement could not be verified' ) );
    }
    my $backup = eval { Web::Authn::Parse::parse_backup_flags( $auth->{flags} ) };
    return( $self->_caught( 'Web::Authn::Exception::InvalidRegistration' ) ) if( $@ );
    return({
        credential_id          => $acd->{credential_id},
        credential_public_key  => $acd->{credential_public_key},
        sign_count             => $auth->{sign_count},
        aaguid                 => Web::Authn::Parse::aaguid_to_string( $acd->{aaguid} ),
        fmt                    => $att->{fmt},
        credential_type        => 'public-key',
        user_verified          => $auth->{flags}->{uv} ? 1 : 0,
        attestation_object     => $att_obj_bytes,
        credential_device_type => $backup->{credential_device_type},
        credential_backed_up   => $backup->{credential_backed_up},
    });
}

sub _caught
{
    my $self  = shift( @_ );
    my $class = shift( @_ );
    my $fallback = shift( @_ );
    my $err = $@;
    if( Scalar::Util::blessed( $err ) && $err->isa( 'Web::Authn::Exception' ) )
    {
        return( $self->pass_error( $err ) );
    }
    my $msg = defined( $fallback ) && length( $fallback ) ? $fallback : ( defined( $err ) ? "$err" : 'unknown error' );
    $msg =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
    return( $self->_fail( $class || 'Web::Authn::Exception', $msg ) );
}

sub _check_known_args
{
    my $self = shift( @_ );
    my $args = shift( @_ );
    my $ok   = shift( @_ );
    unless( $args && ( ref( $args ) || '' ) eq 'HASH' && $ok && ( Scalar::Util::reftype( $ok ) || '' ) eq 'ARRAY' )
    {
        return( $self->error( 'Internal error: _check_known_args expects a hash of arguments and an array of valid names' ) );
    }
    my %valid = map{ $_ => 1 } @$ok;
    my @unknown = sort( grep{ !exists( $valid{ $_ } ) } keys( %$args ) );
    if( @unknown )
    {
        my $sub = ( caller(1) )[3];
        $sub = 'new' unless( defined( $sub ) && length( $sub ) );
        $sub =~ s/.*:://;
        return( $self->error( sprintf( 'Unknown argument%s passed to %s: %s', ( @unknown > 1 ? 's' : '' ), $sub, join( ', ', map{ qq{'$_'} } @unknown ) ) ) );
    }
    return(1);
}

sub _check_origin
{
    my $self     = shift( @_ );
    my $expected = shift( @_ );
    my $got      = $self->_plain( shift( @_ ) );
    my $kind     = shift( @_ ) || 'InvalidRegistration';
    my $class    = "Web::Authn::Exception::${kind}";
    if( ( Scalar::Util::reftype( $expected ) || '' ) eq 'ARRAY' )
    {
        return(1) if( grep{ $self->_plain( $_ ) eq $got } @$expected );
        return( $self->_fail( $class, qq{Unexpected client data origin "$got"} ) );
    }
    $expected = $self->_plain( $expected );
    if( !ref( $expected ) )
    {
        unless( $expected eq $got )
        {
            return( $self->_fail( $class, qq{Unexpected client data origin "$got", expected "$expected"} ) );
        }
        return(1);
    }
    return( $self->_fail( $class, 'expected_origin must be a string or array of strings' ) );
}

sub _fail
{
    my $self  = shift( @_ );
    my $class = shift( @_ ) || 'Web::Authn::Exception';
    my $msg   = shift( @_ );
    my $e = $class->new({ skip_frames => 2, message => $msg });
    return( $self->pass_error( $e ) );
}

sub _get_args_as_hash
{
    my $self = shift( @_ );
    my $ref = {};
    if( scalar( @_ ) == 1 &&
        defined( $_[0] ) &&
        ( ref( $_[0] ) || '' ) eq 'HASH' )
    {
        $ref = shift( @_ );
    }
    elsif( !( scalar( @_ ) % 2 ) )
    {
        $ref = { @_ };
    }
    else
    {
        Web::Authn::Exception->throw( 'Uneven number of parameters provided.' );
    }
    return( $ref );
}

sub _instance
{
    my $class = shift( @_ );
    my $args  = shift( @_ );
    if( @$args && ref( $args->[0] ) && Scalar::Util::blessed( $args->[0] ) && $args->[0]->isa( 'Web::Authn' ) )
    {
        return( shift( @$args ) );
    }
    if( @$args && defined( $args->[0] ) && !ref( $args->[0] ) && $args->[0] eq 'Web::Authn' )
    {
        shift( @$args );
        return( $class->new );
    }
    return( $class->new );
}


sub _plain
{
    my $self = shift( @_ );
    return( Web::Authn::Parse::_plain( shift( @_ ) ) );
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    $self->{ $key } = shift( @_ ) if( @_ );
    return( $self->{ $key } );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Web::Authn - Server-side WebAuthn / passkeys

=head1 SYNOPSIS

    use Web::Authn;

    my $authn = Web::Authn->new(
        rp_id           => 'example.com',
        rp_name         => 'Example Co',
        expected_origin => 'https://example.com',
    );

    my $opts = $authn->generate_registration_options(
        user_name         => 'bob',
        user_display_name => 'Bob',
    ) || die( $authn->error );

    my $json = $authn->options_to_json( $opts );   # send to the browser

    my $reg = $authn->verify_registration_response(
        credential         => $browser_json,
        expected_challenge => $opts->{challenge},
    ) || die( $authn->error );
    # persist $reg->{credential_id}, $reg->{credential_public_key}, $reg->{sign_count}

    my $assert_opts = $authn->generate_authentication_options(
        allow_credentials => [
            { type => 'public-key', id => $reg->{credential_id} },
        ],
    ) || die( $authn->error );

    my $ok = $authn->verify_authentication_response(
        credential                    => $browser_json,
        expected_challenge            => $assert_opts->{challenge},
        credential_public_key         => $reg->{credential_public_key},
        credential_current_sign_count => $reg->{sign_count},
    ) || die( $authn->error );

    $authn->fatal(1);   # subsequent errors die() as exception objects

Functional wrappers still exist (they build a temporary object):

    use Web::Authn qw( generate_registration_options options_to_json );

=head1 VERSION

    v0.2.2

=head1 DESCRIPTION

C<Web::Authn> is a Perl port of Duo Labs' L<py_webauthn|https://github.com/duo-labs/py_webauthn>.
It implements the Relying Party operations of the W3C WebAuthn Level 2/3 specifications: option generation and cryptographic verification of registration and authentication ceremonies.

Methods return, C<undef> in scalar context or an empty list in list context, on failure and store a L<Web::Authn::Exception> on the object and in C<< Web::Authn->error >>. They C<die> only when L</fatal>
is true.

Functional wrappers remain exported on request and dispatch to a temporary object.

See L<Web::Authn::Cookbook> for integration.

It is not a user/session framework. You store challenges, credential IDs, COSE public keys and signature counters yourself.

The usual integration is four JSON endpoints: register/begin, register/complete, login/begin, login/complete. See the distribution F<README.md> for a full walk-through, storage schema, and frontend notes.

=head1 EXPORTS

Nothing is exported by default. Request what you need:

    use Web::Authn qw(
        generate_registration_options
        verify_registration_response
        generate_authentication_options
        verify_authentication_response
        options_to_json
        options_to_json_dict
        base64url_to_bytes
        bytes_to_base64url
        generate_challenge
        generate_user_handle
    );

=head1 METHODS

Named parameters may be passed either as a flat list or as a single hash reference. Both of the following are equivalent:

    $authn->generate_registration_options( rp_id => $id, user_name => $name );
    $authn->generate_registration_options({ rp_id => $id, user_name => $name });

An odd number of list elements throws L<Web::Authn::Exception>.

String arguments may be plain Perl scalars or blessed objects that overload stringification (C<< overload::Method( $obj, '""' ) >>), for example L<Module::Generic::Scalar>. They are converted with C<< $obj . '' >> before use.

Array arguments (such as origins, algorithm lists, credential descriptors) may be a native array reference or a blessed array whose C<reftype> is C<ARRAY>, for example L<Module::Generic::Array>.

=head2 new

    my $authn = Web::Authn->new(
        rp_id             => 'example.com',
        rp_name           => 'Example Co',
        expected_origin   => 'https://example.com',
        expected_rp_id    => 'example.com',   # defaults to rp_id
        attestation       => 'none',
        timeout           => 60_000,
        user_verification => 'preferred',
        fatal             => 0,
    );

    my $authn = Web::Authn->new({
        rp_id           => 'example.com',
        rp_name         => 'Example Co',
        expected_origin => 'https://example.com',
    }) || die( Web::Authn->error );

    my $authn = Web::Authn->new(
        rp_id   => 'example.com',
        rp_name => 'Angels, Inc',
        origins => [ 'https://www.angels-inc.com' ],
        timeout => 120_000,
        debug   => 1,
    ) || die( Web::Authn->error );

Stores Relying Party defaults used by later methods. If C<new> is called on an existing instance, a failure stores the error on that instance so the caller can write C<< $authn->new( %args ) || die( $authn->error ) >>.

Supported options are:

=over

=item C<attestation>

Optional. String. One of C<none>, C<indirect>, C<direct>, or C<enterprise>. Default C<none>. Conveyance preference copied onto options produced by L</generate_registration_options>.

=item C<debug>

Optional. Boolean. Default false. Stored on the object for the caller; it does not change WebAuthn verification.

=item C<expected_origin>

Optional at construction, required later by L</verify_registration_response> and L</verify_authentication_response> unless passed there. String (a full origin such as C<https://example.com>) or array of such strings. Compared to C<clientDataJSON.origin>.

=item C<expected_origins>

Optional. Alias of C<expected_origin>. Same type.

=item C<expected_rp_id>

Optional. String. Effective RP ID used during verification. Defaults to C<rp_id>.

=item C<fatal>

Optional. Boolean. Default false. When true, L</error> throws the exception instead of returning C<undef>. See L</fatal>.

=item C<origin>

Optional. Alias of C<expected_origin>. Same type.

=item C<origins>

Optional. Alias of C<expected_origin>. Same type. Useful when the application config key is plural.

=item C<rp_id>

Optional at construction, required (here or on the call) by L</generate_registration_options> and L</generate_authentication_options>. String. Registrable domain of the Relying Party, for example C<example.com>. Must match the RP ID hash inside authenticator data.

=item C<rp_name>

Optional at construction, required (here or on the call) by L</generate_registration_options>. String. Human-readable Relying Party name shown by the authenticator UI.

=item C<timeout>

Optional. Integer. Milliseconds. Default C<60000>. Hint copied onto generated options.

=item C<user_verification>

Optional. String. One of C<required>, C<preferred>, or C<discouraged>. Default C<preferred>. Copied onto generated options.

=back

=head2 base64url_to_bytes

    my $raw = $authn->base64url_to_bytes( $credential->{id} ) ||
        die( $authn->error );

Decodes unpadded base64url to raw bytes. The only argument is the string to decode (characters C<A-Za-z0-9_->). You may also pass an object that overloads stringification, such as L<Module::Generic::Scalar>.

=head2 bytes_to_base64url

    my $id = $authn->bytes_to_base64url( $reg->{credential_id} );

Encodes raw bytes as unpadded base64url. The only argument is the byte string to encode. You may also pass an object that overloads stringification.

=head2 error

    my $authn = Web::Authn->new( %bad_args );
    if( !defined( $authn ) )
    {
        my $err = Web::Authn->error;
        warn "Error: $err";
    }

    my $err = $authn->error;
    warn $err->message, ' at ', $err->file, ' line ', $err->line;

    $authn->error( 'something went wrong' );
    $authn->error({ class => 'Web::Authn::Exception::InvalidRegistration', message => 'bad' });

Instance and class method. When called with a message, constructs a L<Web::Authn::Exception> object, stores it internally, and either warns (if C<fatal> mode is off) or C<die>s (if C<fatal> mode is on). Returns C<undef> in scalar context, an empty list in list context.

When called without arguments, returns the most recent error object (or C<undef> if no error has occurred).

=over

=item C<class>

This key is optional. It is a string naming the exception class to bless into, and it defaults to C<Web::Authn::Exception>.

=item C<message>

This key is optional when you pass a hash (the sole positional string is treated as the message). It is the human-readable error text.

=item C<skip_frames>

This key is optional. It is an integer: how many extra C<caller> frames to skip when recording file and line.

=back

=head2 fatal

    $authn->fatal(1); # Enable fatal exceptions
    $authn->fatal(0); # Disable fatal exceptions
    my $bool = $authn->fatal;

Sets or get the boolean value, whether to die upon exception, or not. If set to true, then instead of setting an L<exception object|Web::Authn::Exception>, this module will die with an L<exception object|Web::Authn::Exception>. You can catch the exception object then after using C<try>. For example:

    use v.5.34; # to be able to use try-catch blocks in perl
    use experimental 'try';
    no warnings 'experimental';
    try
    {
        my $authn = Web::Authn->new( fatal => 1 );
        # Forgot the 'rp_id':
        my $bad = $authn->generate_registration_options( rp_id => '', rp_name => 'x', user_name => 'y' );
    }
    catch( $e )
    {
        say "Error occurred: ", $e->message;
        # Error occurred: No value for width was provided.
    }

Called with a boolean, this method sets whether subsequent L</error> calls throw. Called without arguments, it returns the current flag.

=head2 generate_registration_options

    my $opts = $authn->generate_registration_options(
        user_name               => 'bob@example.com',
        user_id                 => $handle,          # raw bytes; optional
        user_display_name       => 'Bob',
        challenge               => $bytes,           # optional
        timeout                 => 60_000,
        attestation             => 'none',
        exclude_credentials     => [ { type => 'public-key', id => $cid } ],
        supported_pub_key_algs  => [ -8, -7, -257 ],
        authenticator_selection => {
            resident_key      => 'preferred',
            user_verification => 'preferred',
        },
        hints => [ 'client-device' ],
    ) || die( $authn->error );

    my $opts = $authn->generate_registration_options({
        user_name => 'bob@example.com',
        user_id   => $handle,
    }) || die( $authn->error );

Returns a Perl hash describing C<PublicKeyCredentialCreationOptions>.

Pass it through L</options_to_json> before sending it to the browser.

An empty C<rp_id>, C<rp_name>, or C<user_name> is rejected via L</error>.

=over

=item C<attestation>

This argument is optional. It is a string, one of C<none>, C<indirect>, C<direct>, or C<enterprise>. It defaults to the value stored by L</new>, or to C<none>. It is the conveyance preference placed on the creation options.

=item C<authenticator_selection>

This argument is optional. It is a hash. Recognised keys are C<authenticator_attachment> (the string C<platform> or C<cross-platform>), C<resident_key> (C<discouraged>, C<preferred>, or C<required>), and C<user_verification> (C<required>, C<preferred>, or C<discouraged>). If C<resident_key> is C<required>, C<require_resident_key> is also set to true on the options.

=item C<challenge>

This argument is optional. It is a raw byte string: the cryptographic challenge issued to the authenticator. It defaults to 64 CSPRNG bytes from L</generate_challenge>. Store this value until you call L</verify_registration_response>.

=item C<exclude_credentials>

This argument is optional. It is an array of descriptor hashes of the form C<{ type => 'public-key', id => $raw_bytes, transports => [ ... ] }>, where C<id> is raw bytes. It prevents re-registration of authenticators the account already has.

=item C<hints>

This argument is optional. It is an array of strings: WebAuthn Level 3 UI hints, one or more of C<security-key>, C<client-device>, and C<hybrid>.

=item C<rp_id>

This argument is required unless it was already set on the object by L</new>. It is a string: the registrable domain of the Relying Party.

=item C<rp_name>

This argument is required unless it was already set on the object by L</new>. It is a string: the human-readable Relying Party name.

=item C<supported_pub_key_algs>

This argument is optional. It is an array of integers (COSE algorithm identifiers). It defaults to EdDSA (C<-8>), ES256 (C<-7>), and RS256 (C<-257>). Constants live in L<Web::Authn::COSE>.

=item C<timeout>

This argument is optional. It is an integer number of milliseconds. It defaults to the value stored by L</new>, or to C<60000>. It is a client-side hint only.

=item C<user_display_name>

This argument is optional. It is a string shown in the OS passkey UI. It defaults to C<user_name>.

=item C<user_id>

This argument is optional. It is raw bytes identifying the account to the authenticator, and it must B<not> be an email or other personal information. It defaults to 64 random bytes from L</generate_user_handle>. Keep this value stable for the life of the account.

=item C<user_name>

This argument is required. It is a string: the account identifier shown to the user, often an email or login.

=back

=head2 generate_authentication_options

    my $opts = $authn->generate_authentication_options(
        allow_credentials => [ { type => 'public-key', id => $cid } ],
        user_verification => 'preferred',
        timeout           => 60_000,
        challenge         => $bytes,      # optional
    ) || die( $authn->error );

    # usernameless / discoverable:
    my $opts = $authn->generate_authentication_options;

    my $opts = $authn->generate_authentication_options({
        allow_credentials => [ { type => 'public-key', id => $cid } ],
    }) || die( $authn->error );

Returns C<PublicKeyCredentialRequestOptions>. Pass it through L</options_to_json> before sending it to the browser. An empty C<rp_id> is rejected via L</error>.

=over

=item C<allow_credentials>

This argument is optional. It is an array of descriptor hashes of the form C<{ type => 'public-key', id => $raw_bytes, transports => [ ... ] }>, where C<id> is raw bytes. Omit it or pass C<[]> for usernameless (discoverable) credentials.

=item C<challenge>

This argument is optional. It is a raw byte string: the cryptographic challenge issued to the authenticator. It defaults to 64 CSPRNG bytes from L</generate_challenge>. Store this value until you call L</verify_authentication_response>.

=item C<rp_id>

This argument is required unless it was already set on the object by L</new>. It is a string: the registrable domain of the Relying Party.

=item C<timeout>

This argument is optional. It is an integer number of milliseconds. It defaults to the value stored by L</new>, or to C<60000>. It is a client-side hint only.

=item C<user_verification>

This argument is optional. It is a string, one of C<required>, C<preferred>, or C<discouraged>. It defaults to the value stored by L</new>, or to C<preferred>.

=back

=head2 generate_challenge

    my $chal = $authn->generate_challenge;      # 64 bytes
    my $chal = $authn->generate_challenge(16);

Returns raw challenge bytes from L<Bytes::Random::Secure>. You may pass an optional integer length; it defaults to 64.

=head2 generate_user_handle

    my $handle = $authn->generate_user_handle;  # 64 random bytes

Returns 64 raw random bytes suitable as a WebAuthn C<user.id>. No arguments.

=head2 options_to_json

    print $authn->options_to_json( $opts );

Serialises registration or authentication options to a JSON string suitable for C<Content-Type: application/json>. Byte fields (C<challenge>, C<user.id>, descriptor C<id>) become unpadded base64url. Keys are camelCase as the WebAuthn spec uses them. The only argument is the hash returned by L</generate_registration_options> or L</generate_authentication_options>.

=head2 options_to_json_dict

    my $href = $authn->options_to_json_dict( $opts );

Same conversion as L</options_to_json>, but returns a hash instead of a JSON string. The only argument is the same options hash.

=head2 pass_error

    sub my_method
    {
        my $self = shift( @_ );
        my $authn = Web::Authn->new( %bad_args ) ||
            return( $self->pass_error( Web::Authn->error ) );
        ...
    }

Propagates the error stored in another object (or the class-level error) into the current object's error slot, without constructing a new exception. Used internally when a lower-level call fails and the caller wants to surface the same error to its own caller.

=head2 verify_registration_response

    my $reg = $authn->verify_registration_response(
        credential                    => $browser_json,
        expected_challenge            => $opts->{challenge},
        expected_rp_id                => 'example.com',   # default: new()
        expected_origin               => 'https://example.com',
        require_user_presence         => 1,
        require_user_verification     => 0,
        supported_pub_key_algs        => [ -8, -7, -257 ],
        pem_root_certs_bytes_by_fmt   => { packed => [ $pem ] },
    ) || die( $authn->error );

    my $reg = $authn->verify_registration_response({
        credential         => $browser_json,
        expected_challenge => $opts->{challenge},
        expected_rp_id     => 'example.com',
        expected_origin    => 'https://example.com',
    }) || die( $authn->error );

Implements WebAuthn §7.1.

On success returns a hash of fields to persist (see below).

On failure stores L<Web::Authn::Exception::InvalidRegistration>, and returns C<undef> in scalar context or an empty list in list context, unless L</fatal> is true.

Supported options are:

=over

=item C<credential>

This argument is required. It is either a JSON string, or a hash in the SimpleWebAuthn / py_webauthn shape (C<id>, C<rawId>, C<type>, C<response.clientDataJSON>, C<response.attestationObject> as unpadded base64url). This is the value returned by C<navigator.credentials.create()>.

=item C<expected_challenge>

This argument is required. It is a raw byte string: the challenge previously issued by L</generate_registration_options>. It must match C<clientDataJSON.challenge>.

=item C<expected_origin>

This argument is required unless it was already set on the object by L</new>. It is either a string containing a full origin such as C<https://example.com>, or an array of such strings. It must match C<clientDataJSON.origin>.

=item C<expected_origins>

This argument is optional. It is an alias of C<expected_origin> and accepts the same values.

=item C<expected_rp_id>

This argument is required unless it was already set on the object by L</new> (as C<expected_rp_id> or C<rp_id>). It is a string: the registrable domain. Its SHA-256 must equal the RP ID hash in authenticator data.

=item C<origin>

This argument is optional. It is an alias of C<expected_origin> and accepts the same values.

=item C<origins>

This argument is optional. It is an alias of C<expected_origin> and accepts the same values.

=item C<pem_root_certs_bytes_by_fmt>

This argument is optional. It is a hash mapping an attestation format name (for example C<packed> or C<fido-u2f>) to an array of PEM or DER root certificates (strings or raw bytes). It is used when verifying packed or FIDO U2F statements that carry an C<x5c>. It is unused for C<fmt=none>.

=item C<require_user_presence>

This argument is optional. It is a boolean and defaults to true. When it is true, authenticator data must have the User Present (UP) flag set.

=item C<require_user_verification>

This argument is optional. It is a boolean and defaults to false. When it is true, authenticator data must have the User Verified (UV) flag set.

=item C<supported_pub_key_algs>

This argument is optional. It is an array of integers (COSE algorithm identifiers). It restricts which credential public-key algorithms are accepted. The default includes the L<Web::Authn::COSE> defaults plus ES384, ES512, RS384, RS512, PS256, PS384 and PS512.

=back

Returns a hash:

    credential_id            raw bytes
    credential_public_key    COSE_Key bytes (store as-is)
    sign_count               integer
    aaguid                   UUID string
    fmt                      attestation format
    credential_type          "public-key"
    user_verified            0/1
    attestation_object       raw bytes
    credential_device_type   "singleDevice" | "multiDevice"
    credential_backed_up     0/1

=head2 verify_authentication_response

    my $ok = $authn->verify_authentication_response(
        credential                    => $browser_json,
        expected_challenge            => $opts->{challenge},
        expected_rp_id                => 'example.com',
        expected_origin               => 'https://example.com',
        credential_public_key         => $row->{public_key},
        credential_current_sign_count => $row->{sign_count},
        require_user_verification     => 0,
    ) || die( $authn->error );

    my $ok = $authn->verify_authentication_response({
        credential                    => $browser_json,
        expected_challenge            => $opts->{challenge},
        credential_public_key         => $row->{public_key},
        credential_current_sign_count => $row->{sign_count},
    }) || die( $authn->error );

Implements WebAuthn §7.2. On success returns a hash (see below). On failure returns C<undef> and stores L<Web::Authn::Exception::InvalidAuthentication> unless L</fatal> is true.

The signature counter must strictly increase when either the stored or reported count is non-zero; otherwise the response is rejected as a possible cloned authenticator.

=over

=item C<credential>

This argument is required. It is either a JSON string, or a hash in the SimpleWebAuthn / py_webauthn shape (C<id>, C<rawId>, C<type>, C<response.clientDataJSON>, C<response.authenticatorData>, C<response.signature> as unpadded base64url). This is the value returned by C<navigator.credentials.get()>.

=item C<credential_current_sign_count>

This argument is required. It is an integer: the C<sign_count> last persisted for this credential. It is compared to the counter in authenticator data.

=item C<credential_public_key>

This argument is required. It is raw bytes: the C<credential_public_key> COSE_Key blob returned by L</verify_registration_response> and stored as-is.

=item C<expected_challenge>

This argument is required. It is a raw byte string: the challenge previously issued by L</generate_authentication_options>. It must match C<clientDataJSON.challenge>.

=item C<expected_origin>

This argument is required unless it was already set on the object by L</new>. It is either a string containing a full origin such as C<https://example.com>, or an array of such strings. It must match C<clientDataJSON.origin>.

=item C<expected_origins>

This argument is optional. It is an alias of C<expected_origin> and accepts the same values.

=item C<expected_rp_id>

This argument is required unless it was already set on the object by L</new> (as C<expected_rp_id> or C<rp_id>). It is a string: the registrable domain. Its SHA-256 must equal the RP ID hash in authenticator data.

=item C<origin>

This argument is optional. It is an alias of C<expected_origin> and accepts the same values.

=item C<origins>

This argument is optional. It is an alias of C<expected_origin> and accepts the same values.

=item C<require_user_verification>

This argument is optional. It is a boolean and defaults to false. When it is true, authenticator data must have the User Verified (UV) flag set.

=back

Returns:

    credential_id            raw bytes
    new_sign_count           persist this
    credential_device_type
    credential_backed_up
    user_verified
    user_handle              bytes or undef

=head2 error

    my $authn = Web::Authn->new( %bad_args );
    if( !defined( $authn ) )
    {
        my $err = Web::Authn->error;
        warn "Error: $err";
    }

Instance and class method. When called with a message, constructs a L<Web::Authn::Exception> object, stores it internally, and either warns (if C<fatal> mode is off) or C<die>s (if C<fatal> mode is on). Returns C<undef> in scalar context, an empty list in list context.

When called without arguments, returns the most recent error object (or C<undef> if no error has occurred).

=head2 fatal

    $authn->fatal(1); # Enable fatal exceptions
    $authn->fatal(0); # Disable fatal exceptions
    my $bool = $authn->fatal;

Sets or get the boolean value, whether to die upon exception, or not. If set to true, then instead of setting an L<exception object|Web::Authn::Exception>, this module will die with an L<exception object|Web::Authn::Exception>. You can catch the exception object then after using C<try>. For example:

    use v.5.34; # to be able to use try-catch blocks in perl
    use experimental 'try';
    no warnings 'experimental';
    try
    {
        my $authn = Web::Authn->new( fatal => 1 );
        # Forgot the 'rp_id':
        my $bad = $authn->generate_registration_options( rp_id => '', rp_name => 'x', user_name => 'y' );
    }
    catch( $e )
    {
        say "Error occurred: ", $e->message;
        # Error occurred: No value for width was provided.
    }

=head2 pass_error

    sub my_method
    {
        my $self = shift( @_ );
        my $authn = Web::Authn->new( %bad_args ) ||
            return( $self->pass_error( Web::Authn->error ) );
        ...
    }

Propagates the error stored in another object (or the class-level error) into the current object's error slot, without constructing a new exception. Used internally when a lower-level call fails and the caller wants to surface the same error to its own caller.

=head1 ATTESTATION FORMATS

L<Web::Authn::Parse/parse_attestation_object> decodes the CBOR C<attestationObject> into C<fmt>, C<authData> and C<attStmt>. L<Web::Authn::Attestation/verify> then dispatches on the C<fmt> argument (C<none>, C<packed>, C<fido-u2f>, C<apple>, C<tpm>, C<android-safetynet>, C<android-key>). That package has no C<attestationObject> field; C<fmt> is a named parameter.

=over

=item C<none>

Statement must be empty. Typical for consumer passkeys.

=item C<packed>

Signature over C<authData || SHA-256(clientDataJSON)>. Self-attestation uses the credential public key; C<x5c> uses the leaf certificate (optional root pinning).

=item C<fido-u2f>

U2F C<verificationData>, P-256, AAGUID all zeros.

=item C<apple>

C<x5c>, nonce in OID C<1.2.840.113635.100.8.2>, subject public key matches the credential key. Pass Apple's WebAuthn root via C<pem_root_certs_bytes_by_fmt>.

=item C<tpm>

C<x5c>, signature over C<certInfo>, C<extraData> contains a hash of C<attToBeSigned>.

=item C<android-safetynet>

JWT signature, C<ctsProfileMatch>, nonce.

=item C<android-key>

C<x5c> plus packed-style signature.

=back

Certificate chains against RP-supplied roots are validated B<in process> (CryptX verifies each certificate signature). There is no C<openssl(1)> subprocess. If you pass no roots, pinning is skipped (same as py_webauthn).

=head1 COSE ALGORITHMS

Verified with L<CryptX>: ES256/384/512, Ed25519 (EdDSA), RS256/384/512, PS256/384/512.

ML-DSA (-48/-49/-50) keys can be decoded; verification is not implemented.

=head1 EXCEPTIONS

See L<Web::Authn::Exception>. Generation of empty C<rp_id> etc. uses L<Carp/croak> instead.

=head1 DEPENDENCIES

L<CryptX>, L<Bytes::Random::Secure>, and core L<Digest::SHA>, L<JSON::PP>, L<MIME::Base64>.

=head1 REFERENCES

Normative documents this module is written against. Dated REC links are pinned; undated C</TR/webauthn-3/> always resolves to the latest published Level 3.

=head2 WebAuthn (W3C) — browser API and RP procedures

=over

=item Level 3 Recommendation (25 August 2026) — current

L<https://www.w3.org/TR/webauthn-3/>

Pinned: L<https://www.w3.org/TR/2026/REC-webauthn-3-20260825/>

RP registration procedure: L<https://www.w3.org/TR/webauthn-3/#sctn-registering-a-new-credential> (§7.1)

RP authentication procedure: L<https://www.w3.org/TR/webauthn-3/#sctn-verifying-assertion> (§7.2)

Attestation statement formats: L<https://www.w3.org/TR/webauthn-3/#sctn-defined-attestation-formats> (§8)

Editor's Draft (next level): L<https://w3c.github.io/webauthn/>

Working Group repo: L<https://github.com/w3c/webauthn>

=item Level 2 Recommendation (8 April 2021)

L<https://www.w3.org/TR/webauthn-2/>

Pinned: L<https://www.w3.org/TR/2021/REC-webauthn-2-20210408/>

=item Level 1 Recommendation (4 March 2019)

L<https://www.w3.org/TR/webauthn-1/>

Pinned: L<https://www.w3.org/TR/2019/REC-webauthn-1-20190304/>

=back

C<verify_registration_response> implements §7.1.
C<verify_authentication_response> implements §7.2.

=head2 CTAP / FIDO2 — authenticator protocol

WebAuthn is the web API. CTAP is how the platform talks to the authenticator (USB, NFC, BLE, hybrid). Together they are FIDO2.

=over

=item CTAP 2.2 Proposed Standard (28 February 2025)

L<https://fidoalliance.org/specs/fido-v2.2-ps-20250228/fido-client-to-authenticator-protocol-v2.2-ps-20250228.html>

=item CTAP 2.1 Proposed Standard

L<https://fidoalliance.org/specs/fido-v2.1-ps-20210615/fido-client-to-authenticator-protocol-v2.1-ps-20210615.html>

=item CTAP 2.0 (27 February 2018)

L<https://fidoalliance.org/specs/fido-v2.0-id-20180227/fido-client-to-authenticator-protocol-v2.0-id-20180227.html>

=item FIDO Alliance specifications index

L<https://fidoalliance.org/specifications/>

=item ITU-T X.1278 (CTAP aligned)

L<https://www.itu.int/rec/T-REC-X.1278>

=back

=head2 Encoding and algorithms

=over

=item RFC 8949 — CBOR

L<https://www.rfc-editor.org/rfc/rfc8949.html>

=item RFC 8610 — CDDL

L<https://www.rfc-editor.org/rfc/rfc8610.html>

=item RFC 9052 / 9053 — COSE

L<https://www.rfc-editor.org/rfc/rfc9052.html>

L<https://www.rfc-editor.org/rfc/rfc9053.html>

=item RFC 8812 — COSE/JOSE registrations used by WebAuthn (RS256 etc.)

L<https://www.rfc-editor.org/rfc/rfc8812.html>

=item IANA COSE Algorithms registry

L<https://www.iana.org/assignments/cose/cose.xhtml#algorithms>

=item IANA COSE Key Types / Elliptic Curves

L<https://www.iana.org/assignments/cose/cose.xhtml>

=item RFC 5280 — X.509 (attestation C<x5c>)

L<https://www.rfc-editor.org/rfc/rfc5280.html>

=item RFC 4648 §5 — base64url

L<https://www.rfc-editor.org/rfc/rfc4648.html#section-5>

=back

=head2 Related

=over

=item FIDO Alliance — passkeys overview

L<https://fidoalliance.org/passkeys/>

=item py_webauthn (API this port mirrors)

L<https://github.com/duo-labs/py_webauthn>

=back

=head1 THREAD & PROCESS SAFETY

C<Web::Authn> is designed to be fully thread-safe and process-safe, ensuring data integrity across Perl ithreads and mod_perl’s threaded Multi-Processing Modules (MPMs) such as Worker or Event, provided each thread constructs and uses its own objects. Do not pass a C<Web::Authn> instance, a L<CryptX> key object, or a L<Bytes::Random::Secure> generator across C<< threads->create >>.

Perl ithreads clone the interpreter. Package variables such as C<$Web::Authn::ERROR> and C<$JSON_CLASS> are copied, then independent. They are not C<:shared>. That is the intended model: each thread has its own last-error slot.

What is not safe to share:

=over

=item *

A blessed C<Web::Authn> object created in another thread. Create it inside the worker (C<< Web::Authn->new( ... ) >> after C<< threads->create >>, or in a prefork child after C<fork>).

=item *

CryptX public-key objects returned by L<Web::Authn::Crypto>. Persist COSE public-key B<bytes> in the database and rebuild the key in the thread that verifies.

=item *

A cached C<Bytes::Random::Secure> object. L<Web::Authn::Parse/_random> therefore constructs a new generator for every challenge or user handle. Do not add a process-wide singleton.

=back

JSON backends (L<Cpanel::JSON::XS>, L<JSON::XS>, L<JSON::PP>) are used by creating a new coder per call (C<< $JSON_CLASS->new >>). Do not stash a coder object in a package global.

Typical prefork servers (C<Starman>, C<Hypnotoad>, Apache prefork + mod_perl) start workers after compile. Each worker is a separate process, not an ithread; no extra care is required beyond not sharing memory on purpose.

Typical ithreads pattern:

    use threads;
    my $thr = threads->create(sub
    {
        my $authn = Web::Authn->new(
            rp_id           => 'example.com',
            expected_origin => 'https://example.com',
        );
        my $opts = $authn->generate_registration_options(
            user_name => 'bob',
        ) || die( $authn->error );
        return( $opts->{challenge} );
    });
    my $challenge = $thr->join;

C<fork()> without exec: avoid calling generate/verify in the parent and the child with the same in-memory L<CryptX> object. Rebuild from stored bytes in the child.

=head1 CREDITS

Duo Labs / Matthew Miller for his work on the Python's C<py_webauthn>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Web::Authn::Cookbook>,
L<Web::Authn::Parse>, L<Web::Authn::Attestation>, L<Web::Authn::Crypto>,
L<Web::Authn::COSE>, L<Web::Authn::CBOR>, L<Web::Authn::Exception>,
L<Authen::WebAuthn>

L<https://github.com/duo-labs/py_webauthn>,
L<https://www.w3.org/TR/webauthn-3/>,
L<Authen::WebAuthn>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
