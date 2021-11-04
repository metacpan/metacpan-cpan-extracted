package Win32API::File;

use 5.006002;

use strict;
use warnings;

use Carp;
use Exporter qw{ import };

our $VERSION = '0.012';

our %EXPORT_TAGS = (
    FILE_		=> [ qw{
	FILE_READ_ATTRIBUTES
	FILE_WRITE_ATTRIBUTES
    } ],
    FILE_ATTRIBUTE_	=> [ qw{ FILE_ATTRIBUTE_NORMAL } ],
    FILE_FLAG_		=> [ qw{ FILE_FLAG_BACKUP_SEMANTICS } ],
    FILE_SHARE_		=> [ qw{ FILE_SHARE_READ FILE_SHARE_WRITE } ],
    Func		=> [ qw{ CloseHandle CreateFile } ],
    FuncW		=> [ qw{ CreateFileW } ],
    Misc		=> [ qw{ OPEN_EXISTING } ],
);

our @EXPORT_OK;
push @EXPORT_OK, @{ $EXPORT_TAGS{$_} } for keys %EXPORT_TAGS;

$EXPORT_TAGS{ALL} = \@EXPORT_OK;

use constant FILE_READ_ATTRIBUTES	=> 128;
use constant FILE_WRITE_ATTRIBUTES	=> 256;

use constant FILE_ATTRIBUTE_NORMAL	=> 128;

use constant FILE_FLAG_BACKUP_SEMANTICS	=> 33554432;

use constant FILE_SHARE_READ		=> 1;
use constant FILE_SHARE_WRITE		=> 2;

use constant OPEN_EXISTING		=> 3;

*__mock_add_to_trace = Win32::API->can( '__mock_add_to_trace' ) || sub {};

sub CloseHandle {
    my ( $fh ) = @_;
    __mock_add_to_trace( CloseHandle => @_ );
    defined $fh
	or croak 'Missing file handle';
    return;
}

sub CreateFile {
    my ( $fn, $rw, $share, $sec, $create, $flag, $tplt ) = @_;
    __mock_add_to_trace( CreateFile => @_ );
    'ARRAY' eq ref $sec
	and not @{ $sec }
	or croak "Unexpected security attributes $sec";
    OPEN_EXISTING == $create
	or croak "Unexpected creation/disposition code $create";
    $tplt
	and croak "Unexpected template handle $tplt";
    if ( FILE_WRITE_ATTRIBUTES == $rw ) {
	( FILE_SHARE_WRITE | FILE_SHARE_READ ) == $share
	    or croak "Unexpectes write share code $share";
	( FILE_ATTRIBUTE_NORMAL | FILE_FLAG_BACKUP_SEMANTICS ) == $flag
	    or croak "Unexpected write flags $flag";
    } elsif ( FILE_READ_ATTRIBUTES == $rw ) {
	FILE_SHARE_READ == $share
	    or croak "Unexpectes read share code $share";
	FILE_FLAG_BACKUP_SEMANTICS == $flag
	    or croak "Unexpected read flags $flag";
    } else {
	croak "Unexpected CreateFile access code $rw";
    }
    return $fn;
}

{
    no warnings qw{ once };

    *CreateFileW = \&CreateFile;

}

1;

__END__

=head1 NAME

mock::Win32API::File - Mock needed parts of Win32API::File

=head1 SYNOPSIS

 use lib qw{ inc/mock };
 use Win32API::File qw{ :ALL };

=head1 DESCRIPTION

This Perl module is private to the C<Win32API-File-Time> distribution,
and may be changed or retracted without notice. Documentation is for the
benefit of the author only.

This Perl module provides just enough of
L<Win32API::File|Win32API::File> to allow
L<Win32API::File::Time|Win32::API::File::Time> to be tested under a
non-Windows system.

=head1 EXPORTS

The following manifest constants can be exported:

=over

=item FILE_ATTRIBUTE_NORMAL

=item FILE_FLAG_BACKUP_SEMANTICS

=item FILE_SHARE_READ

=item FILE_SHARE_WRITE

=item OPEN_EXISTING

=back

The values of these constants are defined in the Perl sense, but are
undefined in that the user should not assume any particular value for
them.

In addition, the following tags can be exported:

=over

=item FILE_ATTRIBUTE_ (FILE_ATTRIBUTE_NORMAL)

=item FILE_FLAG_ (FILE_FLAG_BACKUP_SEMANTICS)

=item FILE_SHARE_ (FILE_SHARE_READ, FILE_SHARE_WRITE)

=item Func (CreateFile)

=item FuncW (CreateFileW)

=item Misc (OPEN_EXISTING)

=item ALL (all manifest constants)

=head1 SUBROUTINES

This class supports the following exportable subroutines:

=head2 CreateFile

This subroutine takes the same arguments as
C<Win32API::File::CreateFile()>. It simply returns the file name, since
we are eventually going to pass it to the C<utime()> built-in.

=head2 CreateFileW

This subroutine takes the same arguments as
C<Win32API::File::CreateFileW()>. It simply returns the file name, since
we are eventually going to pass it to the C<utime()> built-in.

=head1 ATTRIBUTES

This class has the following attributes:

=head1 SEE ALSO

<<< replace or remove boilerplate >>>

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Win32API-File-Time>,
L<https://github.com/trwyant/perl-Win32API-File-Time/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Tom Wyant (wyant at cpan dot org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017, 2019-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
