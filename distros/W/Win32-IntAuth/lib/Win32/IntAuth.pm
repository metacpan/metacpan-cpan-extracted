package Win32::IntAuth;

use strict;
use warnings;

require Exporter;

our $VERSION = '0.20';
our @ISA = qw(Exporter);

use Win32;
use Win32::API;

=head1 NAME

Win32::IntAuth - Perl extension for implementing
basic Windows Integrated Authentication

=head1 SYNOPSIS

  # at client:
  use Win32::IntAuth;
  my $auth  = Win32::IntAuth->new();

  # create a user token intended for the user the server process is running as
  my $token = $auth->create_token('my_service_user@my_domain.org')
    or die "couldn't create auth token, ", $auth->last_err_txt();
  # now transfer the token to the server process


  # at server:
  # receive the token from client, then:

  use Win32::IntAuth;
  my $auth  = Win32::IntAuth->new();

  # the service user will need the user rights
  # SeAssignPrimaryTokenPrivilege and SeImpersonatePrivilege
  # and needs to be trusted for delegation in ActiveDirectory

  # impersonate the user that created the token
  $auth->impersonate($token)
      or die "couldn't impersonate user, ", $auth->last_err_txt();

  print 'Hooray user ', $auth->get_username(), " authenticated!\n";

  # now do something as the impersonated user

  # revert back to standard server context
  $auth->revert()

=head1 DESCRIPTION

This module encapsulates (with Win32::API) the SSPI-API functions that are necessary
to authenticate and impersonate remote users from an already existing
session without additional specification of username and password.

The module does not handle transport of the created user token to the
server process or service nor does it provise routines for further
evaluation of user rights or group memberships.

The outline provided in the synopsis should be enough to get you
started. For details please look at the SSPI docs.

L<Link to SSPI docs|http://msdn2.microsoft.com/en-us/library/aa380493.aspx> (as of 5/2008)

=head2 EXPORT

None by default. Only for calling the SSPI functions directly
via C<_sspi_call()> the constants can be imported with:

  use Win32::IntAuth qw/:constants/;

But to do that you will have to look at the implementation.
May the source be with you :-).

=cut

# constants
my %err_txt;
my %constant_hash;

BEGIN {

    %constant_hash = (
        SECBUFFER_EMPTY                   => 0x00000000,
        SECBUFFER_DATA                    => 0x00000001,
        SECBUFFER_TOKEN                   => 0x00000002,
        SECBUFFER_PKG_PARAMS              => 0x00000003,
        SECBUFFER_MISSING                 => 0x00000004,
        SECBUFFER_EXTRA                   => 0x00000005,
        SECBUFFER_STREAM_TRAILER          => 0x00000006,
        SECBUFFER_STREAM_HEADER           => 0x00000007,
        SECBUFFER_NEGOTIATION_INFO        => 0x00000008,

        SECURITY_NATIVE_DREP              => 0x00000010,
        SECURITY_NETWORK_DREP             => 0x00000000,

        SECPKG_CRED_INBOUND               => 0x00000001,
        SECPKG_CRED_OUTBOUND              => 0x00000002,
        SECPKG_CRED_BOTH                  => 0x00000003,

        ISC_REQ_DELEGATE                  => 0x00000001,
        ISC_REQ_MUTUAL_AUTH               => 0x00000002,
        ISC_REQ_REPLAY_DETECT             => 0x00000004,
        ISC_REQ_SEQUENCE_DETECT           => 0x00000008,
        ISC_REQ_CONFIDENTIALITY           => 0x00000010,
        ISC_REQ_USE_SESSION_KEY           => 0x00000020,
        ISC_REQ_PROMPT_FOR_CREDS          => 0x00000040,
        ISC_REQ_USE_SUPPLIED_CREDS        => 0x00000080,
        ISC_REQ_ALLOCATE_MEMORY           => 0x00000100,
        ISC_REQ_USE_DCE_STYLE             => 0x00000200,
        ISC_REQ_DATAGRAM                  => 0x00000400,
        ISC_REQ_CONNECTION                => 0x00000800,
        ISC_REQ_CALL_LEVEL                => 0x00001000,
        ISC_REQ_EXTENDED_ERROR            => 0x00004000,
        ISC_REQ_STREAM                    => 0x00008000,
        ISC_REQ_INTEGRITY                 => 0x00010000,
        ISC_REQ_IDENTIFY                  => 0x00020000,
        ISC_REQ_NULL_SESSION              => 0x00040000,

        ASC_REQ_DELEGATE                  => 0x00000001,
        ASC_REQ_MUTUAL_AUTH               => 0x00000002,
        ASC_REQ_REPLAY_DETECT             => 0x00000004,
        ASC_REQ_SEQUENCE_DETECT           => 0x00000008,
        ASC_REQ_CONFIDENTIALITY           => 0x00000010,
        ASC_REQ_USE_SESSION_KEY           => 0x00000020,
        ASC_REQ_ALLOCATE_MEMORY           => 0x00000100,
        ASC_REQ_USE_DCE_STYLE             => 0x00000200,
        ASC_REQ_DATAGRAM                  => 0x00000400,
        ASC_REQ_CONNECTION                => 0x00000800,
        ASC_REQ_CALL_LEVEL                => 0x00001000,
        ASC_REQ_EXTENDED_ERROR            => 0x00008000,
        ASC_REQ_STREAM                    => 0x00010000,
        ASC_REQ_INTEGRITY                 => 0x00020000,
        ASC_REQ_LICENSING                 => 0x00040000,
        ASC_REQ_IDENTIFY                  => 0x00080000,
        ASC_REQ_ALLOW_NULL_SESSION        => 0x00100000,

        SECPKG_ATTR_SIZES                 => 0x00000000,
        SECPKG_ATTR_NAMES                 => 0x00000001,
        SECPKG_ATTR_LIFESPAN              => 0x00000002,
        SECPKG_ATTR_DCE_INFO              => 0x00000003,
        SECPKG_ATTR_STREAM_SIZES          => 0x00000004,
        SECPKG_ATTR_KEY_INFO              => 0x00000005,
        SECPKG_ATTR_AUTHORITY             => 0x00000006,
        SECPKG_ATTR_PROTO_INFO            => 0x00000007,
        SECPKG_ATTR_PASSWORD_EXPIRY       => 0x00000008,
        SECPKG_ATTR_SESSION_KEY           => 0x00000009,
        SECPKG_ATTR_PACKAGE_INFO          => 0x0000000A,
        SECPKG_ATTR_NATIVE_NAMES          => 0x0000000D,

        SEC_E_OK                          => 0x00000000,
        SEC_E_INSUFFICIENT_MEMORY         => 0x80090300,
        SEC_E_INVALID_HANDLE              => 0x80090301,
        SEC_E_UNSUPPORTED_FUNCTION        => 0x80090302,
        SEC_E_TARGET_UNKNOWN              => 0x80090303,
        SEC_E_INTERNAL_ERROR              => 0x80090304,
        SEC_E_SECPKG_NOT_FOUND            => 0x80090305,
        SEC_E_NOT_OWNER                   => 0x80090306,
        SEC_E_CANNOT_INSTALL              => 0x80090307,
        SEC_E_INVALID_TOKEN               => 0x80090308,
        SEC_E_CANNOT_PACK                 => 0x80090309,
        SEC_E_QOP_NOT_SUPPORTED           => 0x8009030A,
        SEC_E_NO_IMPERSONATION            => 0x8009030B,
        SEC_E_LOGON_DENIED                => 0x8009030C,
        SEC_E_UNKNOWN_CREDENTIALS         => 0x8009030D,
        SEC_E_NO_CREDENTIALS              => 0x8009030E,
        SEC_E_MESSAGE_ALTERED             => 0x8009030F,
        SEC_E_OUT_OF_SEQUENCE             => 0x80090310,
        SEC_E_NO_AUTHENTICATING_AUTHORITY => 0x80090311,
        SEC_I_CONTINUE_NEEDED             => 0x00090312,
        SEC_I_COMPLETE_NEEDED             => 0x00090313,
        SEC_I_COMPLETE_AND_CONTINUE       => 0x00090314,
        SEC_I_LOCAL_LOGON                 => 0x00090315,
        SEC_E_BAD_PKGID                   => 0x80090316,
        SEC_E_CONTEXT_EXPIRED             => 0x80090317,
        SEC_E_INCOMPLETE_MESSAGE          => 0x80090318,
        SEC_E_INCOMPLETE_CREDENTIALS      => 0x80090320,
        SEC_E_BUFFER_TOO_SMALL            => 0x80090321,
        SEC_I_INCOMPLETE_CREDENTIALS      => 0x00090320,
        SEC_I_RENEGOTIATE                 => 0x00090321,
        SEC_E_WRONG_PRINCIPAL             => 0x80090322,

        ERROR_NO_SUCH_DOMAIN              => 0x0000054B,
        ERROR_MORE_DATA                   => 0x000000EA,
        ERROR_NONE_MAPPED                 => 0x00000534,
    );

    # create lookup hash for error names
    %err_txt = map {
        sprintf('0x%08x', $constant_hash{$_}) => $_
    } grep {
      /^SEC_[EI]/
    } keys %constant_hash;

}

use constant \%constant_hash;

our @EXPORT_OK   = keys %constant_hash;
our %EXPORT_TAGS = (
    constants => [keys %constant_hash],
);

=head1 CONSTRUCTOR

=head2 new

  my $auth  = Win32::IntAuth->new([debug => 1]);

Creates a new Win32::IntAuth object. By setting the C<debug>
parameter, you'll get a bit of debugging information on STDERR.

=cut
sub new {
    my($class, %args) = @_;

    my $self = bless({}, $class);
    $self->_init(%args);

    return($self);
}


sub _init {
    my($self, %args) = @_;

    $self->{$_} = $args{$_} for keys %args;

    warn "\n" if $self->{debug};

    return(1);
}

=head1 METHODS

All methods return undef on error. Call C<last_err()> or C<last_err_txt()>
to get the error code respectively a short description.

=head2 last_err

Returns the last error code from a method call.

=cut
sub last_err {
    return($_[0]->{last_err} || '0E0');
}

=head2 last_err_txt

Returns the last error text from a method call.

=cut
sub last_err_txt {
    return($_[0]->{last_err_txt} || 'UNKNOWN ERRCODE');
}


my %sspi = (
    AcquireCredentialsHandle => new Win32::API(
        "Secur32.dll",
        "AcquireCredentialsHandle",
        [qw/P P N P P P P P P/],
        'I',
    ),
    InitializeSecurityContext => new Win32::API(
        "Secur32.dll",
        "InitializeSecurityContext",
        [qw/P P P N N N P N P P P P/],
        'I',
    ),
    AcceptSecurityContext => new Win32::API(
        "Secur32.dll",
        "AcceptSecurityContext",
        [qw/P P P N N P P P P/],
        'I',
    ),
    CompleteAuthToken => new Win32::API(
        "Secur32.dll",
        "CompleteAuthToken",
        [qw/P P/],
        'I',
    ),
    ImpersonateSecurityContext => new Win32::API(
        "Secur32.dll",
        "ImpersonateSecurityContext",
        [qw/P/],
        'I',
    ),
    RevertSecurityContext => new Win32::API(
        "Secur32.dll",
        "RevertSecurityContext",
        [qw/P/],
        'I',
    ),
    GetUserNameEx => new Win32::API(
        "Secur32.dll",
        "GetUserNameEx",
        [qw/N P P/],
        'I',
    ),
    FreeContextBuffer => new Win32::API(
        "Secur32.dll",
        "FreeContextBuffer",
        [qw/P/],
        'I',
    ),
    FreeCredentialsHandle => new Win32::API(
        "Secur32.dll",
        "FreeCredentialsHandle",
        [qw/P/],
        'I',
    ),
);


sub _sspi_call {
    my $self  = shift;
    my $fname = shift;

    warn "calling $fname with " 
         . scalar(@_) 
         . " parameters:\n" 
         . join("\n", @_) 
        if $self->{debug};

    {
        no warnings;
        $self->{last_err} = $sspi{$fname}->Call(@_);
    }    
    
    my $rc_hex = sprintf('0x%08x', $self->{last_err});

    if ( $fname eq 'GetUserNameEx' ) {
        return($self->{last_err}) if $self->{last_err};
        $self->{last_err} = Win32::GetLastError();
        $rc_hex = sprintf('0x%08x', $self->{last_err});
        $self->{last_err_txt} = $err_txt{$rc_hex};
        return;
    }

    $self->{last_err_txt} = $err_txt{$rc_hex};

    warn "$fname -> ", $self->{last_err_txt}, "\n" if $self->{debug};

    return if $self->{last_err} < 0;

    return($self->{last_err} || '0E0');
}


=head2 create_token($spn [, $mechanism [, $token]])

Create and returns a token for the current process user ready to be
sent to the server service that should authenticate/impersonate the
client.

The mechanism defaults to "Negotiate".

C<$spn> has to be the UPN (User Principal Name) of the user the service
is running as (or a dedicated Service Principal Name SPN).

C<$token> is only used in a second call to create_token in case of a
continue request. It must contain the token sent back by the server.

=cut
sub create_token {
    my($self, $spn, $mechanism, $token) = @_;
    
    $mechanism ||= 'Negotiate';
    
    # if we didn't receive a token, then acquire a new credentials handle
    unless ( $token ) {
        my $Package    = $mechanism . "\x00";
        my $pExpiry    = pack('LL', 0, 0);
        $self->{hCred} = pack('LL', 0, 0);
        my $Principal  = undef;

        $self->_sspi_call(
            'AcquireCredentialsHandle',
            $Principal,
            $Package,
            SECPKG_CRED_OUTBOUND,
            0,
            0,
            0,
            0,
            $self->{hCred},
            $pExpiry,
        ) or return;
    }

    $self->{Context} = pack('L L', 0, 0)
        unless $self->{Context} and $self->{Context} =~ /[^\0]/;

    my $pContextAttr = pack('L', 0);

    my $in_buf_size  = length($token);
    my $sec_inbuf    = pack("L L P$in_buf_size", $in_buf_size, SECBUFFER_TOKEN, $token);
    my $pInput       = pack('L L P', 0, 1, $sec_inbuf);

    my $out_buf_size = 4096;
    my $out_buf      = "\x00" x $out_buf_size;
    my $sec_outbuf   = pack("L L P$out_buf_size", $out_buf_size, SECBUFFER_TOKEN, $out_buf);
    my $pOutput      = pack('L L P', 0, 1, $sec_outbuf);

    my $pExpiry      = pack('LL', 0, 0);

    $self->_sspi_call(
        'InitializeSecurityContext',
        $self->{hCred},
        $token ? $self->{Context} : 0,
        $spn,
        0,
        0,
        SECURITY_NATIVE_DREP,
        $token ? $pInput : 0,
        0,
        $self->{Context},
        $pOutput,
        $pContextAttr,
        $pExpiry,
    ) or return;

    $self->{continue} 
        = $self->{last_err} == SEC_I_CONTINUE_NEEDED
        ? 1
        : 0;

    # retrieve new output buffer size and trim the buffer to that size
    $out_buf_size = unpack('L', $sec_outbuf);
    $out_buf      = substr($out_buf, 0, $out_buf_size);

    return($out_buf);
}


=head2 get_token_upn($token [, $spn])

Combines C<impersonate($token [, $spn])>, C<get_username()> and
C<revert()> for simple authentication without acting on behalf of the
user.

Returns the fully qualified user name (UPN) of the token user.

=cut
sub get_token_upn {
    my($self, $token) = @_;

    $self->impersonate($token) or return;

    my $upn = $self->get_username() or return;

    $self->revert() or return;

    return($upn);
}


=head2 impersonate($token [, $spn])

Impersonates the user that has created the token in the client
session.

The client user has to have the appropriate rights. (At least network
logon rights on the server the service is running at).

The service user has to have at least the user rights
SeAssignPrimaryTokenPrivilege and SeImpersonatePrivilege and needs to
be trusted for delegation in ActiveDirectory.

If the client creates the token for an ServicePrincipalName the server
must call impersonate with the same SPN in C<$spn>. Otherwise the UPN
of the user the service is running as has to be used.

You will have to check continue_needed() after a call to
impersonate(). If it is needed, impersonate will have returned a token
to be sent back to the client. The client then has to make a second
call to create_token with the server token as second parameter.

Proceed with the second client token as before.

=cut
sub impersonate {
    my($self, $token, $spn) = @_;

    my $Package    = "Negotiate" . "\x00";
    my $pExpiry    = pack('L L', 0, 0);
    $self->{hCred} = pack('L L', 0, 0);

    $self->_sspi_call(
        'AcquireCredentialsHandle',
        $spn ? $spn . "\x00" : 0,
        $Package,
        SECPKG_CRED_INBOUND,
        0,
        0,
        0,
        0,
        $self->{hCred},
        $pExpiry,
    ) or return;

    $self->{Context} = pack('L L', 0, 0)
        unless $self->{Context} and $self->{Context} =~ /[^\0]/;

    my $pContextAttr = pack('L', 0);
    my $buf_size     = 4096;
    my $sec_inbuf    = pack("L L P$buf_size", $buf_size, SECBUFFER_TOKEN, $token);
    my $pInput       = pack('L L P', 0, 1, $sec_inbuf);
    my $out_buf      = ' ' x $buf_size;
    my $sec_outbuf   = pack("L L P$buf_size", $buf_size, SECBUFFER_TOKEN, $out_buf);
    my $pOutput      = pack('L L P', 0, 1, $sec_outbuf);
    $pExpiry         = pack('L L', 0, 0);

    $self->_sspi_call(
        'AcceptSecurityContext',
        $self->{hCred},
        $self->{Context} =~ /[^\0]/ ? $self->{Context} : 0,
        $pInput,
        0,
        SECURITY_NATIVE_DREP,
        $self->{Context},
        $pOutput,
        $pContextAttr,
        $pExpiry,
    ) or return;

    $self->{continue} = $self->{last_err} == SEC_I_CONTINUE_NEEDED;

    return($out_buf) if $self->{continue};

    $self->_sspi_call(
        'CompleteAuthToken',
        $self->{Context},
        $pOutput,
    ) if $self->{last_err} == SEC_I_COMPLETE_NEEDED;

    $self->_sspi_call(
        'ImpersonateSecurityContext',
        $self->{Context},
    ) or return;

    return('0E0');
}


=head2 continue_needed()

Will return 1 if the last call to C<impersonate()> returned a request to
ask the client for a second token.

=cut
sub continue_needed {
    return($_[0]->{continue} || 0);
}


=head2 revert()

Ends impersonation and reverts back to the original server context.

=cut
sub revert {
    my($self) = @_;

    $self->_sspi_call(
        'RevertSecurityContext',
        $self->{Context},
    ) or return;

    return('0E0');
}

=head2 get_username()

Returns the fully qualified user name (UPN) of the current user. If
called after C<impersonate> it will return the impersonated user's
UPN.

=cut
sub get_username {
    my($self) = @_;

    my $siz  = 256;
    my $name = ' ' x $siz;
    my $lsiz = pack('L', $siz);
    my $rc = $self->_sspi_call(
        'GetUserNameEx',
        8,
        $name,
        $lsiz,
    ) or return;

    $name =~ s/\0.*$//;

    return($name);
}


1;


=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Thomas Kratz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
