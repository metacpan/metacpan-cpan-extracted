=head1 NAME

Win32API::File::Time - Set file times, even on open or readonly files.

=head1 SYNOPSIS

 use Win32API::File::Time qw{:win};
 ($atime, $mtime, $ctime) = GetFileTime ($filename);
 SetFileTime ($filename, $atime, $mtime, $ctime);

or

 use Win32API::File::Time qw{utime};
 utime $atime, $mtime, $filename or die $^E;

=head1 DESCRIPTION

The purpose of Win32API::File::Time is to provide maximal access to
the file creation, modification, and access times under MSWin32.

Under Windows, the Perl utime module will not modify the time of an
open file, nor a read-only file. The comments in win32.c indicate
that this is the intended functionality, at least for read-only
files.

This module will read and modify the time on open files, read-only
files, and directories. I<Caveat user.>

This module is based on the SetFileTime function in kernel32.dll.
Perl's utime built-in also makes explicit use of this function if
the "C" run-time version of utime fails. The difference is in how
the filehandle is created. The Perl built-in requests access
GENERIC_READ | GENERIC_WRITE when modifying file dates, whereas
this module requests access FILE_WRITE_ATTRIBUTES.

Nothing is exported by default, but all documented subroutines
are exportable. In addition, the following export tags are
supported:

 :all => exports everything exportable
 :win => exports GetFileTime and SetFileTime

Wide system calls are implemented (based on the truth of
${^WIDE_SYSTEM_CALLS}) but not currently supported. In other words: I
wrote the code, but haven't tested it and don't have any plans to.
Feedback will be accepted, and implemented when I get a sufficient
supply of tuits.

=over 4

=cut

package Win32API::File::Time;

use 5.006002;

use strict;
use warnings;

use parent qw{ Exporter };

our $FileTimeToSystemTime;
our $FileTimeToLocalFileTime;
our $GetFileTime;
our $LocalFileTimeToFileTime;
our $SetFileTime;
our $SystemTimeToFileTime;

use Carp;
use Time::Local;
use Win32::API;
use Win32API::File qw{ :ALL };

our $VERSION = '0.012';

our @EXPORT_OK = qw{ GetFileTime SetFileTime utime };
our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
    win => [ qw{ GetFileTime SetFileTime } ],
);

=item ( $atime, $mtime, $ctime ) = GetFileTime( $filename );

This subroutine returns the access, modification, and creation times of
the given file. If it fails, nothing is returned, and the error code
can be found in $^E.

No, there's no additional functionality here versus the stat
built-in. But it was useful for development and testing, and
has been exposed for orthogonality's sake.

=cut

sub GetFileTime {
    my ( $fn ) = @_;
    defined $fn
	or croak "usage: GetFileTime (filename)";
    my $fh = _get_handle( $fn ) or return;
    $GetFileTime ||= _map( 'KERNEL32', 'GetFileTime', [ qw{ N P P P } ], 'I' );
    my $atime = my $mtime = my $ctime = pack 'LL', 0, 0; # Preallocate 64 bits.
    $GetFileTime->Call( $fh, $ctime, $atime, $mtime )
	or return _close_handle( $fh );
    CloseHandle( $fh );
    return _filetime_to_perltime( $atime, $mtime, $ctime );
}

=item SetFileTime( filename, atime, mtime, ctime );

This subroutine sets the access, modification, and creation times of
the given file. The return is true for success, and false for failure.
In the latter case, $^E will contain the error.

If you don't want to set all of the times, pass 0 or undef for the
times you don't want to set. For example,

 $now = time();
 SetFileTime( $filename, $now, $now );

is equivalent to the "touch" command for the given file.

=cut

sub SetFileTime {
    my ( $fn, $atime, $mtime, $ctime ) = @_;
    defined $fn
	or croak "usage: SetFileTime (filename, atime, mtime, ctime)";
    foreach ( $atime, $mtime, $ctime ) {
	$_ = _perltime_to_filetime( $_ );
    }
    # We assume we can do something useful for an undef.
    $SetFileTime ||= _map( 'KERNEL32', 'SetFileTime', [ qw{ N P P P } ], 'I' );
    my $fh = _get_handle( $fn, 1 )
	or return;

    $SetFileTime->Call( $fh, $ctime, $atime, $mtime )
	or return _close_handle( $fh );

    CloseHandle( $fh );
    return 1;
}

=item utime( $atime, $mtime, $filename, ... )

This subroutine overrides the built-in of the same name. It does
exactly the same thing, but has a different idea than the built-in
about what files are legal to change.

Like the core utime, it returns the number of files successfully
modified. If not all files can be modified, $^E contains the last
error encountered.

=cut

sub utime {	## no critic (ProhibitBuiltinHomonyms)
    my ( $atime, $mtime, @args ) = @_;
    my $num = 0;
    foreach my $fn (@args) {
	SetFileTime ($fn, $atime, $mtime)
	    and $num++;
    }
    return $num;
}

#######################################################################
#
#	Internal subroutines
#
#	_close_handle
#
#	This subroutine closes the given handle, preserving status
#	around the call.

sub _close_handle {
    my ( $fh ) = @_;
    my $err = Win32::GetLastError();
    CloseHandle( $fh );
    $^E = $err;	## no critic (RequireLocalizedPunctuationVars)
    return;
}

#	_filetime_to_perltime
#
#	This subroutine takes as input a number of Windows file times
#	and converts them to Perl times.
#
#	The algorithm is due to the unsung heros at Hip Communications
#	Inc (currently known as ActiveState), who found a way around
#	the fact that Perl and Windows have a fundamentally different
#	idea of what local time corresponds to a given GMT when summer
#	time was in effect at the given GMT, but not at the time the
#	conversion is made. The given algorithm is consistent with the
#	results of the stat () function.

sub _filetime_to_perltime {
    my @args = @_;
    my @result;
    $FileTimeToSystemTime ||= _map(
	    'KERNEL32', 'FileTimeToSystemTime', [ qw{ P P } ], 'I' );
    $FileTimeToLocalFileTime ||= _map (
	    'KERNEL32', 'FileTimeToLocalFileTime', [qw{P P}], 'I');
    my $st = pack 'ssssssss', 0, 0, 0, 0, 0, 0, 0, 0;
    foreach my $ft ( @args ) {
	my ( undef, $high ) = unpack 'LL', $ft;	# $low unused
	$high or do {
	    push @result, undef;
	    next;
	};
	my $lf = $ft;	# Just to get the space allocated.
	$FileTimeToLocalFileTime->Call ($ft, $lf)
	    and $FileTimeToSystemTime->Call ($lf, $st)
	    or do {
	    push @result, undef;
	    next;
	};
	my @tm = unpack 'ssssssss', $st;
	push @result, $tm[0] > 0 ?
	    timelocal (@tm[6, 5, 4, 3], $tm[1] - 1, $tm[0]) :
	    undef;
    }
    return wantarray ? @result : $result[0];
}

#	_get_handle
#
#	This subroutine takes a file name and returns a handle to the
#	file. If the second argument is true, the handle is configured
#	appropriately for  writing attributes; otherwise it is
#	configured appropriately for reading attributes.

sub _get_handle {
    my ( $fn, $write ) = @_;

    my @arg = (
	    FILE_READ_ATTRIBUTES,
	    FILE_SHARE_READ,
	    [],
	    OPEN_EXISTING,
	    FILE_FLAG_BACKUP_SEMANTICS,
	    0
    );
    if ( $write ) {
	$arg[0] = FILE_WRITE_ATTRIBUTES;
	$arg[1] |= FILE_SHARE_WRITE;
	$arg[4] |= FILE_ATTRIBUTE_NORMAL;
    }
    my $handle = ${^WIDE_SYSTEM_CALLS} ?
	CreateFileW( $fn, @arg ) :
	CreateFile( $fn, @arg )
	or do {
	$^E = Win32::GetLastError();	## no critic (RequireLocalizedPunctuationVars)
	return;
    };

    return $handle;
}

#	_map
#
#	This subroutine calls Win32API to map an entry point.

sub _map {
return Win32::API->new ( @_ ) ||
    croak "Error - Failed to map $_[1] from $_[0]: $^E";
}

#	_perltime_to_filetime
#
#	This subroutine converts perl times to Windows file times.

#	The same considerations apply to the algorithm used here as to
#	the one used in _filetime_to_perltime.

sub _perltime_to_filetime {
    my @args = @_;
    my @result;
    $SystemTimeToFileTime ||= _map(
	    'KERNEL32', 'SystemTimeToFileTime', [ qw{ P P } ], 'I' );
    $LocalFileTimeToFileTime ||= _map(
	    'KERNEL32', 'LocalFileTimeToFileTime', [ qw{ P P } ], 'I' );
    my $zero = pack 'LL', 0, 0;	# To get a quadword zero.
    my ( $ft, $lf ) = ( $zero, $zero );	# To get the space allocated.
    foreach my $pt ( @args ) {
	if ( defined $pt ) {
	    my @tm = localtime ($pt);
	    my $st = pack 'ssssssss', $tm[5] + 1900, $tm[4] + 1, 0,
		@tm[3, 2, 1, 0], 0;
	    push @result, $SystemTimeToFileTime->Call( $st, $lf )  &&
		$LocalFileTimeToFileTime->Call( $lf, $ft ) ? $ft : $zero;
	} else {
	    push @result, $zero;
	}
    }
    return wantarray ? @result : $result[0];
}

1;

__END__

=back

=head1 NOTE

It has been a while since I had access to a Microsoft Windows system of
any sort, and various strange expedients have been used to allow me to
continue to support this module. Requests for co-maintainership, or
ownership of the module, are welcome.

By OS, the situation is:

=head2 ReactOS

ReactOS is an alpha-quality open-source clean-room OS implementing the
Microsoft Windows API. When it started out it was targeting NT 4.0.
Lately they seem to be targeting Windows 2003. ReactOS is found at
L<https://reactos.org/>.

With about 0.4.11 this has become good enough that using it to support
this module is not completely out of the question. However, the last I
checked I was unable to read the creation time. Since this worked under
Microsoft Windows the last time I had access to that OS, I presume this
failure is a ReactOS thing.

The problem here is that I know of no definitive way to distinguish
between ReactOS and Microsoft Windows. Early versions of ReactOS defined
the C<OS> environment variable as C<'ReactOS'>, but more recent ones
call it C<'Windows_NT'>. At the moment there is ad-hocery in
F<t/file.t> that detects ReactOS by feeling around the system drive
looking for files with that name. The default installation makes
C<%SystemRoot%> C<'C:\ReactOS'>, and this is what we look for. If you
change this, you will need to create file F<C:\ReactOS> yourself or the
creation time check will be run, and it will fail.

=head2 Cygwin

I am unable to install this on ReactOS. Support is on a best-effort
basis, and the requester may have to be more-than-usually involved in
developing any change.

=head2 Microsoft Windows

I do not have access to such a system. If ReactOS proves inadequate for
a particular purpose, support will be on the same basis as
L<Cygwin|/Cygwin>.

=head2 Anything else

Regression testing is done using a mock L<Win32::API|Win32::API>.
Anything outside this needs either ReactOS or another pair of hands.

=head1 BUGS

As implemented, C<GetFileTime()> constitutes an access, and therefore
updates the access time.

The C<stat()> builtin, on the other hand, doesn't report an access time
change even after C<GetFileTime()> has been used. In fact, it looks to
me very much like C<stat()> reports the modification time in element [8]
of the list, but I find this nowhere documented.

FAT file time resolution is 2 seconds at best, as documented at
L<https://docs.microsoft.com/en-us/windows/win32/sysinfo/file-times>.
Access time resolution seems to be to the nearest day.

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Win32API-File-Time>,
L<https://github.com/trwyant/perl-Win32API-File-Time/issues>, or in
electronic mail to the author.

=head1 ACKNOWLEDGMENTS

This module would not exist without the following people:

Aldo Calpini, who gave us Win32::API.

Tye McQueen, who gave us Win32API::File.

Jenda Krynicky, whose "How2 create a PPM distribution"
(F<http://jenda.krynicky.cz/perl/PPM.html>) gave me a leg up on
both PPM and tar distributions.

The folks of ActiveState (F<http://www.activestate.com/>,
formerly known as Hip Communications), who found a way to reconcile
Windows' and Perl's subtly different ideas of what time it is.

The folks of Cygwin (F<http://www.cygwin.com/>), especially those
who worked on times.cc in the Cygwin core. This is the B<only>
implementation of utime I could find which did what B<I> wanted
it to do.

=head1 AUTHOR

Thomas R. Wyant, III (F<Thomas.R.Wyant-III@usa.dupont.com>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by E. I. DuPont de Nemours and Company, Inc. All
rights reserved.

Copyright (C) 2007, 2010, 2016-2017, 2019-2021 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
