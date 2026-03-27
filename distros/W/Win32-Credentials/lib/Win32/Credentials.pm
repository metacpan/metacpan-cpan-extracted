package Win32::Credentials;

use strict;
use warnings;


our $VERSION = '0.03';

=head1 NAME

Win32::Credentials - Read/Write Windows Credential Manager via Win32 API

=head1 SYNOPSIS

    use Win32::Credentials qw(cred_write cred_read cred_delete);

    # Store a secret
    cred_write('My_App/My_password', 'myapp', 'secret123');

    # Retrieve a secret
    my $secret = cred_read('My_App/My_password');

    # Retrieve secret and username
    my ($secret, $user) = cred_read('My_App/My_password');

    # Delete
    cred_delete('My_App/My_password');

=head1 DESCRIPTION

Provides a simple Perl interface to the Windows Credential Manager
(CredWriteW, CredReadW, CredDeleteW) via Win32::API.
Secrets are protected by DPAPI (AES-256) tied to the current
Windows user account.

No XS compilation required - uses Win32::API.

=head1 FUNCTIONS

=head2 cred_write($target, $username, $secret)

Stores a secret in the Windows Credential Manager.
Maximum secret size: 512 bytes (CRED_TYPE_GENERIC limit).

=head2 cred_read($target)

Retrieves a secret. In list context returns ($secret, $username).

=head2 cred_delete($target)

Removes a credential from the vault.

=head1 NOTES

=over 4

=item * Requires 64-bit Windows and 64-bit Perl

=item * Uses CRED_TYPE_GENERIC and CRED_PERSIST_LOCAL_MACHINE

=item * Secret is stored as UTF-16LE (native Windows format)

=back

=head1 AUTHOR

Massimiliano Citterio E<lt>mcitterio@cmcps.itE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Exporter 'import';
use Encode   qw(encode decode);
use Win32::API;
use Win32;

our @EXPORT_OK = qw(cred_write cred_read cred_delete);

# Constants
use constant CRED_TYPE_GENERIC          => 1;
use constant CRED_PERSIST_LOCAL_MACHINE => 2;
use constant CRED_PERSIST_ENTERPRISE    => 3;

#  Load from advapi32.dll 
#
# BOOL CredWriteW(PCREDENTIALW Credential, DWORD Flags)
# BOOL CredReadW (LPCWSTR TargetName, DWORD Type, DWORD Flags, PCREDENTIALW *Credential)
# BOOL CredReadW (LPCWSTR TargetName, DWORD Type, DWORD Flags)
# VOID CredFree  (PVOID Buffer)

# L  An unsigned long value.

# Q  An unsigned quad value.
#     (Quads are available only if your system supports 64-bit
#     integer values and if Perl has been compiled to support
#     those.  Raises an exception otherwise.)


# Windows API Loaders
my $CredWrite = Win32::API->new(
    'advapi32', 'CredWriteW', 'PI', 'I'
) or die "CredWriteW: $^E";

my $CredRead = Win32::API->new(
    'advapi32', 'CredReadW', 'PIIP', 'I'
) or die "CredReadW: $^E";

my $CredDelete = Win32::API->new(
    'advapi32', 'CredDeleteW', 'PII', 'I'
) or die "CredDeleteW: $^E";

my $CredFree = Win32::API->new(
    'advapi32', 'CredFree', 'N', 'V'
) or die "CredFree: $^E";

#  Check if Perl is 64-bit 
my $IS64 = (length(pack('P', 0)) == 8);

#  Build CREDENTIAL struct in memory 
#
# Layout 64-bit (all pointers are Q = 8 byte):
#   Flags            DWORD   L  4
#   Type             DWORD   L  4
#   TargetName       PTR     Q  8
#   Comment          PTR     Q  8
#   LastWritten.Low  DWORD   L  4
#   LastWritten.High DWORD   L  4
#   CredentialBlobSz DWORD   L  4
#   (padding)                   4   aligning to 64-bit
#   CredentialBlob   PTR     Q  8
#   Persist          DWORD   L  4
#   AttributeCount   DWORD   L  4
#   Attributes       PTR     Q  8
#   TargetAlias      PTR     Q  8
#   UserName         PTR     Q  8

sub _build_credential_struct {
    my (%args) = @_;

    # Convert strings into UTF-16LE (Wide char Windows)
    my $target_w  = encode('UTF-16LE', $args{target}   . "\0");
    my $user_w    = encode('UTF-16LE', ($args{user}//'') . "\0");
    my $comment_w = encode('UTF-16LE', ($args{comment}//'Win32-Credentials') . "\0");

    # The blob is the password bytes (UTF-16LE for Windows compatibilty)
    my $blob_w    = encode('UTF-16LE', $args{secret});
    my $blob_size = length($blob_w);
	die "Blob exceeds 512 byte (limit CRED_TYPE_GENERIC)\n"
		if $blob_size > 512;

	# There is no way to test it on 32bit systems for the moment
    if ($IS64) {
        # Buuild the struct with Win32::API::Struct
        # using pack with pointer as packed string
        my $struct = pack(
            'L L'     .                # Flags, Type
            ($IS64 ? 'Q Q' : 'L L') .  # TargetName, Comment (ptr)
            'L L'     .                # LastWritten (FILETIME = 2x DWORD)
            'L'       .                # CredentialBlobSize
            'x4'      .                # padding 64-bit
            ($IS64 ? 'Q' : 'L') .      # CredentialBlob (ptr)
            'L L'     .                # Persist, AttributeCount
            ($IS64 ? 'Q Q Q' : 'L L L'),  # Attributes, TargetAlias, UserName
            # valori:
            0,                         # Flags
            CRED_TYPE_GENERIC,         # Type
            unpack('Q', pack('P', $target_w)),   # TargetName ptr
            unpack('Q', pack('P', $comment_w)),  # Comment ptr
            0, 0,                      # LastWritten
            $blob_size,                # CredentialBlobSize
            unpack('Q', pack('P', $blob_w)),     # CredentialBlob ptr
            CRED_PERSIST_LOCAL_MACHINE,          # Persist
            0,                         # AttributeCount
            0,                         # Attributes (NULL)
            0,                         # TargetAlias (NULL)
            unpack('Q', pack('P', $user_w)),     # UserName ptr
        );

        # Return buffers to the scope
        return ($struct, $target_w, $comment_w, $blob_w, $user_w);
    }else{
		  die "32Bit Mode is actually unsupported\n";
	}
}

# WRITE 
sub cred_write {
    my ($target, $user, $secret) = @_;

    my ($struct, @buffers) = _build_credential_struct(
        target  => $target,
        user    => $user,
        secret  => $secret,
    );

    my $result = $CredWrite->Call($struct, 0);

    unless ($result) {
        my $err = Win32::GetLastError();
        die "CredWriteW Failed, error: $err\n";
    }

    return 1;
}

# READ 
sub cred_read {
    my ($target) = @_;

    # Buffer for pointer to struct
    my $ptr_buf = "\0" x 8;

    my $target_w = encode('UTF-16LE', $target . "\0");

    my $result = $CredRead->Call(
        $target_w,           # TargetName (Wide)
        CRED_TYPE_GENERIC,   # Type
        0,                   # Flags (reserved, must be 0)
        $ptr_buf             # output: PCREDENTIALW*
    );

    unless ($result) {
        my $err = Win32::GetLastError();
        die "CredReadW failed, error: $err\n";
    }

    # Extract the pointer
    my $cred_ptr = unpack('Q', $ptr_buf);
    die "CredReadW: Pointer NULL\n" unless $cred_ptr;

    # Read struct From Memory
    # Offset CredentialBlob e CredentialBlobSize in struct 64-bit:
    # 0:  Flags           DWORD L  4
    # 4:  Type            DWORD L  4
    # 8:  TargetName ptr  PTR   Q  8
    # 16: Comment ptr     PTR   Q  8
    # 24: LastWritten.L   DWORD L  4
    # 28: LastWritten.H   DWORD L  4
    # 32: BlobSize        DWORD L  4
    # 36: padding         DWORD L  4
    # 40: Blob ptr        PTR   Q  8
    # 48: Persist         DWORD L  4
    # 52: AttributeCount  DWORD L  4
    # 56: Attributes ptr  PTR   Q  8
    # 64: TargetAlias ptr PTR   Q  8
    # 72: UserName ptr    PTR   Q  8

    # Use Win32::API::ReadMemory to read struct
    my $struct    = Win32::API::ReadMemory($cred_ptr, 80);

	# Extract fields 
    my $blob_size = unpack('L', substr($struct, 32, 4));
    my $blob_ptr  = unpack('Q', substr($struct, 40, 8));
    my $user_ptr  = unpack('Q', substr($struct, 72, 8));

    # Read blob (password)
    my $blob_raw = Win32::API::ReadMemory($blob_ptr, $blob_size);
    my $secret   = decode('UTF-16LE', $blob_raw);

    # Read UserName (optional, null-terminated UTF-16LE string)
    my $username = '';
    if ($user_ptr) {
        # Read till double \0 (max 512 char)
        my $user_raw = Win32::API::ReadMemory($user_ptr, 512);
        ($username)  = ($user_raw =~ /^((?:..)*?)\x00\x00/s);
        $username    = decode('UTF-16LE', $username) if $username;
    }

    # Free allocated memory from CredReadW
    $CredFree->Call($cred_ptr);

    return wantarray ? ($secret, $username) : $secret;
}

# DELETE 
sub cred_delete {
    my ($target) = @_;

    my $target_w = encode('UTF-16LE', $target . "\0");
    my $result   = $CredDelete->Call($target_w, CRED_TYPE_GENERIC, 0);

    unless ($result) {
        die "CredDeleteW failed: " . Win32::GetLastError() . "\n";
    }
    return 1;
}

1;