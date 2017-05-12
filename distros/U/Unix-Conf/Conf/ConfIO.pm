# Class to cache configuration file I/O
#
# Copyright Karthik Krishnamurthy <karthik.k@extremix.net>
=head1 NAME

Unix::Conf::ConfIO - This is an internal module for handling line 
at a time I/O for configuration files, with caching, locking and 
security support.

=head1 SYNOPSIS

Open a configuration file and get a Unix::Conf::ConfIO object.

    use Unix::Conf;

    my $conf = Unix::Conf->_open_conf (
        NAME            => 'some_file',
        SECURE_OPEN     => 1,
        LOCK_STYLE      => 'dotlock',
    );
    $conf->die ('DEAD') unless ($conf);

    # use the file in various ways
    print while (<$conf>);
    $conf->setline (10, "this is the 11th line\n");
    $conf->close ();

=head1 DESCRIPTION

ConfIO is designed to be a class for handling I/O for configuration
files with support for locking and security. At the time of creation
all the data in the file is read in and stored in an array, where each
line is assumed to be one line of the file. It is the responsibility of
the user to ensure that while appending or setting lines, the data ends
in a newline. While this is not enforced it could cause the lineno
counter to get confused.

=cut

package Unix::Conf::ConfIO;

use 5.6.0;
use strict;
use warnings;

use Fcntl qw (:DEFAULT :mode :flock);
use Unix::Conf;

use overload '<>'	=> 'getline',
			 'bool'	=> '__interpret_as_bool',
			 '""'	=> '__interpret_as_string',
			 'eq'	=> '__interpret_as_string';

# Cache of file keyed on filenames. Value is a hash reference.
# {
#	NAME, 
#	FH, 
#	MODE,
#	PERMS,
#	DATA, 
#	TIMESTAMP,
#	LINENO, 
#	LOCK_STYLE,
#	DIRTY,
#	PERSIST,
#	IN_USE,
# }
# FH is true if the file is currently in use (the filehandle is stored there).
# TIMESTAMP is used to see if the file contents have been changed.
# PERSIST is used for those files that need to be held and not
# released even when their destructors have been called. This is needed for
# cases where the file obj goes out of scope, but the file is not closed
# here thus not releasing the lock on that file. This eases the task of
# maintaining the filehandle by the user of this module.
my %File_Cache;

# This hash contains an entry for every module that calls us. If persistent
# open is called, such files are stored as values for the key, which is the
# calling module name. Thus, when release_all is called, we know exactly which
# persistent files are to be released.
my %Calling_Modules;

=over 4

=item open ()

    Arguments
    NAME        => 'PATHNAME',
	FH			=> filehandle			# filehandle, reference to a filehandle
    MODE        => FILE_OPEN_MODE,      # default is O_RDWR | O_CREAT
    PERMS       => FILE_CREATION_PERMS, # default is 0600
    LOCK_STYLE  => 'flock'/'dotlock',   # default is 'flock'
    SECURE_OPEN => 0/1,                 # default is 0 (disabled)
    PERSIST     => 0/1,                 # default is 0 (disabled)

Class constructor. 
Creates a ConfIO object which is associated with the file. 
Releasing the object automatically syncs with the disk version of 
the file. Passing an open filehandle with FH creates a 
Unix::Conf::ConfIO object representing the open file. Take care
to open FH in both read & write mode, because Unix::Conf::ConfIO
reads in the whole file into an in core array as of now.
MODE and PERMS are the same as for sysopen. LOCK_STYLE 
is for choosing between different locking methods. 'dotlock' is 
used for locking '/etc/passwd', '/etc/shadow', '/etc/group', 
'/etc/gshadow'. 'flock' is the default locking style. If the 
value of SECURE_OPEN is 1, it enables a check to see if PATHNAME 
is secure. PERSIST is used to keep files open till release () 
or release_all () is called even though the object may go out 
of scope in the calling code. It reduces the overhead of 
managing ancillary files. Otherwise the file locks associated
with the file would be released for these anciallary files.
TODO: Need to implement ability to accept open filehandles,
IO::Handle, IO::File objects too.
NOTE: This method should not be used directly. Instead use
Unix::Conf::_open_conf () which has the same syntax.

    Example
    use Unix::Conf;
    my $conf;
    $conf = Unix::Conf->_open_conf (
        NAME			=> '/etc/passwd',
        SECURE_OPEN		=> 1,
        LOCK_STYLE		=> 'dotlock',
    ) or $conf->die ("Could not open '/etc/passwd'");

	# or attach a filehandle to a Unix::Conf object.
    $conf = Unix::Conf->_open_conf (
		FH				=> FH,		# or any object that represents an open filehandle
    ) or $conf->die ("Could not attach FH");

=cut
	
sub open
{
	my $class = shift ();
	my $args = {
		LOCK_STYLE	=> 'flock',
		MODE		=> O_RDWR | O_CREAT,
		PERMS		=> 0600,
		SECURE_OPEN	=> 0,
		PERSIST		=> 0,
		@_,
	};

	my ($fh, $name, $timestamp, $retval);

	# do sanity check on the passed argument
	return (Unix::Conf->_err ('open', "neither filename nor filehandle passed"))
		unless (defined ($args->{FH}) || defined ($args->{NAME}));

	if ($args->{FH}) {
		return (Unix::Conf->_err ("open", "`$args->{LOCK_STYLE}' illegal with FH"))
			if ($args->{LOCK_STYLE} ne 'flock');
		return (Unix::Conf->_err ("open", "`SECURE_OPEN' illegal with FH"))
			if ($args->{SECURE_OPEN});
		# store the filehandle name as the name of the file.
		# this is needed for persistent opens where the handle 
		# is cached in $Calling_Modules.
		$args->{NAME} = "$args->{FH}";
		$args->{FILEHANDLE_PASSED} = 1;
		$fh = $File_Cache{$args->{NAME}} = $args
			unless (($fh = $File_Cache{$args->{NAME}}));
		# fh now contains the old ConfIO object if one with the same
		# name exists

		# if file is locked in our cache return Err
		return (Unix::Conf->_err ('open', "`$fh->{NAME}' already in use, locked"))
			if ($fh->{IN_USE});
		$retval = __lock ($fh) or return ($retval);
	}
	elsif ($args->{NAME}) {
		$fh = $File_Cache{$args->{NAME}} = $args
			unless (($fh = $File_Cache{$args->{NAME}}));
		# fh now contains the old ConfIO object if one with the same
		# name exists

		# if file is locked in our cache return Err
		return (Unix::Conf->_err ('open', "`$fh->{NAME}' already in use, locked"))
			if ($fh->{IN_USE});
	
		# if FH exists, file must be a persistent one. we call __checkpath
		# if SECURE_OPEN was specified, and not before. However any change in
		# modes we barf
		if ($fh->{FH}) {
			my $ret;
			$ret = __checkpath ($fh->{NAME}) or return ($ret)
				if ($args->{SECURE_OPEN} > $fh->{SECURE_OPEN});
			my ($oldmode, $newmode);
			$oldmode = $fh->{MODE} & (O_RDONLY | O_WRONLY | O_RDWR);
			$newmode = $args->{MODE} & (O_RDONLY | O_WRONLY | O_RDWR);
			return (Unix::Conf->_err ('open', "mode is not the same as in the original open"))
				if ($oldmode != $newmode); 
		}
		else {
			# file is not in cache, or is but had been previously closed.
			# we need to open file even if our cache has good data, and lock the file
			$fh->{FH} = __open (
								$fh->{NAME}, 
								$fh->{MODE}, 
								$fh->{PERMS}, 
								$fh->{SECURE_OPEN}
			) or return ($fh->{FH});

			unless ($retval = __lock ($fh)) {
				close ($fh->{FH});
				return ($retval);
			}
		}
	}
	# check timestamp even if file was held in persistent store and locked
	$timestamp = (stat ($fh->{FH}))[9];
	# if we had previously cached the file and it has not changed since
	# bless and return.
	if (!defined ($fh->{TIMESTAMP}) || $fh->{TIMESTAMP} != $timestamp) {
		# if we reach here, either we don't have the file in our cache, 
		# the cache is stale.
		return (Unix::Conf->_err ("open")) unless (seek ($fh->{FH}, 0, 0));
		my @lines = readline ($fh->{FH});
		@$fh{'DATA', 'TIMESTAMP'} = (\@lines, $timestamp);
	}

	@$fh{'LINENO', 'DIRTY'} = (-1, 0);
	$fh->{IN_USE} = 1;
	# store files that the calling module wants persisted. subsequently
	# when release_all is called by the same module, these will be actually 
	# released (locks)
	$Calling_Modules{__caller ()}{$fh->{NAME}} = 1
		if ($fh->{PERSIST});
	my $instance = $fh->{NAME};
	my $obj = bless (\$instance, $class);
	return ($obj);
}

=item close ()

Object method.
Syncs the cache to disk and releases the lock on the file unless
the file was opened with PERSIST enabled. However the cache of data
is maintained in the hope that it will still be useful and obviate
the necessity for a read of all the data.
Returns true or an Err object in case of error.

=cut

# method instance. can also be called as a subroutine with the filename as the 
# first arg.
sub close
{
	my $self = shift ();
	my $file = ref ($self) ? $File_Cache{$$self} : $File_Cache{$self};

	return (Unix::Conf->_err ('close', "object already closed"))
		unless ($file->{FH});

	# sync file if dirty
	if ($file->{DIRTY}) {
		truncate ($file->{FH}, 0) or return (Unix::Conf->_err ("truncate"));
		sysseek ($file->{FH}, 0, 0) or return (Unix::Conf->_err ("sysseek"));

		# suppress warnings so that we don't get a warning about empty
		# array elements that we delete'ed.
		no warnings;
		syswrite ($file->{FH}, $_ ) for (@{$$file{DATA}});
	}

	$file->{TIMESTAMP} = (stat ($file->{FH}))[8];	# store new timestamp.
	$file->{IN_USE} = 0;

	# if persistent file, do not close
	return (1) if ($file->{PERSIST});

	close ($file->{FH}) || return (Unix::Conf->_err ('close'));
	__unlock ($file);
	delete ($File_Cache{$file->{NAME}}) if ($file->{FILEHANDLE_PASSED});
	undef ($file->{FH});
	return (1);
}

sub DESTROY 
{
	my $self = shift ();
	my $obj = $File_Cache{$$self};
	my $retval;

	# if FH is still set, call close
	if ($obj->{FH}) {
		$retval	= $self->close () or $retval->die ('Unix::Conf::ConfIO DESTRUCTOR failed'); 
	}
}

sub secure_open 
{
	my $self = shift ();
	my $obj = $File_Cache{$$self};
	return ($obj->{SECURE_OPEN}); 
}

=item release ()

Object method.
Closes the file and releases the lock if opened with PERSIST.
Returns true or an Err object in case of error.

=cut

sub release
{
	my $self = shift ();
	my $obj = $File_Cache{$$self};

	# if FH is still set, call close
	if ($obj->{FH}) {
		# clear PERSIST so that close below can actually close
		$obj->{PERSIST} = 0;
		my $caller = __caller ();
		#
		# check to see the sanity check works properly.
		#
		return (Unix::Conf->_err ('release', "This file was not opened with PERSIST by $caller"))
			unless (exists ($Calling_Modules{$caller}{$$self}));
		delete ($Calling_Modules{$caller}{$$self});
		return ($self->close ()); 
	}
	return (1);
}

=item release_all ()

Class method.
Closes all files opened with PERSIST by a specific class. This can
be called from the destructor for that class, allowing hassle free
operation for ancillary files.
Returns true or an Err object in case of error.

=cut

sub release_all
{
	my $caller = __caller ();
	my ($obj, $ret);

	return (Unix::Conf->_err ('release_all', "No files were opened with PERSIST by $caller"))
		unless (exists ($Calling_Modules{$caller}));
	for (keys(%{$Calling_Modules{$caller}})) {
		$obj = $File_Cache{$_};
		$obj->{PERSIST} = 0;
		# call method close with the filename as arg
		$ret = &close ($_) or return ($ret);
	}
	delete ($Calling_Modules{$caller});
	return (1);
}

=item dirty ()

Object method.
Mark the file cache as dirty explicitly.

=cut

sub dirty
{
	my $self 	= $File_Cache{${shift ()}};
	$self->{DIRTY} = 1;
	return (1);
}

=item name ()

Object method.
Returns the name of the associated file.

=cut
	
sub name 	
{
	my $self 	= $File_Cache{${shift ()}};
	return ($self->{FILENAME});
}

=item rewind ()

Object method.
Rewind the file to the beginning of the data.

=cut

sub rewind
{
	my $self	= $File_Cache{${shift ()}};
	$self->{LINENO} = -1;
	return (1);
}

=item next_lineno ()

Object method.
Returns max lineno + 1. 

=cut

sub next_lineno
{
	my $self    = $File_Cache{${shift ()}};
	return (scalar (@{$self->{DATA}}));
}

=item set_scalar ()

    Arguments
    SCALAR_REF,

Object method.
Pass reference to a scalar. The file data will be set to the value
of the scalar.
Returns true.

=cut

sub set_scalar
{
	no warnings;
	my $self    = $File_Cache{${shift ()}};
	# release the old data
	undef ($self->{DATA});
	$self->{DATA} = [ split (/^/, ${$_[0]}) ];
	$self->{DIRTY} = 1;
	return (1);
}

=item getlines ()

Object method.
Returns reference to the cache array.
NOTE: If the caller then changes the array in anyway it is his/her
responsibility to mark the cache as dirty.

=cut

sub getlines	
{ 
	my $self 	= $File_Cache{${shift ()}};
	return ($self->{DATA}); 	
}

=item setlines ()

    Arguments
    ARRAY_REF,

Object method.
Store the array referenced by ARRAY_REF as the file cache. It is
assumed that each element of the file will be a line of data with a
trailing newline, though it is not a necessity.
Returns true or an Err object in case of error.

=cut

sub setlines	
{
	my $self 	= $File_Cache{${shift ()}};
	my $openmode = $self->{MODE} & O_ACCMODE;
	return (Unix::Conf->_err ('setlines', "file $self->{FH} not opened for writing"))
		if ($openmode != O_WRONLY && $openmode != O_RDWR);
	$self->{DATA} = shift;  	
	$self->{DIRTY} = 1;
	return (1);
}

=item delete ()

Object method.
Delete all lines in the file.
Returns true or an Err object in case of error.

=cut

sub delete
{
    my $self    	= $File_Cache{${shift ()}};
	my $openmode = $self->{MODE} & O_ACCMODE;
	return (Unix::Conf->_err ('delete', "file $self->{FH} not opened for writing"))
		if ($openmode != O_WRONLY && $openmode != O_RDWR);
	$self->{LINENO}	= -1;
	undef (@{$self->{DATA}});
	$self->{DIRTY}	= 1;
	return (1);
}

=item lineno ()

Object method.
Get/set the current lineno of the ConfIO object.

=cut

sub lineno 		
{ 
	my $self 	= $File_Cache{${shift ()}};
	my $lineno	= shift ();
	if (defined ($lineno)) {
		return (Unix::Conf->_err ('lineno', "argument passed not numeric"))
			if ($lineno !~ /^-?\d+$/);
		return (Unix::Conf->_err ('lineno', "`$lineno' value illegal"))
			if ($lineno < -1);
		my $max = $#{$self->{DATA}};
		return (Unix::Conf->_err ('lineno', "argument passed out of bounds, max possible `$max'"))
			if ($lineno > $max);
		$self->{LINENO} = $lineno;
		return (1);
	}
	return ($self->{LINENO}); 	
}

=item getline ()

Object method.
Returns the next line.

=cut

sub getline
{
	my $self = $File_Cache{${shift ()}};
	return ( $self->{DATA}[++($self->{LINENO})] );
}

=item setline ()

    Arguments
    LINENO,
    SCALAR,

Object method.
Set LINENO to value of SCALAR.
Returns true or an Err object in case of error.

=cut

sub setline
{
	my $self = $File_Cache{${shift ()}};

	my $openmode = $self->{MODE} & O_ACCMODE;
	return (Unix::Conf->_err ('setline', "file $self->{FH} not opened for writing"))
		if ($openmode != O_WRONLY && $openmode != O_RDWR);
	$self->{DATA}[$_[0]] = $_[1];
	$self->{DIRTY} = 1;
	return (1);
}

=item append ()

    Arguments
    LIST,

Object method.
Append LIST to the end of the file.
Returns true or an Err object in case of error.

=cut

sub append
{
	my $self = $File_Cache{${shift ()}};
	my $openmode = $self->{MODE} & O_ACCMODE;
	return (Unix::Conf->_err ('append', "file $self->{FH} not opened for writing"))
		if ($openmode != O_WRONLY && $openmode != O_RDWR);
	push (@{$self->{DATA}}, @_);
	$self->{DIRTY} = 1;
	return (1);
}

=item delete_lines ()

    Arguments
    START_LINENO,
    END_LINENO,

Object method.
Delete from START_LINENO to END_LINENO including.
Returns true or an Err object in case of error.

=cut

sub delete_lines
{
	my $self = $File_Cache{${shift ()}};
	my $openmode = $self->{MODE} & O_ACCMODE;
	return (Unix::Conf->_err ('delete_lines', "file $self->{FH} not opened for writing"))
		if ($openmode != O_WRONLY && $openmode != O_RDWR);
	return (Unix::Conf->_err ('delete_lines', "offset not specified"))
		unless (defined ($_[0]));
	my $start = $_[0];	
	my $end = $_[1] ? $_[1] : $start;
	delete (@{$self->{DATA}}[$start..$end]);
	$self->{DIRTY} = 1;
	return (1);
}

=item ungetline ()

Object method.
Rewind the current lineno pointer.
Returns true.

=cut
	
sub ungetline			
{  
	my $self = $File_Cache{${shift ()}};
	($self->{LINENO})--; 	
	return (1);
}

sub __caller { return ((caller (1))[0]); }

# If a ConfIO object has a defined filehandle it is true, else false
sub __interpret_as_bool	
{
	my $self = $File_Cache{${shift ()}};
	return ($self->{IN_USE}); 
}

sub __interpret_as_string
{
	my $self = shift;
	return "$$self";
}

sub __lock ($)
{
	my ($fh) = @_;

	($fh->{LOCK_STYLE} eq 'flock') 	&& do {
		flock ($fh->{FH}, LOCK_EX | LOCK_NB) || return (Unix::Conf->_err ('flock'));
		return (1);
	};
	($fh->{LOCK_STYLE} eq 'dotlock') 	&& do {
		return (__dotlock ($fh->{NAME}));
	};
}

sub __unlock ($)
{
	my ($fh) = @_;

	($fh->{LOCK_STYLE} eq 'flock')		&& do {
		# no unlocking necessary. when the appropriate fh is released or
		# close called on it the lock will be automatically released.
		return (1);
	};
	($fh->{LOCK_STYLE} eq 'dotlock')	&& do {
		unlink ("$fh->{NAME}.lock") or return (Unix::Conf->_err ('unlink'));
	    return (1);
	};
}

# ARGUMENTS: filename to be locked
# RETURN:    BOOL indicating failure or success.
# Locks files.
# Create a unique file from the filename (filename.pid). Write our PID into 
# pidfile. link to filename.lock. If filename.lock nlink is 2 then we have 
# succeded, unlink pidfile. If link fails then read the PID from the (already) 
# existing lockfile. Post 0 to that PID. If no such process exists, lock file 
# is stale and hence unlink it. loop again. All of this is because, opening
# the actual lock file and writing out the PID into it is not atomic. So we
# create an tmp unique file, write out our PID into it and then try linking it
# which is atomic, since it translates into a single system call.
sub __dotlock ($)
{
    my $file = shift;
    my ($pidfile, $lockfile) = ("$file.$$", "$file.lock");
    my $retval;

    sysopen (FH, $pidfile, O_WRONLY | O_CREAT || O_EXCL, 0600)
        or return (Unix::Conf->_err ('sysopen'));
    print FH "$$\x00"	or return (Unix::Conf->_err ('new'));
    CORE::close (FH)	or return (Unix::Conf->_err ('close'));

    # keep looping until we lock or return inside loop
    until (link ($pidfile, $lockfile)) {
        my $pid;
        unless (sysopen (FH, $lockfile, O_RDONLY)) {
            $retval = Unix::Conf->_err ('sysopen');
            goto ERR_RET;
        }
        $pid = <FH> || goto ERR_RET;
        $pid = substr ($pid, 0, -1);
        CORE::close (FH) || goto ERR_RET;
        # if process is alive unlink opened files and return undef
        if (kill (0, $pid)) {
            $retval = Unix::Conf->_err ('kill');
            goto ERR_RET;
        }
        unlink ($lockfile);
    }

    $retval = __check_link_count ($pidfile);
    unlink ($pidfile);
    return $retval;

ERR_RET:
    unlink ($pidfile);
    return ($retval);
}

# check link count of argument and return true if link count == 2
sub __check_link_count ($)
{
    my $file = shift;
    my $nlink;
    (undef, undef, undef, $nlink) = stat ($file)
        or return (Unix::Conf->_err ('stat'));

    return (1) if ($nlink == 2);
    # failure. set _err and return failure
    return (Unix::Conf->_err ('__check_link_count', 'link count of $file is $nlink'));
}

# ARGUMENTS: file_path, mode, perms, secure
# if secure is true then security checks are done on the pathname to see
# if any component is writeable by anyone other than root. if so return
# error.
sub __open ($$$$)
{
	my ($file_path, $mode, $perms, $secure) = @_;
	
	my ($fh, $ret);
    sysopen ($fh, $file_path, $mode, $perms) || 
		return (Unix::Conf->_err ("sysopen ($file_path)"));

	if ($secure) {
		$ret = __checkpath ($file_path) or return ($ret);
	}
	return ($fh);
}

sub __checkpath ($)
{
	my $file_path = $_[0];

	my @chopped = split (/\//, $file_path);
	# if $chopped[0] is "" then the path was absolute.
	if ($chopped[0]) {
		# is using `pwd` safe ?
		my $cwd = `pwd`;
		chomp ($cwd);
		unshift (@chopped, split (/\//, $cwd));
	}
	my ($uid, $gid, $mode);
	my $path = "";
	foreach (@chopped) {
		# on the second iteration $path will be just '/'.
		$path .= ($path =~ /^\/$/) ? "$_" : "/$_";
		($mode, $uid, $gid) = (stat ($path))[2,4,5];
		# check ownership
		return (Unix::Conf->_err ('__open', "$file_path resides in an insecure path ($path)")) 
			if ($uid != 0 || $gid != 0);
		# check to see if others have write perms
		return (Unix::Conf->_err ('__open', "$file_path resides in an insecure path ($path)"))
			if ($mode & S_IWOTH);
	}
	return (1);
}

1;
__END__


=head1 STATUS

Beta

=head1 TODO

This module should accept a scalar representing a file too.

=head1 BUGS

None that I know of.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with the program; if not, write to the Free Software Foundation, Inc. :

59 Temple Place, Suite 330, Boston, MA 02111-1307

=head1 COPYRIGHT

Copyright (c) 2002, Karthik Krishnamurthy <karthik.k@extremix.net>.
