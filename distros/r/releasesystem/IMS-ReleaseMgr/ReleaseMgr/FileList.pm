###############################################################################
#
#         May be distributed under the terms of the artistic license
#
#                  Copyright @ 1998, Hewlett-Packard, Inc.,
#                            All Rights Reserved
#
###############################################################################
#
#   @(#)$Id: FileList.pm,v 1.2 1999/02/23 23:44:56 randyr Exp $
#
#   Description:    Provide an interface by which an application can have files
#                   written locally while also arranging for them to be
#                   propagated to any mirrors of this host.
#
#   Functions:      upload_files
#                   error
#
#   Libraries:      IMS::ReleaseMgr
#
#   Global Consts:  $VERSION            Version information for this module
#                   $revision           Copy of the RCS revision string
#
#   Environment:    None.
#
###############################################################################
package IMS::ReleaseMgr::FileList;

use 5.002;
use strict;
use vars           qw(@ISA @EXPORT @EXPORT_OK $VERSION $revision
                      $error_text $TAR %inc_dirs);
use subs           qw(upload_files error);
use Carp;
use File::Path     qw(mkpath rmtree);
use File::Copy     qw(copy);
use File::Basename qw(dirname);
use Cwd            qw(cwd);

require Exporter;
require IO::File;
require IMS::ReleaseMgr;

$VERSION = do {my @r=(q$Revision: 1.2 $=~/\d+/g);sprintf "%d."."%02d"x$#r,@r};
$revision = q$Id: FileList.pm,v 1.2 1999/02/23 23:44:56 randyr Exp $;
$error_text = '';
$TAR = '/bin/tar';
@ISA = qw(Exporter);
@EXPORT = qw(upload_files error);
@EXPORT_OK = @EXPORT;
%inc_dirs = (
             'www.host.com'          => '/opt/ims/incoming',
             'www.host2.com'         => '/usr/local/etc/httpd/incoming',
            );
1;

###############################################################################
#
#   Sub Name:       upload_files
#
#   Description:    Take the list of files, along with other parameters, and
#                   create a properly-crafted tar file which is then managed
#                   via IMS::ReleaseMgr::new().
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $user     in      scalar    Authenticated user name
#                   $mirror   in      scalar    Mirror group
#                   $project  in      scalar    Name of the project that data
#                                                 is for.
#                   $basedir  in      scalar    Base directory path element(s)
#                                                 under $project for files to
#                                                 be put into
#                   $files    in      hashref   Hash table reference for the
#                                                 files. Keys are file names
#                                                 (rel. to $project/$basedir)
#                                                 and values are either local
#                                                 file names or IO::File refs.
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub upload_files
{
    my ($user, $mirror, $project, $basedir, $files) = @_;

    my ($tmpdir, $tmptar, $cwd, $file, $WL, $PKG, $directory);

    #
    # basic data sanity checks:
    #
    if ($project !~ /^([\w\-\+])+$/o)
    {
        error "The project name ($project) may only contain alphanumerics, " .
            "- and +";
        return 0;
    }
    if ($basedir =~ /\.\./o)
    {
        error "The base-directory specification ($basedir) may not contain " .
            "any occurrances of ``..''";
        return 0;
    }
    if (grep(/\.\./o, (keys %$files)))
    {
        error "The file name specifications may not contain any occurrances " .
            "of ``..''";
        return 0;
    }
    # Make a 'clean' base, without extra // or /./
    $basedir =~ s|^/||go;
    $basedir =~ s|/$||go;
    $basedir =~ s|/\./|/|go;
    $basedir =~ s|//|/|go;

    #
    # Get a name for a temp dir that isn't already in use
    #
    $tmpdir = "/tmp/irMfL-$$";
    $tmpdir++ while (-e $tmpdir);
    umask 02;
    mkpath("$tmpdir/$project/$basedir", 0, 0775);

    $cwd = cwd;
    for $file (sort keys %$files)
    {
        # Leading / not really a problem, but remove them along with trailing
        $file =~ s|^/||go;
        $file =~ s|/$||go;

        #
        # Create any needed subdirectories
        #
        if ($file =~ m|/|o)
        {
            my $dir = dirname $file;
            mkpath "$tmpdir/$project/$basedir/$dir", 0, 0775;
        }
        # If this is not an ordinary scalar-string (name):
        seek($files->{$file}, 0, 0) if (ref $files->{$file});
        if (! copy($files->{$file}, "$tmpdir/$project/$basedir/$file"))
        {
            error "Copy failed to file $tmpdir/$project/$basedir/$file: $!";
            rmtree $tmpdir;
            return 0;
        }
        # Again, if this is not an ordinary scalar-string (name):
        seek($files->{$file}, 0, 0) if (ref $files->{$file});
        chmod 0644, "./$file";
    }

    # Write a weblist for this soon-to-be tar file
    $WL = new IO::File "> $tmpdir/$project/weblist";
    unless (defined $WL)
    {
        error "Could not open $tmpdir/$project/weblist for writing: $!";
        rmtree $tmpdir;
        return 0;
    }
    print $WL "# weblist generated for $user by $revision, " .
        (scalar localtime) . "\n";
    print $WL (map
           {
               ($file = $_) =~ s|^/||go;
               $file =~ s|/$||go;
               $file =~ s|//|/|go;
               $file =~ s|/\./|/|go;
               $file = ($basedir) ? "$basedir/$file" : $file;

               sprintf("%s\t%s\t%s\n",
                       ($file =~ /(jpg|gif|pdf)$/oi) ? 'Fig' : 'Doc',
                       $file, "/$project/" . dirname $file);
           }
               sort (keys %$files));
    $WL->close;

    #
    # Now create the tar file
    #
    chdir $tmpdir;
    if ($?)
    {
        error "Could not chdir to $tmpdir: $!";
        chdir $cwd;
        rmtree $tmpdir;
        return 0;
    }
    #
    # Expect to replace this with Archive::Tar soon
    #
    system("$TAR cf $project.tar $project 2>&1 > /dev/null");
    $? >>= 8;
    if ($?)
    {
        error "System error executing ``$TAR cf $project.tar $project'': $!";
        chdir $cwd;
        rmtree $tmpdir;
        return 0;
    }

    #
    # Later, we'll make this more flexible...
    #
    $directory = $inc_dirs{$mirror} || '/tmp';
    $PKG = new IMS::ReleaseMgr(name      => $project,
                               user      => $user,
                               nomail    => 1,
                               file      => "$tmpdir/$project.tar",
                               directory => $directory);
    unless (defined $PKG)
    {
        error "Unable to create upload package";
        chdir $cwd;
        rmtree $tmpdir;
        return 0;
    }
    unless ($PKG->validate)
    {
        my ($err, $file, $line) = $PKG->error;
        $PKG->abort;
        error "Package upload error detected at $file, line $line: $err";
        chdir $cwd;
        rmtree $tmpdir;
        return 0;
    }

    unless ($PKG->commit)
    {
        my ($err, $file, $line) = $PKG->error;
        $PKG->abort;
        error "Package upload error detected at $file, line $line: $err";
        chdir $cwd;
        rmtree $tmpdir;
        return 0;
    }

    #
    # Successfully processed
    #
    $PKG->close;
    undef $PKG; # Force destructor now, rather than at exit

    error '';

    1;
}

###############################################################################
#
#   Sub Name:       error
#
#   Description:    Get/set the message associated with the most recent error
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $text     in      scalar    If passed, set the error text
#                                                 to this before returning.
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        current error text
#
###############################################################################
sub error
{
    my $text = shift;

    $IMS::ReleaseMgr::FileList::error_text = $text
        if (defined $text and $text);

    $IMS::ReleaseMgr::FileList::error_text;
}

__END__

=head1 NAME

IMS::ReleaseMgr::FileList - Create a simple IMS-compatible upload package.

=head1 SYNOPSIS

    use IMS::ReleaseMgr::FileList;

    ...

    upload_files($user,
                 $mirror_group,
                 $project,
                 $directory_base,
                 {
                  file1 => '/path/to/file1',
                  file2 => $open_fh_on_file2,
                  'dir/file3' => '/diff/path/to/file3'
                 });

    if ($text = error)
    {
        die "Error creating upload package: $text, stopped";
    }

=head1 DESCRIPTION

The IMS::ReleaseMgr::FileList package is a small, generalized interface to
the release manager class, IMS::ReleaseMgr. This interface allows a program to
create small distributions from a handful of files and take advantage of the
existing release management facility to facilitate the actual distribution.
For machines that are one part of a larger mirrored pool, this also ensures
that the files will be propagated to all other members of the mirror pool.

This package is not an object class, like its predecessor. There are only two
routines, which are exported by default.

=head1 ROUTINES

There are two routines exported by this package. If either or both are
expected to conflict with other routines in the application, explicit import
can be used instead:

    use IMS::ReleaseMgr::FileList qw(upload_files); # Don't import error()

and the other routine (IMS::ReleaseMgr::FileList::error) called by 
fully-qualified package name.

These routines are:

=over

=item upload_files($user, $mirror, $project, $dir, $files)

This is the main interface routine. The arguments are:

=over 8

=item $user

A user name to associate with this package transfer. In a more CGI-centric
view, this would be the authenticated user for a page that was 
access-controlled. This information is bundled into the uploaded package.

=item $mirror

The name of the system pool that this is running on, i.e.
"www.interactive.hp.com". This information is used to insure that the package
is delivered into the correct area, and propagated out to the correct subset
of secondary servers.

=item $project

The name of the project, as known by on the server (mpgawg, etc.)

=item $dir

A directory path prefixed to all the file names when the
archive is being created. This has no bearing on the location
of the local files that are read from, it is only here as a
shortcut for groups of files all under the same directory path
relative to $project.

=item $files

A hash-table reference, whose keys are the file names as they will appear in
the archive, and whose values are either names of physical files on the host
filesystem, or open filehandles that can be read from directly. If a value
in this table is a file name, it must either be an absolute path or relative
to the current working directory of the running process. No checks are made
that the paths are correct; failure to open a file means failure of this
routine call. Any values that are file handles (of a reference type GLOB or
IO::File) are first subjected to a seek system-call to make certain the pointer
is at the start of the file. After reading, another seek-to-start is done, so
after the call to this routine all filehandles will be at the head of their
respective files.

=back

Any errors that are encountered are reported via the C<error> routine
documented below. 

=item error

Returns the text of the most recent error, or none if the last call to
C<upload_files> was successful. Note that the return value is not specifically
set to C<undef>, so the test should be looking for a return value that is
both defined B<and> non-null.

=back

=head1 BUGS

None currently known.

=head1 CAVEATS

Any error results in the working directory under B</tmp> to be removed.
There is currently no option to disable this behavior.

=head1 SEE ALSO

L<IMS::ReleaseMgr>

=head1 AUTHOR

Randy J. Ray <randyr@nafohq.hp.com>

=cut
