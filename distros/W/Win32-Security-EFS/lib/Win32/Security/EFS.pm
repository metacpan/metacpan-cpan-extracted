package Win32::Security::EFS;

use strict;
use warnings;

use base qw/Exporter Win32::API::Interface/;
use vars qw/$VERSION @EXPORT_OK %EXPORT_TAGS/;
$VERSION = '0.11';

use File::Spec ();

my %consts;

BEGIN {
    %consts = (
        FILE_ENCRYPTABLE        => 0,
        FILE_IS_ENCRYPTED       => 1,
        FILE_SYSTEM_ATTR        => 2,
        FILE_ROOT_DIR           => 3,
        FILE_SYSTEM_DIR         => 4,
        FILE_UNKNOWN            => 5,
        FILE_SYSTEM_NOT_SUPPORT => 6,
        FILE_USER_DISALLOWED    => 7,
        FILE_READ_ONLY          => 8,
        FILE_DIR_DISALLOWED     => 9,
    );
}

use constant \%consts;

__PACKAGE__->generate(
    {
        'advapi32' => [
            [
                'EncryptFile',
                'P', 'I', '',
                sub {
                    my ( $self, $filename ) = @_;
                    return $self->Call( File::Spec->canonpath($filename) );
                },
            ],
            [
                'DecryptFile',
                'PN',
                'I',
                '',
                sub {
                    my ( $self, $filename, $reserved ) = @_;
                    return $self->Call( File::Spec->canonpath($filename),
                        $reserved );
                },
            ],
            [
                'FileEncryptionStatus',
                'PP',
                'I',
                '',
                sub {
                    my ( $self, $filename, $statusref ) = @_;
                    $$statusref = "\0" x 4;
                    return $self->Call( File::Spec->canonpath($filename),
                        $$statusref );
                },
            ],
            [
                'EncryptionDisable',
                'PI',
                'I',
                '',
                sub {
                    my ( $self, $filename, $disable ) = @_;
                    return $self->Call( File::Spec->canonpath($filename),
                        $disable );
                },
            ],
            [
                'QueryUsersOnEncryptedFile',
                'PP',
                'I',
                '__QueryUsersOnEncryptedFile',
                sub {
                    my ( $self, $filename, $usersref ) = @_;

                    my $users = pack("L", 0x0);
                    my $retval =
                      $self->Call(
                        __make_unicode( File::Spec->canonpath($filename) ),
                        $users );

                    print STDERR "\nusers: ", unpack("PP", $users), "\n";
                },
            ],
        ],
    }
);

%EXPORT_TAGS = (
    consts => [ __PACKAGE__->constant_names ],
    api    => [ __PACKAGE__->generated ]
);
@EXPORT_OK = ( __PACKAGE__->constant_names, __PACKAGE__->generated );

=head1 NAME

Win32::Security::EFS - Perl interface to functions that assist in working
with EFS (Encrypted File System) under Windows plattforms.

=head1 SYNOPSIS

	use Win32::Security::EFS;

	if(Win32::Security::EFS->supported()) {
		Win32::Security::EFS->encrypt('some/file');
		Win32::Security::EFS->decrypt('some/file');
	}




=head1 DESCRIPTION

The Encrypted File System, or EFS, was introduced in version 5 of NTFS to
provide an additional level of security for files and directories. It
provides cryptographic protection of individual files on NTFS volumes
using a public-key system. Typically, the access control to file and
directory objects provided by the Windows security model is sufficient to
protect unauthorized access to sensitive information. However, if a laptop
containing sensitive data is lost or stolen, the security protection of
that data may be compromised. Encrypting the files increases security in
this scenario.

=head2 METHODS

=over 4

=item B<supported()>

Returns I<true> iff the underlaying filesystem supports EFS

=cut

sub supported {
    require Win32;

    my ( undef, $flags, undef ) = Win32::FsType();
    return ( $flags & 0x00020000 ) > 0;
}

=item B<constant_names()>

=cut

sub constant_names {
    return keys %consts;
}

=item B<encrypt($filename)>

The I<encrypt> function encrypts a file or directory. All data streams in a file are encrypted.
All new files created in an encrypted directory are encrypted.

=cut

sub encrypt {
    my ( $self, $filename ) = @_;
    return $self->EncryptFile($filename);
}

=item B<decrypt($filename)>

The I<decrypt> function decrypts an encrypted file or directory.

=cut

sub decrypt {
    my ( $self, $filename ) = @_;
    return $self->DecryptFile( $filename, 0 );
}

=item B<encryption_status($filename)>

The I<encryption_status> function retrieves the encryption status of the specified file.

If the function succeeds, it will return one of the following values see the L</CONSTANTS> section.

=cut

sub encryption_status {
    my ( $self, $filename ) = @_;
    my $status;
    my $result = $self->FileEncryptionStatus( $filename, \$status );
    return $result ? unpack( "L*", $status ) : undef;
}

=item B<encryption_disable($dirpath)>

The I<encryption_disable> function disables encryption of the specified directory and the files in it.
It does not affect encryption of subdirectories below the indicated directory.

=cut

sub encryption_disable {
    my ( $self, $dirpath ) = @_;
    return $self->EncryptionDisable( $dirpath, 1 );
}

=item B<encryption_enable($dirpath)>

The I<encryption_enable> function enables encryption of the specified directory and the files in it.
It does not affect encryption of subdirectories below the indicated directory.

=cut

sub encryption_enable {
    my ( $self, $dirpath ) = @_;
    return $self->EncryptionDisable( $dirpath, 0 );
}

=back

=head2 FUNCTIONS

You have the possibility to access the plain API directly. Therefore the
following functions can be exported:

    use Win32::Security::EFS ':api';

=over 4

=item B<EncryptFile($filename)>

    BOOL EncryptFile(
        LPCTSTR lpFileName  // file name
    );

=item B<DecryptFile($filename, $reserved)>

    BOOL DecryptFile(
        LPCTSTR lpFileName,  // file name
        DWORD dwReserved     // reserved; must be zero
    );

=item B<FileEncryptionStatus($filename, \$status)>

    BOOL FileEncryptionStatus(
        LPCTSTR lpFileName,  // file name
        LPDWORD lpStatus     // encryption status
    );

=item B<EncryptionDisable($filename, $disable)>

    BOOL EncryptionDisable(
        LPCWSTR lpDirPath,
        BOOL fDisable
    );

=item B<QueryUsersOnEncryptedFile( ... )>

Not yet implemented.

=back

=head1 CONSTANTS

You can import all constants by importing Win32::Security::EFS like

	use Win32::Security::EFS ':consts';

=over 4

=item *
encryption_status constants

=over 4

=item *
I<FILE_DIR_DISALLOWED:>
Reserved for future use.

=item *
I<FILE_ENCRYPTABLE:>
The file can be encrypted.

=item *
I<FILE_IS_ENCRYPTED:>
The file is encrypted.

=item *
I<FILE_READ_ONLY:>
The file is a read-only file.

=item *
I<FILE_ROOT_DIR:>
The file is a root directory. Root directories cannot be encrypted.

=item *
I<FILE_SYSTEM_ATTR:>
The file is a system file. System files cannot be encrypted.

=item *
I<FILE_SYSTEM_DIR:>
The file is a system directory. System directories cannot be encrypted.

=item *
I<FILE_SYSTEM_NOT_SUPPORT:>
The file system does not support file encryption.

=item *
I<FILE_UNKNOWN:>
The encryption status is unknown. The file may be encrypted.

=item *
I<FILE_USER_DISALLOWED:>
Reserved for future use.

=back

=back

=head1 AUTHOR

Sascha Kiefer, L<esskar@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Sascha Kiefer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub __make_unicode {
    require Encode;
    return map { Encode::encode( 'UTF-16LE', $_, 1 ) } @_;
}

1;
