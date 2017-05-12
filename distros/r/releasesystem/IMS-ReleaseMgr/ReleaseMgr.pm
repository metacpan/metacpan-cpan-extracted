###############################################################################
#
#          May be distributed under the terms of the artistic license
#
#                  Copyright @ 1998, Hewlett-Packard, Inc.,
#                            All Rights Reserved
#
###############################################################################
#
#   @(#)$Id: ReleaseMgr.pm,v 1.22 2000/05/26 21:55:02 idsweb Exp $
#
#   Description:    This module is designed for the purpose of abstracting the
#                   Perl <-> Release Manager interface, specifically for the
#                   sake of Perl applications that need to create packages that
#                   Release Manager is expected to find and deploy.
#
#   Functions:      new
#                   validate
#                   error
#                   sync
#                   commit
#                   cleanup
#                   close
#                   abort
#                   DESTROY
#
#   Libraries:      None.
#
#   Global Consts:  $VERSION            Version information for this module
#                   $revision           Copy of the RCS revision string
#
#   Environment:    None.
#
###############################################################################
package IMS::ReleaseMgr;

use 5.004;
use strict;
use vars qw($VERSION $version $revision);
use Carp;
use IO::File;

require Archive::Tar;

# This first one is used for tests to see that we have a recent-enough version
$VERSION = 1.12;
$version = do {my @r=(q$Revision: 1.22 $=~/\d+/g);sprintf "%d."."%02d"x$#r,@r};
$revision =
    q{$Id: ReleaseMgr.pm,v 1.22 2000/05/26 21:55:02 idsweb Exp $ };

1;

###############################################################################
#
#   Sub Name:       new
#
#   Description:    Object constructor. Checks that sufficient information
#                   was provided in the argument list, and if so creates the
#                   new object, blesses, and copies data from %args to the
#                   object.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      varies    Identifies the class to bless
#                                                 into. May be a string (a
#                                                 static constructor) or an
#                                                 existing object of this class
#                                                 (dynamic constructor).
#                   %opts     in      list      All the remaining input
#                                                 elements auto-converted into
#                                                 this hash for checking.
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    new reference to object
#                   Failure:    undef
#
###############################################################################
sub new
{
    my $class = shift;
    my %opts  = @_;


    #
    # Check for the required arguments in the passed-in values
    #
    if (! exists $opts{name})
    {
        carp "new: missing required parameter ``name'', ";
        return undef;
    }
    unless (exists $opts{file} or exists $opts{filehandle})
    {
        carp "new: one of ``file'' or ``filehandle'' parameters must be " .
            'specified, ';
        return undef;
    }

    #
    # This approach lets new() work correctly whether called as
    #
    # $val = new IMS::ReleaseMgr
    # -or-
    # $val = IMS::ReleaseMgr->new
    # -or-
    # $val = $old->new
    #
    # when $old is an object of this class.
    #
    $class = ref($class) || $class;
    my $self = bless {}, $class;

    $self->{name} = $opts{name};
    # The file option takes precedence over filehandle
    if (exists $opts{file})
    {
        $self->{file} = $opts{file};
        $self->{filehandle} = undef;
    }
    else
    {
        $self->{filehandle} = $opts{filehandle};
        $self->{file} = undef;
    }
    # Not required at this point, because commit() can override it
    $self->{directory} = $opts{directory} || '';

    #
    # Handle any/all e-mail addresses specified
    #
    $self->{email} = '';
    $self->{email} = $opts{email} if (defined $opts{email} and $opts{email});
    if (defined $opts{emails} and ref($opts{emails}) eq 'ARRAY')
    {
        my @list = @{$opts{emails}};
        $self->{email} .= " @list" if (scalar @list);
    }
    $self->{email} =~ tr/, /,/s;
    $self->{email} =~ s/^,//o;
    $self->{dest} = $opts{dest} if defined $opts{dest};

    #
    # Other misc. special-purpose options
    #
    $self->{other_opts} = {};
    for (keys %opts)
    {
        $self->{other_opts}->{$_} = $opts{$_} unless (exists $self->{$_});
    }

    #
    # Date/time stamp
    #
    my ($min, $hour, $mday, $mon, $year) = (localtime)[1 .. 5];
    $hour %= 100; $mon++;
    $self->{datestamp} = sprintf("%02d%02d%02d-%02d%02d",
                                 $year, $mon, $mday, $hour, $min);

    #
    # Initialize a few other fields so that tests of them don't generate
    # noise under -w.
    #
    for (qw(validated error_text error_file error_line ark_temp_file))
    {
        $self->{$_} = undef;
    }

    $self;
}

###############################################################################
#
#   Sub Name:       validate
#
#   Description:    Verify the data in the archive portion of the object.
#                   If the archive was specified as a filehandle, it is first
#                   written to a temporary file (which is noted for future
#                   operations).
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $%opts    in      list      Options passed in
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    $self
#                   Failure:    undef
#
###############################################################################
sub validate
{
    my $self = shift;
    my %opts = @_;

    my ($line, @contents, @parts, @bad_lines, $bad_lines, $weblist_seen);

    $self->{validated} = 0;
    # Ensures that there is a physical file to tar tf on
    return undef if (! defined($self->sync));

    #
    # Control the verbosity of the error text
    #
    my $verbose = (defined $opts{verbose} and $opts{verbose}) ? 1 : 0;

    #
    # Choose the file to read (a passed-in file would take precendence over
    # the temp file from a filehandle argument) and pass it to Archive::Tar
    #
    my $file = $self->{file} || $self->{ark_temp_file} || undef;
    if (! defined $file)
    {
        $self->error("Panic error! No file found, but should exist at this " .
                     "point. Something is wrong.", __FILE__, __LINE__);
        return undef;
    }

    $weblist_seen = $bad_lines = 0;
    @contents = Archive::Tar->list_archive($file);
    for $line (@contents)
    {
        if ($line =~ /symbolic link/o)
        {
            $bad_lines++;
            push(@bad_lines, "SYMLINKS NOT ALLOWED: $line") if ($verbose);
        }
        if ($line =~ /\.\./o)
        {
            $bad_lines++;
            push(@bad_lines, "NO ``..'' IN PATHS: $line") if ($verbose);
        }
        if ($line =~ m| /|o)
        {
            $bad_lines++;
            push(@bad_lines, "ABSOLUTE PATH NOT ALLOWED: $line") if ($verbose);
        }
        # Just in case some project use Weblist rather than weblist
        $weblist_seen++ if ($line =~ m|/[Ww]eblist|o);
    }

    if ($bad_lines)
    {
        if ($verbose)
        {
            $self->error("Insecure entries detected in tar archive:\n" .
                         join(', ', @bad_lines), __FILE__, __LINE__);
        }
        else
        {
            $self->error('Insecure entries detected in tar archive',
                         __FILE__, __LINE__);
        }
    }
    elsif (! $weblist_seen)
    {
        $self->error('No weblist file found in the tar archive',
                     __FILE__, __LINE__);
    }
    else
    {
        $self->error('', '', '');
        $self->{validated} = 1;
    }

    return ($self->{validated}) ? $self : undef;
}

###############################################################################
#
#   Sub Name:       error
#
#   Description:    Return/set error text.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   $text     in      scalar    If exists and is defined, set
#                   $file     in      scalar      the error vaules to this.
#                   $line     in      scalar
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    text (possibly null)
#                   Failure:    no failure possibility
#
###############################################################################
sub error
{
    my $self = shift;
    my $text = shift;
    my $file = shift;
    my $line = shift;

    $self->{error_text} = $text if (defined $text);
    $self->{error_file} = $file if (defined $file);
    $self->{error_line} = $line if (defined $line);

    #
    # Return nothing if wantarray returns undef (void context), return just
    # the text if wantarray is false (scalar context) and return the triple
    # if it is true.
    #
    return if (! defined wantarray);
    return ((wantarray) ?
            ($self->{error_text}, $self->{error_file}, $self->{error_line}) :
            ($self->{error_text}));
}

###############################################################################
#
#   Sub Name:       sync
#
#   Description:    Ensure that any temporary data is in sync with changes,
#                   etc., prior to a commit operation. Usually just called by
#                   commit() or validate(), though should not be a problem if
#                   called multiple times.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    $self
#                   Failure:    undef
#
###############################################################################
sub sync
{
    my $self = shift;

    return $self if (defined $self->{syncronized} and $self->{synchronized});

    if (defined $self->{file} and $self->{file})
    {
        $self->{synchronized} = 1;
    }
    elsif (defined $self->{ark_temp_fh} and $self->{ark_temp_fh})
    {
        seek $self->{ark_temp_fh}, 0, 0;
        $self->{synchronized} = 1;
    }
    elsif (defined $self->{filehandle} and $self->{filehandle})
    {
        no strict 'refs'; # In case the filehandle is a symbolic ref

        # Pick a tempfile name using PID and package name
        my $tempfile = '/tmp/' . __PACKAGE__ . "-$$-00";
        # In case of strays or other instances of this class in this process
        $tempfile++ while (-e $tempfile);
        # Open for reading and writing, with initial truncation
        my $out_fh = new IO::File "+> $tempfile";
        if (! defined $out_fh)
        {
            $self->error("Error opening $tempfile for read/write: $!",
                         __FILE__, __LINE__);
            return undef;
        }
        my $bytesread;
        my $buffer = '';
        my $infile = $self->{filehandle};
        while ($bytesread = read($infile, $buffer, 1024))
        {
            print $out_fh $buffer;
        }

        #
        # Save these for future ease-of-use
        #
        $self->{ark_temp_file} = $tempfile;
        $self->{ark_temp_fh} = $out_fh;
        seek $self->{ark_temp_fh}, 0, 0;
        $self->{synchronized} = 1;
    }
    else
    {
        $self->error('sync: unable to locate input file or input filehandle',
                     __FILE__, __LINE__);
        return undef;
    }

    $self->error('', '', '');
    $self;
}

###############################################################################
#
#   Sub Name:       commit
#
#   Description:    Commit the data that this object refers to to the pre-
#                   determined place. Basically moves the archive to the
#                   release manager area, and writes the info file in the
#                   same directory.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   %opts     in      list      Any passed-in arguments
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    $self
#                   Failure:    undef
#
###############################################################################
sub commit
{
    my $self = shift;
    my %opts = @_;

    use File::Copy qw(copy move);

    $self->{directory} = $opts{directory}
        if (defined $opts{directory} and $opts{directory});

    unless (defined $self->{directory} and $self->{directory})
    {
        $self->error('No directory specified for commit operation',
                     __FILE__, __LINE__);
        return undef;
    }
    unless (defined $self->{validated} and $self->{validated})
    {
        $self->error('Package must be validated before being committed',
                     __FILE__, __LINE__);
        return undef;
    }

    my ($tarfile, $infofile, $ofh, $bytesread, $buffer, $basename);
    ($basename = $self->{name}) =~ s/[\s\*\+\&\!\$\(\)]/_/g;
    $tarfile = "$self->{directory}/$basename-$self->{datestamp}.tar";
    $tarfile .= '.gz' if ((defined $self->{compressed}) and
                          ($self->{compressed} =~ /yes|true|[1-9]/i));
    $infofile = "$self->{directory}/$self->{name}-$self->{datestamp}.info";
    $self->sync;

    if (defined $self->{file} and ($self->{file} ne $tarfile))
    {
        #
        # This is deliberate! We do not want to just rename the file, as
        # there is no way of knowing what is going on outside of this module,
        # and that's a tough side-effect for the end-user to code around.
        #
        if (! copy($self->{file}, $tarfile))
        {
            $self->error("Copy error, $self->{file} to $tarfile: $!",
                         __FILE__, __LINE__);
            return undef;
        }
    }
    elsif (defined $self->{ark_temp_file})
    {
        if (defined $self->{ark_temp_fh})
        {
            close $self->{ark_temp_fh};
            $self->{ark_temp_fh} = undef;
        }
        if (! move($self->{ark_temp_file}, $tarfile))
        {
            $self->error("Copy error, $self->{ark_temp_file} to $tarfile: $!",
                         __FILE__, __LINE__);
            return undef;
        }
        # Success-- undef this object element for the sake of close()
        $self->{ark_temp_file} = undef;
    }
    else
    {
        $self->error('Unable to create the physical tar archive from input',
                     __FILE__, __LINE__);
        return undef;
    }

    #
    # If we've reached this point, then the tar file is OK, and we need only
    # write the info file.
    #
    # Destination is the target subdir of the server root. Defaults to the
    # project name. The leading slash is added later.
    #
    my %other_opts = %{$self->{other_opts}};
    $self->{dest} = $self->{dest} || $self->{destination} ||
        $other_opts{dest} || "/$self->{name}";
    delete $other_opts{dest};
    $self->{user} = $self->{user} || $other_opts{user};
    delete $other_opts{user};
    $self->{name} = $self->{name} || $other_opts{name};
    delete $other_opts{name};
    $self->{email} = $self->{email} || $other_opts{email};
    delete $other_opts{email};
    $ofh = new IO::File "> $infofile";
    if (! defined $ofh)
    {
        $self->error("Unable to open $infofile for writing: $!",
                     __FILE__, __LINE__);
        unlink $tarfile;
        return undef;
    }
    print $ofh "# $self->{name} release ticket - " . (scalar localtime) . "\n";
    print $ofh "# Written by $revision\n";
    print $ofh "Info:dest\t$self->{dest}\n";
    print $ofh "Info:email\t$self->{email}\n";
    print $ofh "Info:name\t$self->{name}\n";
    print $ofh "Info:user\t$self->{user}\n";
    print $ofh "Info:nomail\tyes\n"
        if (defined $self->{nomail} and $self->{nomail});
    print $ofh "Info:compressed\t$self->{compressed}\n"
        if (defined $self->{compressed});
    if (defined $opts{noupload} and $opts{noupload})
    {
        print $ofh "Info:upload\tno\n"
    }
    else
    {
        print $ofh "Info:upload\tyes\n"
    }
    # Do these now, since the old-style checksum has to be last
    print $ofh (map { "Info:$_\t$other_opts{$_}\n" }
                (keys %other_opts));
    if (defined $self->{crc})
    {
        print $ofh "$self->{crc}\n";
    }
    $ofh->close;

    $self->{committed} = 1;
    $self->{tarfile} = $tarfile;
    $self->{infofile} = $infofile;
    $self->error('', '', '');
    $self;
}

###############################################################################
#
#   Sub Name:       cleanup
#
#   Description:    Perform clean-up activities such as clearing out temp
#                   files, etc. Mainly a placeholder in case future expansion
#                   needs it. This shouldn't be needed by users of the module,
#                   it should be enough for them to call close(), which calls
#                   this.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   %opts     in      hash      Named params to the function
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    $self
#                   Failure:    undef
#
###############################################################################
sub cleanup
{
    my $self = shift;
    my %opts = @_;

    if (defined $self->{ark_temp_fh} and $self->{ark_temp_fh})
    {
        close($self->{ark_temp_fh});
        delete $self->{ark_temp_fh};
    }
    if (defined $self->{ark_temp_file} and $self->{ark_temp_file})
    {
        #
        # The nodelete option to this method is to suppress this deletion
        # of temp files. For debugging purposes, mainly.
        #
        unless (defined $opts{nodelete} and $opts{nodelete})
        {
            unlink $self->{ark_temp_file} if (-e $self->{ark_temp_file});
            delete $self->{ark_temp_file};
        }
    }

    $self->error('', '', '');
    $self;
}

###############################################################################
#
#   Sub Name:       close
#
#   Description:    Close out the object. Call cleanup() to make sure any
#                   stray bits are cleaned out, then set the flag that the
#                   destructor checks.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   %opts     in      hash      Named parameters, probably
#                                                 filtered through from some-
#                                                 where else. This routine as
#                                                 published should have no opts
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    $self
#                   Failure:    undef
#
###############################################################################
sub close
{
    my $self = shift;
    my %opts = @_;

    $self->cleanup(%opts);
    $self->{closed} = 1;

    $self->error('', '', '');
    $self;
}

###############################################################################
#
#   Sub Name:       abort
#
#   Description:    Unconditionally destroy this object and free up any temp
#                   material. Used when an error condition requires exit after
#                   validation but prior to disk committment.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#                   %opts     in      hash      Options passed to this routine
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        1
#
###############################################################################
sub abort
{
    my $self = shift;
    my %opts = @_;

    # Pass any opts on to close(), which will pass them along to cleanup()
    $self->close(%opts) if (defined $self->{validated} and $self->{validated});
    delete $self->{validated}; # This suppresses the noise from DESTROY

    1;
}

###############################################################################
#
#   Sub Name:       DESTROY
#
#   Description:    Before freeing up the object, make sure that any data
#                   was properly saved/committed/etc. beforehand. Complain
#                   loudly if it wasn't.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        doesn't, really...
#
###############################################################################
sub DESTROY
{
    my $self = shift;

    if (defined $self->{validated} and $self->{validated})
    {
        unless (defined $self->{committed} and $self->{committed})
        {
            warn "IMS::ReleaseMgr::DESTROY -- freeing object that has not " .
                "been committed to disk, ";
        }
        unless (defined $self->{closed} and $self->{closed})
        {
            warn "IMS::ReleaseMgr::DESTROY -- freeing object that has not " .
                "been properly closed/cleaned, ";
        }
    }

    undef $self;
}

__END__

=head1 NAME

IMS::ReleaseMgr - Perl extension for managing IMS Release Manager packages

=head1 SYNOPSIS

    use IMS::ReleaseMgr;

    $P = new IMS::ReleaseMgr(name => 'mpgcpd',
                             email => 'contractor@aol.com',
                             file => '/tmp/inbound/mpgcpd.tar');
    $P->validate;
    if (! $P->commit(directory => '/opt/ims/incoming'))
    {
        die "Error attempting to commit package: " . $self->error .
            "\nStopped ";
    }
    $P->close;

    exit 0;

=head1 DESCRIPTION

The B<IMS::ReleaseMgr> package is designed to provide an API layer over the
IMSS Release Manager software, for Perl programs. The goal is to provide a
means by which a program can place an archive file and create the release
manager ticket file without the developer being concerned about the finer
implementation points. The interface is implemented in an object-oriented
approach, with an object destructor that verifies a package was saved prior
to destruction (the destruction is unavoidable, but the person running the
application does receive notitification, aiding in problem tracking).

Deploying content to servers is a basic requirement for supporting the
web development environment that IMSS is responsible for. In addition,
for those hostnames that are in fact implemented as a cluster of mirrored
servers, simple writing of the data is not sufficient, as it must also
be propagated to the mirror hosts.

By using this library in place of simply writing data to pre-determined
directories, the release manager is able to step in and manage the deployment
and mirroring of data. This frees the application developer from concerns of
how to ensure successful mirroring.

=head1 METHODS

This interface is implemented as an object class, allowing the data and
functions to be wrapped together and remain transparent to the user.
Unless otherwise noted, any methods that take arguments take them in a
name-value form, such as: B<name> = I<value>. See the sample code above.

The functions and methods available are:

=over

=item new

The object constructor. This initializes and returns an object of the
B<IMS::ReleaseMgr> class. Named arguments are: B<name>, the name of the
project that the content is deploying to; B<file>, the name of the tar
archive file that contains the material being released; B<filehandle>, an
alternative to B<file> that accepts a currently-open filehandle;
B<directory>, the directory on the client side where the release manager
expects incoming files to be placed; B<emails>, a list-reference of e-mail
addresses that should receive the per-stage notification from the release
manager; and B<email>, a short-form of B<emails> that passes a single address
in via a scalar.

=item error

Returns the error text, and possibly the context, of the most recent error.
If called in a scalar context, it returns simply the error text (which may
be the null string). In a list context, it returns a three-value list of the
text, followed by the file in which the code was in, and the line number of
that file. If called in a void context, nothing is returned.

If the B<IMS::ReleaseMgr> class is used as a super-class, then the implementor
of the sub-class may have use of the internal call style: if C<error> is
called with any arguments, they are treated as text, file and line, in that
order. These values are then set as the current error text, etc. This is the
means used internally both to set and clear errors. Applications B<SHOULD NOT>
use these, as the API is not considered public and therefore more succeptible
to change. This form should only be used within the B<IMS::ReleaseMgr> package
or sub-classes.

=item abort

This can be used in place of B<close> below, in cases where a fatal error has
occurred (such as in validation). It performs clean-up and clears flags so that
no warning is generated at object destruction (as a last-gasp measure, the
class destructor makes a final check that the data was indeed written to disk
before being lost). It takes one named parameter, called B<nodelete>, that is
passed unexamined through to the B<cleanup> method. The return value is always
true.

=item validate

Perform certain integrity checks on the archive file portion of the object.
The package must contain a file whose name is either C<weblist> or C<Weblist>.
Additionally, it cannot contain any of: absolute paths, symbolic links, or
relative paths containing the C<..> directory element. These content 
restrictions are to improve security. If the return value is C<undef>, then
there was something wrong (use B<error> to check). The success value returned
is the object value itself (the reference). The only argument accepted is the
named parameter B<verbose>, which if non-null means to include much more
verbose information in the error text generated at failure.

=item commit

This is the means by which to actually put to disk the archive data, and
create the release manager information file. This will fail if no directory
has been specified (either with B<new> or by a parameter to this method) or
if the package has not been validated. The named parameters that are accepted
here are: B<directory>, the directory into which the archive should be placed.
If this was specified in B<new>, it can be overridden here. The other is
B<noupload>, which disables upload-request settings in the release manager
file. The release manager propagates packages throughout a mirrored 
environment; if passed in with a non-null value, this disables that feature.
Great care should be taken in using this feature, as it could cause data to
not be mirrored correctly. The return value is C<undef> on error, object
reference on success.

=item close

This routine checks that data has been successfully commited prior to
object destruction. It calls B<cleanup> if it has not already been called.
This is also a place-holder for either future expansion or for sub-classing.
Return value is C<undef> on error, object reference on success.

=item cleanup

Perform any cleaning tasks that need to be done between data commit and
object destruction. This is called by B<close> if it has not already been
called. Return value is C<undef> on error, object reference on success. It
takes one optional named parameter, B<nodelete>. If set to non-null, it 
prevents the deletion of any temporary files that the B<IMS::ReleaseMgr>
package created during the processing of this object. Since B<close> will
not call B<cleanup> a second time, explicit calling of B<cleanup> with this
parameter set to 1 (or any value) will prevent file deletion and leave the
files in place for debugging and analysis.

=item sync

This is used to ensure that any internal buffers or file-pointers are
syncronized, generally prior to a B<validate> or B<commit>. It is called
by both of those methods, so it is rarely used itself. It is provided as a
hook for sub-classes or for future functionality. Return value is C<undef>
on error, the object reference on success.

=back

The insistence of most methods of returning the object reference upon
success enables chains such as:

    $P = IMS::ReleaseMgr->new()->validate->commit->close;

Such a chain will die after the first link that returns failure. Of course,
it will do so in an exceedingly noisy and ungainful manner, but it may be
useful for Perl one-liners.

=head1 AUTHOR

Randy J. Ray <randyr@nafohq.hp.com>

=head1 SEE ALSO

perl(1).

=cut
