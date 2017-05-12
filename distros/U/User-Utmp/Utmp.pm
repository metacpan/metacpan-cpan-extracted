# @(#) $Id: Utmp.pm 1.1.1.3 Mon, 27 Mar 2006 02:20:00 +0200 mxp $

package User::Utmp;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(setutent  getut  putut  utmpname
		setutxent endutxent getutxid getutxline getutxent pututxline
		utmpxname getutx
		HAS_UTMPX
		UTMP_FILE UTMPX_FILE WTMP_FILE WTMPX_FILE
		BOOT_TIME
		DEAD_PROCESS
		EMPTY
		INIT_PROCESS
		LOGIN_PROCESS
		NEW_TIME
		OLD_TIME
		RUN_LVL
		USER_PROCESS);
@EXPORT      = ();
%EXPORT_TAGS = (utmp  => [qw(getut putut utmpname)],
		utmpx => [qw(setutxent endutxent getutxid getutxline getutxent
			     pututxline utmpxname getutx)],
		constants => [qw(HAS_UTMPX
				 UTMP_FILE UTMPX_FILE WTMP_FILE WTMPX_FILE
				 BOOT_TIME
				 DEAD_PROCESS
				 EMPTY
				 INIT_PROCESS
				 LOGIN_PROCESS
				 NEW_TIME
				 OLD_TIME
				 RUN_LVL
				 USER_PROCESS)]);
# $Format: "$VERSION='$ProjectVersion$';"$
$VERSION='1.8';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	   croak "Your vendor has not defined User::Utmp macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap User::Utmp $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the documentation

=head1 NAME

User::Utmp - Perl access to utmp- and utmpx-style databases

=head1 SYNOPSIS

  use User::Utmp qw(:constants :utmpx);
  @utmp = getutx();

or, using utmp:

  use User::Utmp qw(:constants :utmp);
  @utmp = getut();

=head1 DESCRIPTION

UNIX systems record information about current and past logins in a
user accounting database.  This database is realized by two files:
File F<utmpx> contains a record of all users currently logged onto the
system, while file F<wtmpx> contains a record of all logins and
logouts.  Some systems (such as HP-UX and AIX) also maintain a third
file containing failed login attempts.  The information in these files
is used by commands such as who(1), last(1), write(1), or login(1).

The exact location of these files in the file system varies between
operating systems, but they are typically stored in directories like
F</var/adm>, F</var/run>, or F</var/log>.  The Single UNIX
Specification specifies an API for reading from and writing to these
files.

The utmpx file format and functions were derived from the older utmp
file format and functions.  For compatibility reasons, many systems
still support the utmp functions and maintain utmp database files.  It
is recommended, however, to use the utmpx functions instead of the
obsolete utmp functions.

The User::Utmp module provides functions for reading and writing utmpx
and utmp files by providing a Perl interface to the system functions.

Utmpx and utmp records are represented in Perl by hash references.
The hash keys are the names of the elements of the utmpx structure.
For details consult utmpx(4) (utmpx(5) on some systems).  The hash
values are (mostly) the same as in C.

As an example, here is a typical record as it may be returned by the
getutxent(), getutxid(), getutxline() or the corresponding utmp
functions:

  {ut_tv   => {tv_sec => 1141256698, tv_usec => 0},
   ut_line => "ttyp0",
   ut_time => 1141256698,
   ut_id   => "p0",
   ut_host => ":0.0",
   ut_exit => {e_termination => 0, e_exit => 2},
   ut_pid  => 4577,
   ut_user => "mxp",
   ut_type => USER_PROCESS,}

The array returned by the getutx() and getut() functions is composed
of hash references like this.

=head2 Utmpx functions

User::Utmp offers a high-level function for reading a utmpx database,
getutx(), and access to the lower-level utmpx functions defined by the
Single UNIX Specification and vendor extensions.

=over 4

=item B<getutx()>

Reads a utmpx-like file and converts it to a Perl array of hashes.
See above for a description of the hashes.

Note that C<ut_addr> (if provided by the utmpx implementation)
contains an Internet address (four bytes in network order), not a
number.  It is therefore converted to a string suitable as parameter
to gethostbyname().  If the record doesn't describe a remote login
C<ut_addr> is the empty string.

For compatibility with utmp, User::Utmp provides a C<ut_time> field
which contains the same value as the C<ut_tv.tv_sec> field.

=back

The following functions are equivalent to the C functions of the same
names; refer to your system's documentation for details.

=over 4

=item B<endutxent()>

Closes the database.

=item B<getutxent()>

Read the next entry from the database.  Returns a hash ref or undef if
the end of the database is reached.

=item B<getutxid()>

This function takes a hash ref as argument and searches for a database
entry matching the values for the C<ut_type> and C<ut_id> keys
specified in the argument.  Returns a hash ref or undef if no matching
entry could be found.

=item B<getutxline()>

This function takes a hash ref as argument and searches for an entry
of the type LOGIN_PROCESS or USER_PROCESS which also has a C<ut_line>
value matching that in the argument.

=item B<pututxline()>

Writes out the supplied utmpx record into the current database.
pututxline() takes a reference to a hash which has the same structure
and contents as the elements of the array returned by getut().
Whether or not pututxline() creates the utmp file if it doesn't exist
is implementation-dependent.

=item B<setutxent()>

Resets the current database.

=item B<utmpxname()>

Allows the user to change the name of the file being examined from the
default file (see the section L</"Constants"> below) to any other
file.  The name provided to utmpxname() will then be used for all
following utmpx functions.

This is a vendor extension, which may not be available on all systems.

=back

=head2 Utmp functions

User::Utmp offers a high-level function for reading a utmp database,
getut(), and access to the lower-level utmp functions.

=over 4

=item B<getut()>

Reads a utmp-like file and converts it to a Perl array of hashes.
See above for a description of the hashes.

Note that C<ut_addr> (if provided by the utmpx implementation)
contains an Internet address (four bytes in network order), not a
number.  It is therefore converted to a string suitable as parameter
to gethostbyname().  If the record doesn't describe a remote login
C<ut_addr> is the empty string.

=back

The following functions are equivalent to the C functions of the same
names; refer to your system's documentation for details.  Since utmp
is not formally standardized, not all functions may be available on
your system, or their behavior may vary.

=over 4

=item B<endutent()>

Closes the database.

=item B<getutent()>

Read the next entry from the database.  Returns a hash ref or undef if
the end of the database is reached.

=item B<getutid()>

This function takes a hash ref as argument and searches for a database
entry matching the values for the C<ut_type> and C<ut_id> keys
specified in the argument.  Returns a hash ref or undef if no matching
entry could be found.

=item B<getutline()>

This function takes a hash ref as argument and searches for an entry
of the type LOGIN_PROCESS or USER_PROCESS which also has a C<ut_line>
value matching that in the argument.

=item B<pututline()>

Writes out the supplied utmp record into the utmp file.  pututline()
takes a reference to a hash which has the same structure and contents
as the elements of the array returned by getut().  Whether or not
pututline() creates the utmp file if it doesn't exist is
implementation-dependent.

=item B<setutent()>

Resets the current database.

=item B<utmpname()>

Allows the user to change the name of the file being examined from the
default file (typically something like F</etc/utmp> or
F</var/run/utmp>; see the section L</"Constants"> below) to any other
file.  In this case, the name provided to utmpname() will be used for
the getut() and pututline() functions.  On some operating systems,
this may also implicitly set the database for utmpx functions.

=back

=head2 Constants

User::Utmp also provides the following constants as functions:

=over 4

=item HAS_UTMPX

True if User::Utmp was built with support for utmpx.

=item UTMP_FILE UTMPX_FILE WTMP_FILE WTMPX_FILE

The default databases.  These constants may not be available on all
platforms.

=item BOOT_TIME DEAD_PROCESS EMPTY INIT_PROCESS LOGIN_PROCESS NEW_TIME
OLD_TIME RUN_LVL USER_PROCESS

Values used in the ut_type field.  EMPTY is also used on Linux
(instead of the non-standard UT_UNKNOWN used in some Linux versions).

=back

=head1 EXAMPLES

See the files F<example.pl> and F<test.pl> in the distribution for
usage examples.

=head1 NOTES

The utmpx interface is standardized in the the Single UNIX
Specificaton and should therefore be used in preference to the legacy
utmp functions.  Some systems only provide minimal utmp support.

=head1 RESTRICTIONS

Reading the whole file into an array might not be the most efficient
approach for very large databases.

This module is based on the non-reentrant utmpx and utmp functions; it
is therefore not thread-safe.

=head1 AUTHOR

Michael Piotrowski <mxp@dynalabs.de>

=head1 SEE ALSO

utmpx(4), utmp(4); on some systems: utmpx(5), utmp(5)

=cut
