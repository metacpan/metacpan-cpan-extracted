package DBI::Filesystem;

=head1 NAME

DBI::Filesystem - Store a filesystem in a relational database

=head1 SYNOPSIS

 use DBI::Filesystem;

 # Preliminaries. Create the mount point:
 mkdir '/tmp/mount';

 # Create the databas:
 system "mysqladmin -uroot create test_filesystem"; 
 system "mysql -uroot -e 'grant all privileges on test_filesystem.* to $ENV{USER}@localhost' mysql";

 # (Usually you would do this in the shell.)
 # (You will probably need to add the admin user's password)

 # Create the filesystem object
 $fs = DBI::Filesystem->new('dbi:mysql:test_filesystem',{initialize=>1});

 # Mount it on the mount point.
 # This call will block until the filesystem is mounted by another
 # process by calling "fusermount -u /tmp/mount"
 $fs->mount('/tmp/mount');

 # Alternatively, manipulate the filesystem directly from within Perl.
 # Any of these methods could raise a fatal error, so always wrap in
 # an eval to catch those errors.
 eval {
   # directory creation
   $fs->create_directory('/dir1');
   $fs->create_directory('/dir1/subdir_1a');

   # file creation
   $fs->create_file('/dir1/subdir_1a/test.txt');

   # file I/O
   $fs->write('/dir1/subdir_1a/test.txt','This is my favorite file',0);
   my $data = $fs->read('/dir1/subdir_1a/test.txt',100,0);

   # reading contents of a directory
   my @entries = $fs->getdir('/dir1');

   # fstat file/directory
   my @stat = $fs->stat('/dir1/subdir_1a/test.txt');

   #chmod/chown file
   $fs->chmod('/dir1/subdir_1a/test.txt',0600);
   $fs->chown('/dir1/subdir_1a/test.txt',1001,1001); #uid,gid

   # rename file/directory
   $fs->rename('/dir1'=>'/dir2');

   # create a symbolic link
   $fs->symlink('/dir2' => '/dir1');

   # create a hard link
   $fs->link('/dir2/subdir_1a/test.txt' => '/dir2/hardlink.txt');

   # read symbolic link
   my $target = $fs->read_symlink('/dir1/symlink.txt');

   # unlink a file
   $fs->unlink_file('/dir2/subdir_1a/test.txt');

   # remove a directory
   $fs->remove_directory('/dir2/subdir_1a');

   # get the inode (integer) that corresponds to a file/directory
   my $inode = $fs->path2inode('/dir2');

   # get the path(s) that correspond to an inode
   my @paths = $fs->inode2paths($inode);
 };
 if ($@) { warn "file operation failed with $@"; }
 
=head1 DESCRIPTION

This module can be used to create a fully-functioning "Fuse" userspace
filesystem on top of a relational database. Unlike other
filesystem-to-DBM mappings, such as Fuse::DBI, this one creates and
manages a specific schema designed to support filesystem
operations. If you wish to mount a filesystem on an arbitrary DBM
schema, you probably want Fuse::DBI, not this.

Most filesystem functionality is implemented, including hard and soft
links, sparse files, ownership and access modes, UNIX permission
checking and random access to binary files. Very large files (up to
multiple gigabytes) are supported without performance degradation.

Why would you use this? The main reason is that it allows you to use
DBMs functionality such as accessibility over the network, database
replication, failover, etc. In addition, the underlying
DBI::Filesystem module can be extended via subclassing to allow
additional functionality such as arbitrary access control rules,
searchable file and directory metadata, full-text indexing of file
contents, etc.

Before mounting the DBMS, you must have created the database and
assigned yourself sufficient privileges to read and write to it. You
must also create an empty directory to serve as the mount point.

A convenient front-end to this library is provided by B<sqlfs.pl>,
which is installed along with this library.

=head2 Unsupported Features

The following features are not implemented:

 * statfs -- df on the filesystem will not provide any useful information
            on free space or other filesystem information.

 * extended attributes -- Extended attributes are not supported.

 * nanosecond times -- atime, mtime and ctime are accurate only to the
            second.

 * ioctl -- none are supported

 * poll  -- polling on the filesystem to detect file update events will not work.

 * lock  -- file handle locking among processes running on the local machine 
            works, but protocol-level locking, which would allow cooperative 
            locks on different machines talking to the same database server, 
            is not implemented.

You must be the superuser in order to create a file system with the
suid and dev features enabled, and must invoke this commmand with
the mount options "allow_other", "suid" and/or "dev":

   -o dev,suid,allow_other

=head2 Supported Database Management Systems

DBMSs differ in what subsets of the SQL language they support,
supported datatypes, date/time handling, and support for large binary
objects. DBI::Filesystem currently supports MySQL, PostgreSQL and
SQLite. Other DBMSs can be supported by creating a subclass file
named, e.g. DBI::Filesystem:Oracle, where the last part of the class
name corresponds to the DBD driver name ("Oracle" in this
example). See DBI::Filesystem::SQLite, DBI::Filesystem::mysql and
DBI::Filesystem:Pg for an illustration of the methods that need to be
defined/overridden.

=head2 Fuse Installation Notes

For best performance, you will need to run this filesystem using a
version of Perl that supports IThreads. Otherwise it will fall back to
non-threaded mode, which will introduce occasional delays during
directory listings and have notably slower performance when reading
from more than one file simultaneously.

If you are running Perl 5.14 or higher, you *MUST* use at least 0.15
of the Perl Fuse module. At the time this was written, the version of
Fuse 0.15 on CPAN was failing its regression tests on many
platforms. I have found that the easiest way to get a fully
operational Fuse module is to clone and compile a patched version of
the source, following this recipe:

 $ git clone git://github.com/dpavlin/perl-fuse.git
 $ cd perl-fuse
 $ perl Makefile.PL
 $ make test   (optional)
 $ sudo make install

=head1 HIGH LEVEL METHODS

The following methods are most likely to be needed by users of this module.

=cut

use strict;
use warnings;
use DBI;
use Fuse 'fuse_get_context',':xattr';
use threads;
use threads::shared;
use File::Basename 'basename','dirname';
use File::Spec;
use POSIX qw(ENOENT EISDIR ENOTDIR ENOTEMPTY EINVAL ECONNABORTED EACCES EIO EPERM EEXIST
             O_RDONLY O_WRONLY O_RDWR O_CREAT F_OK R_OK W_OK X_OK
             S_IXUSR S_IXGRP S_IXOTH);
use Carp 'croak';

our $VERSION = '1.04';

use constant SCHEMA_VERSION => 3;
use constant ENOATTR      => ENOENT;  # not sure this is right?
use constant MAX_PATH_LEN => 4096;  # characters
use constant BLOCKSIZE    => 16384;  # bytes
use constant FLUSHBLOCKS  => 256;    # flush after we've accumulated this many cached blocks

my %Blockbuff :shared;


=head2 $fs = DBI::Filesystem->new($dsn,{options...})

Create the new DBI::Filesystem object. The mandatory first argument is
a DBI data source, in the format "dbi:<driver>:<other_arguments>". The
other arguments may include the database name, host, port, and
security credentials. See the documentation for your DBMS for details.

Non-mandatory options are contained in a hash reference with one or
more of the following keys:

 initialize          If true, then initialize the database schema. Many
                     DBMSs require you to create the database first.

 ignore_permissions  If true, then Unix permission checking is not
                     performed when creating/reading/writing files.

 allow_magic_dirs    If true, allow SQL statements in "magic" directories
                     to be executed (see below).

WARNING: Initializing the schema quietly destroys anything that might
have been there before!

=cut

# DBI::Filesystem->new($dsn,{create=>1,ignore_permissions=>1})
sub new {
    my $class = shift;
    my ($dsn,$options) = @_;

    my ($dbd)          = $dsn =~ /dbi:([^:]+)/;
    $dbd or croak "Could not figure out the DBI subclass to load from $dsn";

    $options ||= {};

    # load the appropriate DBD subclass and fix up its @ISA so that we become
    # the parent class
    my $c        = ref $class||$class;
    my $subclass = __PACKAGE__.'::DBD::'.$dbd;
    eval "require $subclass;1" or croak $@  unless $subclass->can('new');
    eval "unshift \@$subclass\:\:ISA,'$c'   unless \$subclass->isa('$c')";
    die $@ if $@;

    my $self  = bless {
	dsn          => $dsn,
	%$options
    },$subclass;

    local $self->{dbh};  # to avoid cloning database handle into child threads

    $self->initialize_schema if $options->{initialize};
    $self->check_schema_version;
    return $self;
}

=head2 $boolean = $fs->ignore_permissions([$boolean]);

Get/set the ignore_permissions flag. If ignore_permissions is true,
then all permission checks on file and directory access modes are
disabled, allowing you to create files owned by root, etc.

=cut

sub ignore_permissions {
    my $self = shift;
    my $d    = $self->{ignore_permissions};
    $self->{ignore_permissions} = shift if @_;
    $d;
}

=head2 $boolean = $fs->allow_magic_dirs([$boolean]);

Get/set the allow_magic_dirs flag. If true, then directories whose
names begin with "%%" will be searched for a dotfile named ".query"
that contains a SQL statement to be run every time a directory listing
is required from this directory. See getdir() below.

=cut

sub allow_magic_dirs {
    my $self = shift;
    my $d    = $self->{allow_magic_dirs};
    $self->{allow_magic_dirs} = shift if @_;
    $d;
}

############### filesystem handlers below #####################

our $Self;   # because entrypoints cannot be passed as closures

=head2 $fs->mount($mountpoint, [\%fuseopts])

This method will mount the filesystem on the indicated mountpoint
using Fuse and block until the filesystem is unmounted using the
"fusermount -u" command or equivalent. The mountpoint must be an empty
directory unless the "nonempty" mount option is passed.

You may pass in a hashref of options to pass to the Fuse
module. Recognized options and their defaults are:

 debug        Turn on verbose debugging of Fuse operations [false]
 threaded     Turn on threaded operations [true]
 nullpath_ok  Allow filehandles on open files to be used even after file
               is unlinked [true]
 mountopts    Comma-separated list of mount options

Mount options to be passed to Fuse are described at
http://manpages.ubuntu.com/manpages/precise/man8/mount.fuse.8.html. In
addition, you may pass the usual mount options such as "ro", etc. They
are presented as a comma-separated list as shown here:

 $fs->mount('/tmp/foo',{debug=>1,mountopts=>'ro,nonempty'})

Common mount options include:

Fuse specific
 nonempty      Allow mounting over non-empty directories if true [false]
 allow_other   Allow other users to access the mounted filesystem [false]
 fsname        Set the filesystem source name shown in df and /etc/mtab
 auto_cache    Enable automatic flushing of data cache on open [false]
 hard_remove   Allow true unlinking of open files [true]
 nohard_remove Activate alternate semantics for unlinking open files
                (see below)

General
 ro          Read-only filesystem
 dev         Allow device-special files
 nodev       Do not allow device-special files
 suid        Allow suid files
 nosuid      Do not allow suid files
 exec        Allow executable files
 noexec      Do not allow executable files
 atime       Update file/directory access times
 noatime     Do not update file/directory access times

Some options require special privileges. In particular allow_other
must be enabled in /etc/fuse.conf, and the dev and suid options can
only be used by the root user.

The "hard_remove" mount option is passed by default. This option
allows files to be unlinked in one process while another process holds
an open filehandle on them. The contents of the file will not actually
be deleted until the last open filehandle is closed. The downside of
this is that certain functions will fail when called on filehandles
connected to unlinked files, including fstat(), ftruncate(), chmod(),
and chown(). If this is an issue, then pass option
"nohard_remove". This will activate Fuse's alternative semantic in
which unlinked open files are renamed to a hidden file with a name
like ".fuse_hiddenXXXXXXX'. The hidden file is removed when the last
filehandle is closed.

=cut

sub mount {
    my $self = shift;
    my $mtpt = shift or croak "Usage: mount(\$mountpoint)";
    my $fuse_opts = shift;

    $fuse_opts ||= {};

    my %mt_opts = map {$_=>1} split ',',($fuse_opts->{mountopts}||'');
    $mt_opts{hard_remove}++ unless $mt_opts{nohard_remove};
    delete $mt_opts{nohard_remove};
    $fuse_opts->{mountopts} = join ',',keys %mt_opts;

    my $pkg  = __PACKAGE__;

    $Self = $self;  # because entrypoints cannot be passed as closures
    $self->check_schema 
	or croak "This database does not appear to contain a valid schema. Do you need to initialize it?\n";
    $self->mounted(1);
    my @args = (
	mountpoint  => $mtpt,
	getdir      => "$pkg\:\:e_getdir",
	getattr     => "$pkg\:\:e_getattr",
	fgetattr    => "$pkg\:\:e_fgetattr",
	open        => "$pkg\:\:e_open",
	release     => "$pkg\:\:e_release",
	flush       => "$pkg\:\:e_flush",
	read        => "$pkg\:\:e_read",
	write       => "$pkg\:\:e_write",
	ftruncate   => "$pkg\:\:e_ftruncate",
	truncate    => "$pkg\:\:e_truncate",
	create      => "$pkg\:\:e_create",
	mknod       => "$pkg\:\:e_mknod",
	mkdir       => "$pkg\:\:e_mkdir",
	rmdir       => "$pkg\:\:e_rmdir",
	link        => "$pkg\:\:e_link",
	rename      => "$pkg\:\:e_rename",
	access      => "$pkg\:\:e_access",
	chmod       => "$pkg\:\:e_chmod",
	chown       => "$pkg\:\:e_chown",
	symlink     => "$pkg\:\:e_symlink",
	readlink    => "$pkg\:\:e_readlink",
	unlink      => "$pkg\:\:e_unlink",
	utime       => "$pkg\:\:e_utime",
	getxattr    => "$pkg\:\:e_getxattr",
	listxattr   => "$pkg\:\:e_listxattr",
	nullpath_ok => 1,
	debug       => 0,
	threaded    => 1,
	%$fuse_opts,
	);
    push @args,$self->_subclass_implemented_calls();
    Fuse::main(@args);
}

# this method detects when one of the currently unimplemented
# Fuse methods is defined in a subclass, and creates the appropriate
# Fuse stub to call it
sub _subclass_implemented_calls{
    my $self = shift;
    my @args;

    my @u = (qw(statfs fsync 
                setxattr getxattr listxattr removexattr
                opendir readdir releasedir fsyncdir
                init destroy lock utimens
                bmap ioctl poll));
    my @implemented = grep {$self->can($_)} @u;

    my $pkg  = __PACKAGE__;
    foreach my $method (@implemented) {
	next if $self->can("e_$method");  # don't overwrite
	my $hook = "$pkg\:\:e_$method";
	eval <<END;
sub $hook {
    my \$path   = fixup(shift) if \@_;
    my \@result = eval {\$${pkg}\:\:Self->$method(\$path,\@_)};
    return \$Self->errno(\$@) if \$@;
    return wantarray ? \@result:\$result[0];
}
END
    ;
	warn $@ if $@;
	push @args,($method => $hook);
    }
    return @args;
}

=head2 $boolean = $fs->mounted([$boolean])

This method returns true if the filesystem is currently
mounted. Subclasses can change this value by passing the new value as
the argument.

=cut

sub mounted {
    my $self = shift;
    my $d = $self->{mounted};
    $self->{mounted} = shift if @_;
    return $d;
}

=head2 Fuse hook functions

This module defines a series of short hook functions that form the
glue between Fuse's function-oriented callback hooks and this module's
object-oriented methods. A typical hook function looks like this:

 sub e_getdir {
    my $path = fixup(shift);
    my @entries = eval {$Self->getdir($path)};
    return $Self->errno($@) if $@;
    return (@entries,0);
 }

The preferred naming convention is that the Fuse callback is named
"getdir", the function hook is named e_getdir(), and the method is
$fs->getdir(). The DBI::Filesystem object is stored in a singleton
global named $Self. The hook fixes up the path it receives from Fuse,
and then calls the getdir() method in an eval{} block. If the getdir()
method raises an error such as "file not found", the error message is
passed to the errno() method to turn into a ERRNO code, and this is
returned to the caller. Otherwise, the hook returns the results in the
format proscribed by Fuse.

If you are subclassing DBI::Filesystem, there is no need to define new
hook functions. All hooks described by Fuse are already defined or
generated dynamically as needed. Simply create a correctly-named
method in your subclass.

These are the hooks that are defined:

 e_getdir       e_open           e_access      e_unlink     e_removexattr
 e_getattr      e_release        e_rename      e_rmdir
 e_fgetattr     e_flush          e_chmod       e_utime
 e_mkdir        e_read           e_chown       e_getxattr
 e_mknod        e_write          e_symlink     e_setxattr
 e_create       e_truncate       e_readlink    e_listxattr

These hooks will be created as needed if a subclass implements the
corresponding methods:

 e_statfs       e_lock            e_init 
 e_fsync        e_opendir         e_destroy 
 e_readdir      e_utimens
 e_releasedir   e_bmap 
 e_fsyncdir     e_ioctl 
 e_poll

=cut

sub e_getdir {
    my $path = fixup(shift);
    my @entries = eval {$Self->getdir($path)};
    return $Self->errno($@) if $@;
    return (@entries,0);
}

sub e_getattr {
    my $path  = fixup(shift);
    my @stat  = eval {$Self->getattr($path)};
    return $Self->errno($@) if $@;
    return @stat;
}

# the {get,list}xattr methods call for a bit of finessing of return values
#
sub e_getxattr {
    my $path = fixup(shift);
    my $name = shift;
    my $val  = eval {$Self->getxattr($path,$name)};
    return $Self->errno($@) if $@;
    return 0 unless defined $val;
    return $val
}

sub e_listxattr {
    my $path = fixup(shift);
    my @val  = eval {$Self->listxattr($path)};
    return $Self->errno($@) if $@;
    return (@val,0);
}

sub e_fgetattr {
    my ($path,$inode) = @_;
    my @stat  = eval {$Self->fgetattr(fixup($path),$inode)};
    return $Self->errno($@) if $@;
    return @stat;
}

sub e_mkdir {
    my $path = fixup(shift);
    my $mode = shift;

    $mode             |= 0040000;
    my $ctx            = $Self->get_context();
    my $umask          = $ctx->{umask};
    eval {$Self->mkdir($path,$mode&(~$umask))};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_mknod {
    my $path = fixup(shift);
    my ($mode,$device) = @_;
    my $ctx            = $Self->get_context;
    my $umask          = $ctx->{umask};
    eval {$Self->mknod($path,$mode&(~$umask),$device)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_create {
    my $path = fixup(shift);
    my ($mode,$flags) = @_;
    # warn sprintf("create(%s,0%o,0%o)",$path,$mode,$flags);
    my $ctx            = $Self->get_context;
    my $umask          = $ctx->{umask};
    my $fh = eval {
	$Self->mknod($path,$mode&(~$umask));
	$Self->open($path,$flags,{});
    };
    return $Self->errno($@) if $@;
    return (0,$fh);
}

sub e_open {
    my ($path,$flags,$info) = @_;
#    warn sprintf("open(%s,0%o,%s)",$path,$flags,$info);
    $path    = fixup($path);
    my $fh = eval {$Self->open($path,$flags,$info)};
    return $Self->errno($@) if $@;
    (0,$fh);
}

sub e_release {
    my ($path,$flags,$fh) = @_;
    eval {$Self->release($fh)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_flush {
    my ($path,$fh) = @_;
    eval {$Self->flush($path,$fh)};
    return $Self->errno($@) if $@;
    return 0;
}
 

sub e_read {
    my ($path,$size,$offset,$fh) = @_;
    $path    = fixup($path);
    my $data = eval {$Self->read($path,$size,$offset,$fh)};
    return $Self->errno($@) if $@;
    return $data;
}

sub e_write {
    my ($path,$buffer,$offset,$fh) = @_;
    $path    = fixup($path);
    my $data = eval {$Self->write($path,$buffer,$offset,$fh)};
    return $Self->errno($@) if $@;
    return $data;
}

sub e_truncate {
    my ($path,$offset) = @_;
    $path = fixup($path);
    eval {$Self->truncate($path,$offset)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_ftruncate {
    my ($path,$offset,$inode) = @_;
    $path = fixup($path);
    eval {$Self->truncate($path,$offset,$inode)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_link {
    my ($oldname,$newname) = @_;
    eval {$Self->link($oldname,$newname)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_access {
    my ($path,$access_mode) = @_;
    eval {$Self->access($path,$access_mode)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_rename {
    my ($oldname,$newname) = @_;
    eval { $Self->rename($oldname,$newname) };
    return $Self->errno($@) if $@;
    return 0;
}

sub e_chmod {
    my ($path,$mode) = @_;
    eval {$Self->chmod($path,$mode)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_chown {
    my ($path,$uid,$gid) = @_;
    eval {$Self->chown($path,$uid,$gid)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_symlink {
    my ($oldname,$newname) = @_;
    eval {$Self->symlink($oldname,$newname)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_readlink {
    my $path = shift;
    my $link = eval {$Self->readlink($path)};
    return $Self->errno($@) if $@;
    return $link;
}

sub e_unlink {
    my $path = shift;
    eval {$Self->unlink($path)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_rmdir {
    my $path = shift;
    eval {$Self->rmdir($path)};
    return $Self->errno($@) if $@;
    return 0;
}

sub e_utime {
    my ($path,$atime,$mtime) = @_;
    $path = fixup($path);
    my $result = eval {$Self->utime($path,$atime,$mtime)};
    return $Self->errno($@) if $@;
    return 0;
}

=head2 $inode = $fs->mknod($path,$mode,$rdev)

This method creates a file or special file (pipe, device file,
etc). The arguments are the path of the file to create, the mode of
the file, and the device number if creating a special device file, or
0 if not.  The return value is the inode of the newly-created file, an
unique integer ID, which is actually the primary key of the metadata
table in the underlying database.

The path in this, and all subsequent methods, is relative to the
mountpoint. For example, if the filesystem is mounted on /tmp/foobar,
and the file you wish to create is named /tmp/foobar/dir1/test.txt,
then pass "dir1/test.txt". You can also include a leading slash (as in
"/dir1/test.txt") which will simply be stripped off.

The mode is a bitwise combination of file type and access mode as
described for the st_mode field in the stat(2) man page. If you
provide just the access mode (e.g. 0666), then the method will
automatically set the file type bits to indicate that this is a
regular file. You must provide the file type in the mode in order to
create a special file.

The rdev field contains the major and minor device numbers for device
special files, and is only needed when creating a device special file
or pipe; ordinarily you can omit it. The rdev field is described in
stat(2).

Various exceptions can arise during this call including invalid paths,
permission errors and the attempt to create a duplicate file
name. These will be presented as fatal errors which can be trapped by
an eval {}. See $fs->errno() for a list of potential error messages.

Like other file-manipulation methods, this will die with a "permission
denied" message if the current user does not have sufficient
privileges to write into the desired directory. To disable permission
checking, set ignore_permissions() to a true value:

 $fs->ignore_permissions(1)

Unless explicitly provided, the mode will be set to 0100777 (all
permissions set).

=cut

sub mknod { 
    my $self = shift;
    my ($path,$mode,$rdev) = @_;
    my $result = eval {$self->create_inode_and_path($path,'f',$mode,$rdev)};
    if ($@) {
	die "file exists" if $@ =~ /not unique|duplicate/i;
	die $@;
    }
    return $result;
}

=head2 $inode = $fs->mkdir($path,$mode)

Create a new directory with the specified path and mode and return the
inode of the newly created directory. The path and mode are the same
as those described for mknod(), except that the filetype bits for
$mode will be set to those for a directory if not provided. Like
mknod() this method may raise a fatal error, which should be trapped
by an eval{}.

Unless explicitly provided, the mode will be set to 0040777 (all
permissions set).

=cut

sub mkdir {
    my $self = shift;
    my ($path,$mode) = @_;
    $self->create_inode_and_path($path,'d',$mode);
}

=head2 $fs->rename($oldname,$newname)

Rename a file or directory. Raises a fatal exception if unsuccessful.

=cut

sub rename {
    my $self = shift;
    my ($oldname,$newname) = @_;
    my ($inode,$parent,$basename,$dynamic) = $self->path2inode($oldname);
    die "permission denied" if $dynamic;

    # if newname exists then this is an error
    die "file exists" if eval{$self->path2inode($newname)};

    my $newbase   = basename($newname);
    my $newdir    = $self->_dirname($newname);
    my $newparent = $self->path2inode($newdir); # also does path checking
    $self->check_perm($parent,W_OK);            # can we update the old parent?
    $self->check_perm($newparent,W_OK);         # can we update the new parent?

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare_cached(
	'update path set name=?,parent=? where parent=? and name=?');
    $sth->execute($newbase,$newparent,$parent,$basename);
    $sth->finish;
    1;
}

=head2 $fs->unlink($path)

Unlink the file or symlink located at $path. If this is the last
reference to the file (via hard links or filehandles) then the
contents of the file and its inode will be permanently removed. This
will raise a fatal exception on any errors.

=cut

sub unlink {
    my $self  = shift;
    my $path = shift;
    my ($inode,$parent,$name,$dynamic)  = $self->path2inode($path);
    die "permission denied" if $dynamic;

    $parent ||= 1;
    $self->check_perm($parent,W_OK);

    $name   ||= basename($path);

    $self->_isdir($inode)      and croak "$path is a directory";
    my $dbh                    = $self->dbh;
    my $sth                    = $dbh->prepare_cached("delete from path where inode=? and parent=? and name=?") 
	or die $dbh->errstr;
    $sth->execute($inode,$parent,$name) or die $dbh->errstr;

    eval {
	$dbh->begin_work();
	$dbh->do("update metadata set links=links-1 where inode=$inode");
	$dbh->do("update metadata set links=links-1 where inode=$parent");
	$self->touch($parent,'mtime');
	$self->touch($parent,'ctime');
	$dbh->commit();
    };
    if ($@) {
	eval {$dbh->rollback()};
	die "unlink failed due to $@";
    }
    $self->unlink_inode($inode);
    1;
}

=head2 $fs->rmdir($path)

Remove the directory at $path. This method will fail under a variety
of conditions, raising a fatal exception. Common errors include
attempting to remove a file rather than a directory or removing a
directory that is not empty.

=cut

sub rmdir {
    my $self = shift;
    my $path = shift;
    my ($inode,$parent,$name) = $self->path2inode($path) ;
    $self->check_perm($parent,W_OK);
    $self->_isdir($inode)                or croak "$path is not a directory";
    $self->_getdir($inode )             and croak "$path is not empty";

    my $dbh   = $self->dbh;
    eval {
	$dbh->begin_work;
	my $now = $self->_now_sql;
	$dbh->do("update metadata set links=links-1,ctime=$now where inode=$inode");
	$dbh->do("update metadata set links=links-1,ctime=$now where inode=$parent");
	$dbh->do("delete from path where inode=$inode");
	$self->touch($parent,'ctime');
	$self->touch($parent,'mtime');
	$self->unlink_inode($inode);
	$dbh->commit;
    };
    if($@) {
	eval {$dbh->rollback()};
	die "update aborted due to $@";
    }
    1;
}    



=head2 $fs->link($oldpath,$newpath)

Create a hard link from the file at $oldpath to $newpath. If an error
occurs the method will die. Note that this method will allow you to
create a hard link to directories as well as files. This is disallowed
by the "ln" command, and is generally a bad idea as you can create a
filesystem with path loops.

=cut

sub link {
    my $self = shift;
    my ($oldpath,$newpath,$allow_dir_unlink) = @_;
    $self->check_perm(scalar $self->path2inode($self->_dirname($oldpath)),W_OK);
    $self->check_perm(scalar $self->path2inode($self->_dirname($newpath)),W_OK);
    my $inode  = $self->path2inode($oldpath);
    $self->_isdir($inode) && !$allow_dir_unlink
	and die "hard links of directories not allowed";
    eval {
	$self->create_path($inode,$newpath);
    };
    if ($@) {
	die "file exists" if $@ =~ /not unique|duplicate/i;
	die $@;
    }
    1;
}

=head2 $fs->symlink($oldpath,$newpath)

Create a soft (symbolic) link from the file at $oldpath to
$newpath. If an error occurs the method will die. It is safe to create
symlinks that involve directories.

=cut

sub symlink {
    my $self = shift;
    my ($oldpath,$newpath) = @_;
    eval {
	my $newnode = $self->create_inode_and_path($newpath,'l',0120777);
	$self->write($newpath,$oldpath);
    };
    if ($@) {
	die "file exists" if $@ =~ /not unique|duplicate/i;
	die $@;
    }
    1;
}

=head2 $path = $fs->readlink($path)

Read the symlink at $path and return its target. If an error occurs
the method will die.

=cut

sub readlink {
    my $self   = shift;
    my $path   = shift;
    my $target = $self->read($path,MAX_PATH_LEN);
    return $target;
}

=head2 @entries = $fs->getdir($path)

Given a directory in $path, return a list of all entries (files,
directories) contained within that directory. The '.' and '..' paths
are also always returned. This method checks that the current user has
read and execute permissions on the directory, and will raise a
permission denied error if not (trap this with an eval{}).

Experimental feature: If the directory begins with the magic
characters "%%" then getdir will look for a dotfile named ".query"
within the directory. ".query" must contain a SQL query that returns a
series of one or more inodes. These will be used to populate the
directory automagically. The query can span multiple lines, and 
lines that begin with "#" will be ignored.

Here is a simple example which will run on all DBMSs. It displays all
files with size greater than 2 Mb:

 select inode from metadata where size>2000000

Another example, which uses MySQL-specific date/time
math to find all .jpg files created/modified within the last day:

 select m.inode from metadata as m,path as p
     where p.name like '%.jpg'
       and (now()-interval 1 day) <= m.mtime
       and m.inode=p.inode

(The date/time math syntax is very slightly different for PostgreSQL
and considerably different for SQLite)

An example that uses extended attributes to search for all documents
authored by someone with "Lincoln" in the name:

 select m.inode from metadata as m,xattr as x
    where x.name == 'user.Author'
     and x.value like 'Lincoln%'
     and m.inode=x.inode
    
The files contained within the magic directories can be read and
written just like normal files, but cannot be removed or
renamed. Directories are excluded from magic directories. If two or
more files from different parts of the filesystem have name clashes,
the filesystem will append a number to their end to distinguish them.

If the SQL contains an error, then the error message will be contained
within a file named "SQL_ERROR".

=cut

sub getdir {
    my $self = shift;
    my $path = shift;

    my $inode = $self->path2inode($path);
    $self->_isdir($inode) or croak "not directory";
    $self->check_perm($inode,X_OK|R_OK);
    return $self->_getdir($inode,$path);
}

sub _getdir {
    my $self  = shift;
    my ($inode,$path) = @_;
    my $dbh   = $self->dbh;
    my $col   = $dbh->selectcol_arrayref("select name from path where parent=$inode");
    if ($self->allow_magic_dirs && $self->_is_dynamic_dir($inode,$path)) {
	my $dynamic = $self->get_dynamic_entries($inode,$path);
	push @$col,keys %$dynamic if $dynamic;
    }
    return '.','..',@$col;
}

# user has passed a SQL WHERE clause as a directory name
sub _sql_directory {
    my $self = shift;
    my $path = shift;
    (my $where = $path) =~ s/^%(?:where)?//;
    my $dbh    = $self->dbh;
    my $names  = eval {$dbh->selectcol_arrayref("select name from metadata,path where metadata.inode=path.inode and $where")};
    if ($@) {
	my $msg = $@;
	$msg   =~ s/\s+at.+$//;
	$msg =~ s![\n/] !!g;
	return ('.','..',$msg);
    } 
    return ('.','..',@$names);
}

sub get_dynamic_entries {
    my $self = shift;
    my ($inode,$path) = @_;

    return $self->_get_cached_dynamic_entries($inode,$path)
	|| $self->_set_cached_dynamic_entries($inode,$path);
}

sub _get_cached_dynamic_entries {
    my $self = shift;
    my ($inode,$path) = @_;

    my $dbh   = $self->dbh;
    my $query = <<END;
select inode,name,parent
  from dynamic_cache
   where directory=? and time>=?
END
;
    my (%matches,%seenit);
    eval {
	my $sth = $dbh->prepare_cached($query);
	$sth->execute($inode,time()-1); # cache time 1s at most

	while (my ($file_inode,$name,$parent)=$sth->fetchrow_array) {
	    $name .= '('.($seenit{$name}-1).')' if $seenit{$name}++;
	    $matches{$name} = [$file_inode,$parent];
	}
    };
    return unless %matches;
    return \%matches;
}

sub _set_cached_dynamic_entries {
    my $self = shift;
    my ($inode,$path) = @_;

    my $dbh   = $self->dbh;

    # create a temporary table to hold the results
    $dbh->do(<<END);
create temporary table if not exists dynamic_cache 
     (directory integer,
      time      integer,
      inode     integer,
      name      varchar(255),
      parent    integer)
END
;

    $dbh->do("delete from dynamic_cache where directory=$inode");

    # look for a file named .query
    my ($query_inode) = 
	$dbh->selectrow_array("select inode from path where name='.query' and parent=$inode");
    return unless $query_inode;

    # fetch the query
    my $sql   = $self->read(undef,4096,0,$query_inode) or return;
    $sql =~ s/#.+\n//g;

    # run the query
    my $isdir = 0x4000;
    my $query = <<END;
insert into dynamic_cache (directory,time,inode,name,parent)
 select ?,?,p.inode,p.name,p.parent 
 from path as p,metadata as m
   where p.inode=m.inode 
     and ($isdir&m.mode)=0 
       and p.inode in ($sql)
END
    ;;
    my $sth;
    eval {
	$sth   = $dbh->prepare($query);
	$sth->execute($inode,time());
    };	    

    my $error_file = "$path/SQL_ERROR";
    if ($@) {
	my $msg = $@;
	eval {
	    my ($i) = eval {$self->_path2inode($error_file)};
	    $i    ||= $self->mknod($error_file,0444,0);
	    $self->ftruncate($error_file,0,$i);
	    $self->write($error_file,$msg,0,$i);
	};
	warn $@ if $@;
	return;
    } else {
	eval{
	    $self->unlink($error_file) if $self->_path2inode($error_file);
	};
    }
    $sth->finish;
    return $self->_get_cached_dynamic_entries($inode,$path);
}

=head2 $boolean = $fs->isdir($path)

Convenience method. Returns true if the path corresponds to a
directory. May raise a fatal error if the provided path is invalid.

=cut

sub isdir {
    my $self = shift;
    my $path = shift;
    my $inode = $self->path2inode($path) ;
    return $self->_isdir($inode);
}

sub _isdir {
    my $self  = shift;
    my $inode = shift;
    my $dbh   = $self->dbh;
    my $mask  = 0xf000;
    my $isdir = 0x4000;
    my ($result) = $dbh->selectrow_array("select ($mask&mode)=$isdir from metadata where inode=$inode")
	or die $dbh->errstr;
    return $result;
}

sub _is_dynamic_dir {
    my $self = shift;
    my ($inode,$path) = @_;
    return unless $path;
    return $path =~ m!(?:^|/)%%[^/]+$! && $self->_isdir($inode) 
}

=head2 $fs->chown($path,$uid,$gid)

This method changes the user and group ids for the indicated path. It
raises a fatal exception on errors.

=cut

sub chown {
    my $self              = shift;
    my ($path,$uid,$gid)  = @_;
    my $inode             = $self->path2inode($path) ;

    # permission checking here
    unless ($self->ignore_permissions) {
	my $ctx = $self->get_context;
	die "permission denied" unless $uid == 0xffffffff || $ctx->{uid} == 0 || $ctx->{uid}==$uid;

	my $groups            = $self->get_groups(@{$ctx}{'uid','gid'});
	die "permission denied" unless $gid == 0xffffffff || $ctx->{uid} == 0 || $ctx->{gid}==$gid || $groups->{$gid};
    }

    my $dbh               = $self->dbh;
    eval {
	$dbh->begin_work();
	$dbh->do("update metadata set uid=$uid where inode=$inode") if $uid!=0xffffffff;
	$dbh->do("update metadata set gid=$gid where inode=$inode") if $gid!=0xffffffff;
	$self->touch($inode,'ctime');
	$dbh->commit();
    };
    if ($@) {
	eval {$dbh->rollback()};
	die "update aborted due to $@";
    }
    1;
}

=head2 $fs->chmod($path,$mode)

This method changes the access mode for the file or directory at the
indicated path. The mode in this case is just the three octal word
access mode, not the combination of access mode and path type used in
mknod().

=cut

sub chmod {
    my $self         = shift;
    my ($path,$mode) = @_;
    my $inode        = $self->path2inode($path) ;
    $self->check_perm($inode,F_OK);
    my $dbh          = $self->dbh;
    my $f000         = 0xf000;
    my $now          = $self->_now_sql;
    return $dbh->do("update metadata set mode=(($f000&mode)|$mode),ctime=$now where inode=$inode");
}

=head2 @stat = $fs->fgetattr($path,$inode)

Return the 13-element file attribute list returned by Perl's stat()
function, describing an existing file or directory. You may pass the
path, and/or the inode of the file/directory. If both are passed, then
the inode takes precedence.

The returned list will contain:

   0 dev      device number of filesystem
   1 ino      inode number
   2 mode     file mode  (type and permissions)
   3 nlink    number of (hard) links to the file
   4 uid      numeric user ID of file's owner
   5 gid      numeric group ID of file's owner
   6 rdev     the device identifier (special files only)
   7 size     total size of file, in bytes
   8 atime    last access time in seconds since the epoch
   9 mtime    last modify time in seconds since the epoch
  10 ctime    inode change time in seconds since the epoch (*)
  11 blksize  preferred block size for file system I/O
  12 blocks   actual number of blocks allocated

=cut

sub fgetattr {
    my $self  = shift;
    my ($path,$inode) = @_;
    $inode  ||= $self->path2inode($path);
    my $dbh   = $self->dbh;
    my ($ino,$mode,$uid,$gid,$rdev,$nlinks,$ctime,$mtime,$atime,$size) =
	$dbh->selectrow_array($self->_fgetattr_sql($inode));
    $ino or die 'not found';

    # make sure write buffer contributes
    if (my $blocks = $Blockbuff{$inode}) {
	lock $blocks; 
	if (keys %$blocks) { 
	    my ($biggest) = sort {$b<=>$a} keys %$blocks; 
	    my $offset    = $self->blocksize * $biggest + length $blocks->{$biggest}; 
	    $size         = $offset if $offset > $size;
	}
    }

    my $dev     = 0;
    my $blocks  = 1;
    my $blksize = $self->blocksize;
    return ($dev,$ino,$mode,$nlinks,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
}

=head2 @stat = $fs->getattr($path)

Similar to fgetattr() but only the path is accepted.

=cut

sub getattr {
    my $self         = shift;
    my $path         = shift;
    my $inode        = $self->path2inode($path);
    return $self->fgetattr($path,$inode);
}

=head2 $inode = $fs->open($path,$flags,$info)

Open the file at $path and return its inode. $flags are a bitwise
OR-ing of the access mode constants including O_RDONLY, O_WRONLY,
O_RDWR, O_CREAT, and $info is a hash reference containing flags from
the Fuse module. The latter is currently ignored.

This method checks read/write permissions on the file and containing
directories, unless ignore_permissions is set to true. The open method
also increments the file's inuse counter, ensuring that even if it is
unlinked, its contents will not be removed until the last open
filehandle is closed.

The flag constants can be obtained from POSIX.

=cut

sub open {
    my $self = shift;
    my ($path,$flags,$info) = @_;
    my $inode  = $self->path2inode($path);
    $self->check_open_perm($inode,$flags);
    $self->dbh->do("update metadata set inuse=inuse+1 where inode=$inode");
    return $inode;
}

=head2 $fh->release($inode)

Release a file previously opened with open(), decrementing its inuse
count. Be careful to balance calls to open() with release(), or the
file will have an inconsistent use count.

=cut

sub release {
    my ($self,$inode) = @_;
    $self->flush(undef,$inode);  # write cached blocks
    my $dbh = $self->dbh;
    $dbh->do("update metadata set inuse=inuse-1 where inode=$inode");
    $self->unlink_inode($inode);
    return 0;
}


=head2 $data = $fs->read($path,$length,$offset,$inode)

Read $length bytes of data from the file at $path, starting at
position $offset. You may optionally pass an inode to the method to
read from a previously-opened file.

On success, the requested data will be returned. Otherwise a fatal
exception will be raised (which can be trapped with an eval{}).

Note that you do not need to open the file before reading from
it. Permission checking is not performed in this call, but in the
(optional) open() call.

=cut

sub read {
    my $self = shift;
    my ($path,$length,$offset,$inode) = @_;

    $inode || defined $path or croak "no path or inode provided";

    unless ($inode) {
	$inode  = $self->path2inode($path);
	$self->_isdir($inode) and croak "$path is a directory";
    }
    $offset  ||= 0;

    my $blksize     = $self->blocksize;
    my $first_block = int($offset / $blksize);
    my $last_block  = int(($offset+$length) / $blksize);
    my $start       = $offset % $blksize;
    
    $self->flush(undef,$inode);
    my $get_atime = $self->_get_unix_timestamp_sql('atime');
    my $get_mtime = $self->_get_unix_timestamp_sql('mtime');
    my ($current_length,$atime,$mtime) = 
	$self->dbh->selectrow_array("select size,$get_atime,$get_mtime from metadata where inode=$inode");
    if ($length+$offset > $current_length) {
	$length = $current_length - $offset;
    }
    my $data = $self->_read_direct($inode,$start,$length,$first_block,$last_block);
    $self->touch($inode,'atime') if length $data && $atime < $mtime;
    return $data;
}

=head2 $bytes = $fs->write($path,$data,$offset,$inode)

Write the data provided in $data into the file at $path, starting at
position $offset. You may optionally pass an inode to the method to
read from a previously-opened file.

On success, the number of bytes written will be returned. Otherwise a fatal
exception will be raised (which can be trapped with an eval{}).

Note that the file does not previously need to have been opened in
order to write to it, and permission checking is not performed at this
level. This checking is performed in the (optional) open() call.

=cut

sub write {
    my $self = shift;
    my ($path,$data,$offset,$inode) = @_;
    $inode || defined $path or croak "no path or inode provided";

    unless ($inode) {
	$inode  = $self->path2inode($path);
	$self->_isdir($inode) and croak "$path is a directory";
    }
    $offset  ||= 0;

    my $blksize        = $self->blocksize;
    my $first_block    = int($offset / $blksize);
    my $start          = $offset % $blksize;

    my $block          = $first_block;
    my $bytes_to_write = length $data;
    my $bytes_written  = 0;
    unless ($Blockbuff{$inode}) {
	my %hash;
	$Blockbuff{$inode}=share(%hash);
    }
    my $blocks         = $Blockbuff{$inode}; # blockno=>data
    lock $blocks;

    my $dbh            = $self->dbh;
    while ($bytes_to_write > 0) {
	my $bytes          = $blksize > ($bytes_to_write+$start) ? $bytes_to_write : ($blksize-$start);
	my $current_length = length($blocks->{$block}||'');

	if ($bytes < $blksize && !$current_length) {  # partial block replacement, and not currently cached
	    my $sth = $dbh->prepare_cached('select contents,length(contents) from extents where inode=? and block=?');
	    $sth->execute($inode,$block);
	    ($blocks->{$block},$current_length) = $sth->fetchrow_array();
	    $current_length                   ||= 0;
	    $sth->finish;
	}

	if ($start > $current_length) {  # hole in current block
	    my $padding  = "\0" x ($start-$current_length);
	    $padding   ||= '';
	    $blocks->{$block} .= $padding;
	}

	if ($blocks->{$block}) {
	    substr($blocks->{$block},$start,$bytes,substr($data,$bytes_written,$bytes));
	} else {
	    $blocks->{$block} = substr($data,$bytes_written,$bytes);
	}

	$start = 0;  # no more offsets
	$block++;
	$bytes_written  += $bytes;
	$bytes_to_write -= $bytes;
    }
    $self->flush(undef,$inode) if keys %$blocks > $self->flushblocks;
    return $bytes_written;
}

sub _write_blocks {
    my $self = shift;
    my ($inode,$blocks,$blksize) = @_;

    my $dbh = $self->dbh;
    my ($length) = $dbh->selectrow_array("select size from metadata where inode=$inode");
    my $hwm      = $length;  # high water mark ;-)

    eval {
	$dbh->begin_work;
	my $sth = $dbh->prepare_cached(<<END) or die $dbh->errstr;
replace into extents (inode,block,contents) values (?,?,?)
END
;
	for my $block (keys %$blocks) {
	    my $data = $blocks->{$block};
	    $sth->execute($inode,$block,$data);
	    my $a   = $block * $blksize + length($data);
	    $hwm    = $a if $a > $hwm;
	}
	$sth->finish;
	my $now = $self->_now_sql;
	$dbh->do("update metadata set size=$hwm,mtime=$now where inode=$inode");
	$dbh->commit();
    };

    if ($@) {
	my $msg = $@;
	eval{$dbh->rollback()};
	warn $msg;
	die "write failed with $msg";
	return;
    }

    1;
}

=head2 $fs->flush( [$path,[$inode]] )

Before data is written to the database, it is cached for a while in
memory. flush() will force data to be written to the database. You may
pass no arguments, in which case all cached data will be written, or
you may provide the path and/or inode to an existing file to flush
just the unwritten data associated with that file.

=cut

sub flush {
    my $self  = shift;
    my ($path,$inode) = @_;

    $inode  ||= $self->path2inode($path) if $path;

    # if called with no inode, then recursively call ourselves
    # to flush all cached inodes
    unless ($inode) {
	for my $i (keys %Blockbuff) {
	    $self->flush(undef,$i);
	}
	return;
    }

    my $blocks  = $Blockbuff{$inode} or return;
    my $blksize = $self->blocksize;

    lock $blocks;
    my $result = $self->_write_blocks($inode,$blocks,$blksize) or die "flush failed";

    delete $Blockbuff{$inode};
}

# This type of read is invoked when there is no write buffer for
# the file. It executes a single SQL query across the data table.
sub _read_direct {
    my $self = shift;
    my ($inode,$start,$length,$first_block,$last_block) = @_;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare_cached(<<END);
select block,contents 
   from extents where inode=? 
   and block between ? and ?
   order by block
END
;
    $sth->execute($inode,$first_block,$last_block);

    my $blksize     = $self->blocksize;
    my $previous_block;
    my $data = '';
    while (my ($block,$contents) = $sth->fetchrow_array) {
	$previous_block = $block unless defined $previous_block;
	# a hole spanning an entire block
	if ($block - $previous_block > 1) {
	    $data .= "\0"x($blksize*($block-$previous_block-1));
	}
	$previous_block = $block;
	
	# a hole spanning a portion of a block
	if (length $contents < $blksize && $block < $last_block) {
	    $contents .= "\0"x($blksize-length($contents));  # this is a hole!
	}
	$data      .= substr($contents,$start,$length);
	$length    -= $blksize;
	$start      = 0;
    }
    $sth->finish();
    return $data;
}

=head2 $fs->truncate($path,$length)

Shorten the contents of the file located at $path to the length
indicated by $length.

=cut

sub truncate {
    my $self = shift;
    my ($path,$length) = @_;
    $self->ftruncate($path,$length);
}

=head2 $fs->ftruncate($path,$length,$inode)

Like truncate() but you may provide the inode instead of the path.
This is called by Fuse to truncate an open file.

=cut

sub ftruncate {
    my $self = shift;
    my ($path,$length,$inode) = @_;

    $inode ||= $self->path2inode($path);
    $self->_isdir($inode) and croak "$path is a directory";

    my $dbh    = $self->dbh;
    $length  ||= 0;

    # check that length isn't greater than current position
    my @stat   = $self->getattr($path);
    $stat[7] >= $length or croak "length beyond end of file";

    my $last_block = int($length/$self->blocksize);
    my $trunc      = $length % $self->blocksize;
    eval {
	$dbh->begin_work;
	$dbh->do("delete from extents where inode=$inode and block>$last_block");
	$dbh->do("update      extents set contents=substr(contents,1,$trunc) where inode=$inode and block=$last_block");
	$dbh->do("update metadata set size=$length where inode=$inode");
	$self->touch($inode,'mtime');
	$dbh->commit;
    };
    if ($@) {
	eval {$dbh->rollback()};
	die "Couldn't update because $@";
    }
    1;
}

=head2 $fs->utime($path,$atime,$mtime)

Update the atime and mtime of the indicated file or directory to the
values provided. You must have write permissions to the file in order
to do this.

=cut

sub utime {
    my $self = shift;
    my ($path,$atime,$mtime) = @_;
    my $inode = $self->path2inode($path) ;
    $self->check_perm($inode,W_OK);
    my $dbh    = $self->dbh;
    my $sth    = $dbh->prepare_cached($self->_update_utime_sql);
    my $result = $sth->execute($atime,$mtime,$inode);
    $sth->finish();
    return $result;
}

=head2 $fs->access($path,$access_mode)

This method checks the current user's permissions for a file or
directory. The arguments are the path to the item of interest, and the
mode is one of the following constants:

 F_OK   check for existence of file

or a bitwise OR of one or more of:

 R_OK   check that the file can be read
 W_OK   check that the file can be written to
 X_OK   check that the file is executable

These constants can be obtained from the POSIX module.

=cut

sub access {
    my $self = shift;
    my ($path,$access_mode) = @_;
    my $inode = $self->path2inode($path);
    return $self->check_perm($inode,$access_mode);
}

sub check_open_perm {
    my $self = shift;
    my ($inode,$flags) = @_;
    $flags         &= 0x3;
    my $wants_read  = $flags==O_RDONLY || $flags==O_RDWR;
    my $wants_write = $flags==O_WRONLY || $flags==O_RDWR;
    my $mask        = 0000;
    $mask          |= R_OK if $wants_read;
    $mask          |= W_OK if $wants_write;
    return $self->check_perm($inode,$mask);
}

=head2 $errno = $fs->errno($message)

Most methods defined by this module are called within an eval{} to
trap errors. On an error, the message contained in $@ is passed to
errno() to turn it into a UNIX error code. The error code is then
returned to the Fuse module.

The following is the limited set of mappings performed:

  Eval{} error message       Unix Errno   Context
  --------------------       ----------   -------

  not found                  ENOENT       Path lookups
  file exists                EEXIST       Path creation
  is a directory             EISDIR       Attempt to open/read/write a directory
  not a directory            ENOTDIR      Attempt to list entries from a file
  length beyond end of file  EINVAL       Truncate file to longer than current length
  not empty                  ENOTEMPTY    Attempt to remove a directory that is in use
  permission denied          EACCESS      Access modes don't allow requested operation

The full error message usually has further detailed information. For
example the full error message for "not found" is "$path not found"
where $path contains the requested path.

All other errors, including problems in the underlying DBI database
layer, result in an error code of EIO ("I/O error"). These constants
can be obtained from POSIX.

=cut


sub errno {
    my $self    = shift;
    my $message = shift;
    return -ENOENT()    if $message =~ /not found/;
    return -EEXIST()    if $message =~ /file exists/;
    return -EISDIR()    if $message =~ /is a directory/;
    return -EPERM()     if $message =~ /hard links of directories not allowed/;
    return -ENOTDIR()   if $message =~ /not a directory/;
    return -EINVAL()    if $message =~ /length beyond end of file/;
    return -ENOTEMPTY() if $message =~ /not empty/;
    return -EACCES()    if $message =~ /permission denied/;
    return -ENOATTR()   if $message =~ /no such attribute/;
    return -EEXIST()    if $message =~ /attribute exists/;
    warn $message;      # something unexpected happened!
    return -EIO();
}

=head2 $result = $fs->setxattr($path,$name,$val,$flags)

This method sets the extended attribute named $name to the value
indicated by $val for the file or directory in $path. The Fuse
documentation states that $flags will be one of XATTR_REPLACE or
XATTR_CREATE, but in my testing I have only seen the value 0 passed.

On success, the method returns 0.

=cut

sub setxattr {
    my $self = shift;
    my ($path,$xname,$xval,$xflags) = @_;
    my $inode = $self->path2inode($path);
    my $dbh = $self->dbh;
    if (!$xflags) {
	my $sql = 'replace into xattr (inode,name,value) values (?,?,?)';
	my $sth = $dbh->prepare_cached($sql);
	$sth->execute($inode,$xname,$xval);
	$sth->finish;
    }
    elsif ($xflags&XATTR_REPLACE) {
	my $sql = 'update xattr set value=? where inode=? and name=?';
	my $sth = $dbh->prepare_cached($sql);
	my $rows = eval {$sth->execute($xval,$inode,$xname)};
	$sth->finish;
	die "no such attribute" unless $rows>0;
    }
    elsif ($xflags&XATTR_CREATE) {
	my $sql = 'insert into xattr (inode,name,value) values (?,?,?)';
	my $sth = $dbh->prepare_cached($sql);
	eval {$sth->execute($inode,$xname,$xval)};
	die "attribute exists" if $@ =~ /not unique|duplicate/i;
	$sth->finish;
    } else {
	die "Can't interpret value of setxattr flags=$xflags";
    }
    return 0;
}

=head2 $val = $fs->getxattr($path,$name)

Reads the extended attribute named $name from the file or directory at
$path and returns the value. Will return undef if the attribute not
found.

Note that when the filesystem is mounted, the Fuse interface provides
no way to distinguish between an attribute that does not exist versus
one that does exist but has value "0". The only workaround for this is
to use "attr -l" to list the attributes and look for the existence of
the desired attribute.


=cut

sub getxattr {
    my $self = shift;
    my ($path,$xname) = @_;
    my $inode = $self->path2inode($path);
    my $dbh   = $self->dbh;
    my $name  = $dbh->quote($xname);
    my ($value) = $dbh->selectrow_array("select value from xattr where inode=$inode and name=$name");
    return $value;
}

=head2 @attribute_names = $fs->listxattr($path)

List all xattributes for the file or directory at the indicated path
and return them as a list.

=cut

sub listxattr {
    my $self = shift;
    my $path = shift;
    my $inode = $self->path2inode($path);
    my $names = $self->dbh->selectcol_arrayref("select name from xattr where inode=$inode");
    $names ||= [];
    return @$names;
}

=head2 $fs->removexattr($path,$name)

Remove the attribute named $name for path $path. Will raise a "no such
attribute" error if then if the attribute does not exist.

=cut

sub removexattr {
    my $self = shift;
    my ($path,$xname) = @_;
    my $dbh = $self->dbh;
    my $inode = $self->path2inode($path);
    my $sth   = $dbh->prepare_cached("delete from xattr where inode=? and name=?");
    $sth->execute($inode,$xname);
    $sth->rows > 0 or die "no such attribute named $xname";
    $sth->finish;
    return 0;
}

=head1 LOW LEVEL METHODS

The following methods may be of interest for those who wish to
understand how this module works, or want to subclass and extend this
module.

=cut

=head2 $fs->initialize_schema

This method is called to initialize the database schema. The database
must already exist and be writable by the current user. All previous
data will be deleted from the database.

The default schema contains three tables:

 metadata -- Information about the inode used for the stat() call. This
             includes its length, modification and access times, 
             permissions, and ownership. There is one row per inode,
             and the inode is the table's primary key.

 path     -- Maps paths to inodes. Each row is a distinct component
             of a path and contains the name of the component, the 
             inode of the parent component, and the inode corresponding
             to the component. This is illustrated below.

 extents  -- Maps inodes to the contents of the file. Each row consists
             of the inode of the file, the block number of the data, and
             a blob containing the data in that block.

For the mysql adapter, here is the current schema:

metadata:

 +--------+------------+------+-----+---------------------+----------------+
 | Field  | Type       | Null | Key | Default             | Extra          |
 +--------+------------+------+-----+---------------------+----------------+
 | inode  | int(10)    | NO   | PRI | NULL                | auto_increment |
 | mode   | int(10)    | NO   |     | NULL                |                |
 | uid    | int(10)    | NO   |     | NULL                |                |
 | gid    | int(10)    | NO   |     | NULL                |                |
 | rdev   | int(10)    | YES  |     | 0                   |                |
 | links  | int(10)    | YES  |     | 0                   |                |
 | inuse  | int(10)    | YES  |     | 0                   |                |
 | size   | bigint(20) | YES  |     | 0                   |                |
 | mtime  | timestamp  | NO   |     | 0000-00-00 00:00:00 |                |
 | ctime  | timestamp  | NO   |     | 0000-00-00 00:00:00 |                |
 | atime  | timestamp  | NO   |     | 0000-00-00 00:00:00 |                |
 +--------+------------+------+-----+---------------------+----------------+

path:

 +--------+--------------+------+-----+---------+-------+
 | Field  | Type         | Null | Key | Default | Extra |
 +--------+--------------+------+-----+---------+-------+
 | inode  | int(10)      | NO   |     | NULL    |       |
 | name   | varchar(255) | NO   |     | NULL    |       |
 | parent | int(10)      | YES  | MUL | NULL    |       |
 +--------+--------------+------+-----+---------+-------+

extents:

 +----------+---------+------+-----+---------+-------+
 | Field    | Type    | Null | Key | Default | Extra |
 +----------+---------+------+-----+---------+-------+
 | inode    | int(10) | YES  | MUL | NULL    |       |
 | block    | int(10) | YES  |     | NULL    |       |
 | contents | blob    | YES  |     | NULL    |       |
 +----------+---------+------+-----+---------+-------+

The B<metadata table> is straightforward. The meaning of most columns
can be inferred from the stat(2) manual page. The only columns that
may be mysterious are "links" and "inuse". "links" describes the
number of distinct paths involving a file or directory. Files start
out with one link and are incremented by one every time a hardlink is
created (symlinks don't count). Directories start out with two links
(one for '..' and the other for '.') and are incremented by one every
time a file or subdirectory is added to the directory. The "inuse"
column is incremented every time a file is opened for reading or
writing, and decremented when the file is closed. It is used to
prevent the content from being deleted if the file is still in use.

The B<path table> is organized to allow rapid translation from a pathname
to an inode. Each entry in the tree is identified by its inode, its
name, and the inode of its parent directory. The inode of the root "/"
node is hard-coded to 1. The following steps show the effect of
creating subdirectories and files on the path table:

After initial filesystem initialization there is only one entry
in paths corresponding to the root directory. The root has no parent:

 +-------+------+--------+
 | inode | name | parent |
 +-------+------+--------+
 |     1 | /    |   NULL |
 +-------+------+--------+

$ mkdir directory1
 +-------+------------+--------+
 | inode | name       | parent |
 +-------+------------+--------+
 |     1 | /          |   NULL |
 |     2 | directory1 |      1 |
 +-------+------------+--------+

$ mkdir directory1/subdir_1_1

 +-------+------------+--------+
 | inode | name       | parent |
 +-------+------------+--------+
 |     1 | /          |   NULL |
 |     2 | directory1 |      1 |
 |     3 | subdir_1_1 |      2 |
 +-------+------------+--------+

$ mkdir directory2

 +-------+------------+--------+
 | inode | name       | parent |
 +-------+------------+--------+
 |     1 | /          |   NULL |
 |     2 | directory1 |      1 |
 |     3 | subdir_1_1 |      2 |
 |     4 | directory2 |      1 |
 +-------+------------+--------+

$ touch directory2/file1.txt

 +-------+------------+--------+
 | inode | name       | parent |
 +-------+------------+--------+
 |     1 | /          |   NULL |
 |     2 | directory1 |      1 |
 |     3 | subdir_1_1 |      2 |
 |     4 | directory2 |      1 |
 |     5 | file1.txt  |      4 |
 +-------+------------+--------+

$ ln directory2/file1.txt link_to_file1.txt

 +-------+-------------------+--------+
 | inode | name              | parent |
 +-------+-------------------+--------+
 |     1 | /                 |   NULL |
 |     2 | directory1        |      1 |
 |     3 | subdir_1_1        |      2 |
 |     4 | directory2        |      1 |
 |     5 | file1.txt         |      4 |
 |     5 | link_to_file1.txt |      1 |
 +-------+-------------------+--------+

Notice in the last step how creating a hard link establishes a second
entry with the same inode as the original file, but with a different
name and parent.

The inode for path /directory2/file1.txt can be found with this
recursive-in-spirit SQL fragment:

 select inode from path where name="file1.txt" 
              and parent in 
                (select inode from path where name="directory2" 
                              and parent in
                                (select 1)
                )

The B<extents table> provides storage of file (and symlink)
contents. During testing, it turned out that storing the entire
contents of a file into a single BLOB column provided very poor random
access performance. So instead the contents are now broken into blocks
of constant size 4096 bytes. Each row of the table corresponds to the
inode of the file, the block number (starting at 0), and the data
contained within the block. In addition to dramatically better
read/write performance, this scheme allows sparse files (files
containing "holes") to be stored efficiently: Blocks that fall within
holes are completely absent from the table, while those that lead into
a hole are shorter than the full block length.

The logical length of the file is stored in the metadata size
column.

If you have subclassed DBI::Filesystem and wish to adjust the default
schema (such as adding indexes), this is the place to do it. Simply
call the inherited initialize_schema(), and then alter the tables as
you please.

=cut

sub initialize_schema {
    my $self = shift;
    my $dbh  = $self->dbh;
    $dbh->do('drop table if exists metadata')   or croak $dbh->errstr;
    $dbh->do('drop table if exists path')       or croak $dbh->errstr;
    $dbh->do('drop table if exists extents')    or croak $dbh->errstr;
    $dbh->do('drop table if exists sqlfs_vars') or croak $dbh->errstr;
    $dbh->do('drop table if exists xattr')      or croak $dbh->errstr;
    eval{$dbh->do('drop index if exists iblock')};
    eval{$dbh->do('drop index if exists ipath')};

    
    $dbh->do($_) foreach split ';',$self->_metadata_table_def;
    $dbh->do($_) foreach split ';',$self->_path_table_def;
    $dbh->do($_) foreach split ';',$self->_extents_table_def;
    $dbh->do($_) foreach split ';',$self->_variables_table_def;
    $dbh->do($_) foreach split ';',$self->_xattr_table_def;

    # create the root node
    # should update this to use fuse_get_context to get proper uid, gid and masked permissions
    my $ctx  = $self->get_context;
    my $mode = (0040000|0777)&~$ctx->{umask};
    my $uid = $ctx->{uid};
    my $gid = $ctx->{gid};
    my $timestamp = $self->_now_sql();
    # bug: we assume that sequence begins with 1
    $dbh->do("insert into metadata (mode,uid,gid,links,mtime,ctime,atime) values ($mode,$uid,$gid,2,$timestamp,$timestamp,$timestamp)") 
	or croak $dbh->errstr;
    $dbh->do("insert into path (inode,name,parent) values (1,'/',null)")
	or croak $dbh->errstr;
    $self->set_schema_version($self->schema_version);
}

=head2 $ok = $fs->check_schema

This method is called when opening a preexisting database. It checks
that the metadata, path and extents tables exist in the database and
have the expected relationships. Returns true if the check passes.

=cut

sub check_schema {
    my $self     = shift;
    local $self->{dbh};  # to avoid cloning database handle into child threads
    my ($result) = eval {
 	$self->dbh->selectrow_array('select 1 from metadata as m,path as p left join extents as e on e.inode=p.inode where m.inode=1 and p.parent=1');
    };
     return !$@;
}

=head2 $version = $fs->schema_version

This method returns the schema version understood by this module. It
is used when opening up a sqlfs databse to check whether database was
created by an earlier or later version of the software. The schema
version is distinct from the library version since updates to the library
do not always necessitate updates to the schema.

Versions are small integers beginning at 1.

=cut

sub schema_version {
    return SCHEMA_VERSION;
}

=head2 $version = $fs->get_schema_version

This returns the schema version known to a preexisting database.

=cut

sub get_schema_version {
    my $self = shift;
    my ($result) = eval { $self->dbh->selectrow_array("select value from sqlfs_vars where name='schema_version'") };
    return $result || 1;
}

=head2 $fs->set_schema_version($version)

This sets the databases's schema version to the indicated value.

=cut

sub set_schema_version {
    my $self = shift;
    my $version = shift;
    $self->dbh->do("replace into sqlfs_vars (name,value) values ('schema_version','$version')");
}

=head2 $fs->check_schema_version 

This checks whether the schema version in a preexisting database is
compatible with the version known to the library. If the version is
from an earlier version of the library, then schema updating will be
attempted. If the database was created by a newer version of the
software, the method will raise a fatal exception.

=cut

sub check_schema_version {
    my $self = shift;
    my $current_version = $self->schema_version;
    my $db_version      = $self->get_schema_version;
    return if $current_version == $db_version;
    die "This module understands schema version $current_version, but database was created with schema version $db_version"
	if $db_version > $current_version;
    # otherwise we evolve...
    my $ok = 1;
    for (my $i=$db_version;$i<$current_version;$i++) {
	print STDERR "Updating database schema from version $i to version ",$i+1,"...\n";
	my $method = "_update_schema_from_${i}_to_".($i+1);
	$ok &&= eval{$self->$method};
	warn $@ if $@;
    }
    die "Update failed" unless $ok;
    eval {$self->dbh->do($_)} foreach split ';',$self->_variables_table_def;
    $self->set_schema_version($self->schema_version);
}

###### schema update statements ######

=head2 $fs->_update_schema_from_A_to_B

Every update to this library that defines a new schema version has a
series of methods named _update_schema_from_A_to_B(), where A and B are
sequential version numbers. For example, if the current schema version
is 3, then the library will define the following methods:

 $fs->_update_schema_from_1_to_2
 $fs->_update_schema_from_2_to_3

These methods are only of interests to people who want to write
adapters for DBMS engines that are not currently supported, such as
Oracle.

=cut

sub _update_schema_from_1_to_2 {
    my $self = shift;
    my $dbh  = $self->dbh;
    $dbh->do('alter table metadata change column length size bigint default 0');
    $dbh->do($self->_variables_table_def);
    1;
}

sub _update_schema_from_2_to_3 {
    my $self = shift;
    my $dbh  = $self->dbh;
    $dbh->do($_) foreach split ';',$self->_xattr_table_def;
    1;
}

sub _variables_table_def {
    return <<END;
create table sqlfs_vars (
    name   varchar(255) primary key,
    value  varchar(255)
)
END
}

=Head2 $size = $fs->blocksize

This method returns the blocksize (currently 4096 bytes) used for
writing and retrieving file contents to the extents table. Because
4096 is a typical value used by libc, altering the value in subclasses
will probably degrade performance. Also be aware that altering the
blocksize will render filesystems created with other blocksize values
unreadable.

=cut

sub blocksize   { return 4096 }

=head2 $count = $fs->flushblocks

This method returns the maximum number of blocks of file contents data
that can be stored in memory before it is written to disk. Because all
blocks are written to the database in a single transaction, this can
have a dramatic performance effect and it is worth trying different
values when tuning the module for new DBMSs.

The default is 64.

=cut

sub flushblocks { return   64 }


=head2 $fixed_path = fixup($path)

This is an ordinary function (not a method!) that removes the initial
slash from paths passed to this module from Fuse. The root directory
(/) is not changed:

 Before      After fixup()
 ------      -------------
 /foo        foo
 /foo/bar    foo/bar
 /          /

To call this method from subclasses, invoke it as DBI::Filesystem::fixup().

=cut

sub fixup {
    my $path = shift;
    no warnings;
    $path    =~ s!^/!!;
    $path   || '/';
}

=head2 $dsn = $fs->dsn

This method returns the DBI data source passed to new(). It cannot be
changed.

=cut

sub dsn { shift->{dsn} }

=head2 $dbh = $fs->dbh

This method opens a connection to the database defined by dsn() and
returns the database handle (or raises a fatal exception). The
database handle will have its RaiseError and AutoCommit flags set to
true. Since the mount function is multithreaded, there will be one
database handle created per thread.

=cut

sub dbh {
    my $self = shift;
    my $dsn  = $self->dsn;
    return $self->{dbh} if $self->{dbh};
    my $dbh = DBI->connect($dsn,
			   undef,undef,
			   {RaiseError=>1,
			    PrintError=>0,
			    AutoCommit=>1}) or die DBI->errstr;
    $self->_dbh_init($dbh) if $self->can('_dbh_init');
    return $self->{dbh}=$dbh;
}

=head2 $inode = $fs->create_inode($type,$mode,$rdev,$uid,$gid)

This method creates a new inode in the database. An inode corresponds
to a file, directory, symlink, pipe or block special device, and has a
unique integer ID defining it as its primary key. Arguments are the
type of inode to create, which is used to check that the passed mode
is correct ('f'=file, 'd'=directory,'l'=symlink; anything else is
ignored), the mode of the inode, which is a combination of type and
access permissions as described in stat(2), the device ID if a special
file, and the desired UID and GID.

The return value is the newly-created inode ID.

You will ordinarily use the mknod() and mkdir() methods to create
files, directories and special files.

=cut

sub create_inode {
    my $self        = shift;
    my ($type,$mode,$rdev,$uid,$gid) = @_;

    $mode ||= 0777; # set filetype unless already set
    $mode  |=  $type eq 'f'       ? 0100000
              :$type eq 'd'       ? 0040000
              :$type eq 'l'       ? 0120000
              :0000000 unless $mode&0777000;

    $uid  ||= 0;
    $gid  ||= 0;
    $rdev ||= 0;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare_cached($self->_create_inode_sql);
    $sth->execute($mode,$uid,$gid,$rdev,$type eq 'd' ? 1 : 0) or die $sth->errstr;
    $sth->finish;
    return $self->last_inserted_inode($dbh);
}

=head2 $id = $fs->last_inserted_inode($dbh)

After a new inode is inserted into the database, this method returns
its ID. Unique inode IDs are generated using various combinations of
database autoincrement and sequence semantics, which vary from DBMS to
DBMS, so you may need to override this method in subclasses.

The default is simply to call DBI's last_insert_id method:

 $dbh->last_insert_id(undef,undef,undef,undef)

=cut

sub last_inserted_inode {
    my $self = shift;
    my $dbh  = shift;
    return $dbh->last_insert_id(undef,undef,undef,undef);
}

=head2 $self->create_path($inode,$path)

After creating an inode, you can associate it with a path in the
filesystem using this method. It will raise an error if unsuccessful.

=cut

# this links an inode to a path
sub create_path {
    my $self = shift;
    my ($inode,$path) = @_;

    my $parent = $self->path2inode($self->_dirname($path));
    my $base   = basename($path);
    $base      =~ s!/!_!g;

    my $dbh  = $self->dbh;
    my $sth  = $dbh->prepare_cached('insert into path (inode,name,parent) values (?,?,?)');
    $sth->execute($inode,$base,$parent);
    $sth->finish;

    $dbh->do("update metadata set links=links+1 where inode=$inode");
    $dbh->do("update metadata set links=links+1 where inode=$parent");
    $self->touch($parent,'ctime');
    $self->touch($parent,'mtime');
}

=head2 $inode=$self->create_inode_and_path($path,$type,$mode,$rdev)

Create an inode and associate it with the indicated path, returning
the inode ID. Arguments are the path, the file type (one of 'd', 'f',
or 'l' for directory, file or symbolic link). As usual, this may exit
with a fatal error.

=cut

sub create_inode_and_path {
    my $self = shift;
    my ($path,$type,$mode,$rdev) = @_;
    my $dbh    = $self->dbh;
    my $inode;

    my $parent = $self->path2inode($self->_dirname($path));
    $self->check_perm($parent,W_OK);

    my $ctx = $self->get_context;

    eval {
	$dbh->begin_work;
	$inode  = $self->create_inode($type,$mode,$rdev,@{$ctx}{'uid','gid'});
	$self->create_path($inode,$path);
	$dbh->commit;
    };
    if ($@) {
	my $message = $@;
	eval{$dbh->rollback()};
	die "commit failed due to $message";
    }
    return $inode;
}

=head2 $fs->unlink_inode($inode)

Given an inode, this deletes it and its contents, but only if the file
is no longer in use. It will die with an exception if the changes
cannot be committed to the database.

=cut


sub unlink_inode {
    my $self = shift;
    my $inode = shift;
    my $dbh   = $self->dbh;
    my ($references) = $dbh->selectrow_array("select links+inuse from metadata where inode=$inode");
    return if $references > 0;
    eval {
	$dbh->begin_work;
	$dbh->do("delete from metadata where inode=$inode") or die $dbh->errstr;
	$dbh->do("delete from extents  where inode=$inode") or die $dbh->errstr;
	$dbh->commit;
    };
    if ($@) {
	eval {$dbh->rollback};
	die "commit aborted due to $@";
    }
}

=head2 $boolean = $fs->check_path($name,$inode,$uid,$gid)

Given a directory's name, inode, and the UID and GID of the current
user, this will traverse all containing directories checking that
their execute permissions are set. If the directory and all of its
parents are executable by the current user, then returns true.

=cut

# traverse path recursively, checking for X permission
sub check_path {
    my $self = shift;
    my ($dir,$inode,$uid,$gid) = @_;

    return 1 if $self->ignore_permissions;

    my $groups   = $self->get_groups($uid,$gid);

    my $dbh      = $self->dbh;
    my $sth = $dbh->prepare_cached(<<END);
select p.parent,m.mode,m.uid,m.gid
       from path as p,metadata as m
       where p.inode=m.inode
       and   p.inode=? and p.name=?
END
;
    my $name  = basename($dir);
    my $ok  = 1;
    while ($ok) {
	$sth->execute($inode,$name);
	my ($node,$mode,$owner,$group) = $sth->fetchrow_array() or last;
	my $mask     = $uid==$owner       ? S_IXUSR
	               :$groups->{$group} ? S_IXGRP
                       :S_IXOTH;
	my $allowed = $mask & $mode;
	$ok &&= $allowed;
	$inode          = $node;
	$dir            = $self->_dirname($dir);
	$name           = basename($dir);
    }
    $sth->finish;
    return $ok;
}

=head2 $fs->check_perm($inode,$access_mode)

Given a file or directory's inode and the access mode (a bitwise OR of
R_OK, W_OK, X_OK), checks whether the current user is allowed
access. This will return if access is allowed, or raise a fatal error
potherwise.

=cut

sub check_perm {
    my $self = shift;
    my ($inode,$access_mode) = @_;

    return 1 if $self->ignore_permissions;

    my $ctx = $self->get_context;
    my ($uid,$gid) = @{$ctx}{'uid','gid'};

    return 0 if $uid==0; # root can do anything

    my $dbh      = $self->dbh;

    my $fff = 0xfff;
    my ($mode,$owner,$group) 
	= $dbh->selectrow_array("select $fff&mode,uid,gid from metadata where inode=$inode");

    my $groups      = $self->get_groups($uid,$gid);
    if ($access_mode == F_OK) {
	die "permission denied" unless $uid==$owner || $groups->{$group};
	return 1;
    }

    my $perm_word   = $uid==$owner      ? $mode >> 6
                     :$groups->{$group} ? $mode >> 3
                     :$mode;
    $perm_word     &= 07;

    $access_mode==($perm_word & $access_mode) or die "permission denied";
    return 1;
}     

=head2 $fs->touch($inode,$field)

This updates the file/directory indicated by $inode to the current
time. $field is one of 'atime', 'ctime' or 'mtime'.

=cut

sub touch {
    my $self  = shift;
    my ($inode,$field) = @_;
    my $now = $self->_now_sql;
    $self->dbh->do("update metadata set $field=$now where inode=$inode");
}

=head2 $inode = $fs->path2inode($path)

=head2 ($inode,$parent_inode,$name) = $self->path2inode($path)

This method takes a filesystem path and transforms it into an inode if
the path is valid. In a scalar context this method return just the
inode. In a list context, it returns a three element list consisting
of the inode, the inode of the containing directory, and the basename
of the file.

This method does permission and access path checking, and will die
with a "permission denied" error if either check fails. In addition,
passing an invalid path will return a "path not found" error.

=cut

# in scalar context return inode
# in list context return (inode,parent_inode,name)
sub path2inode {
    my $self   = shift;
    my $path   = shift;

    my $dynamic;
    my ($inode,$p_inode,$name) = eval {	$self->_path2inode($path)};
    unless ($inode) {
	($inode,$p_inode,$name) = $self->_dynamic_path2inode($path);
	$dynamic++ if $inode;
    }
    croak "$path not found" unless $inode;

    my $ctx = $self->get_context;
    $self->check_path($self->_dirname($path),$p_inode,@{$ctx}{'uid','gid'}) or die "permission denied";
    return wantarray ? ($inode,$p_inode,$name,$dynamic) : $inode;
}

sub _dynamic_path2inode {
    my $self = shift;
    my $path      = shift;
    return unless $self->allow_magic_dirs;
    my $dirname     = $self->_dirname($path);
    my $basename    = basename($path);
    my ($dir_inode) = $self->_path2inode($dirname)   or return;
    $self->_is_dynamic_dir($dir_inode,$dirname)   or return;
    my $entries = $self->get_dynamic_entries($dir_inode,$dirname);
    $entries->{$basename}                         or return;
    my ($inode,$parent) = @{$entries->{$basename}};
    return ($inode,$parent,$basename);
}

sub _path2inode {
    my $self   = shift;
    my $path   = shift;
    if ($path eq '/') {
	return wantarray ? (1,undef,'/') : 1;
    }
    $path =~ s!/$!!;
    my ($sql,@bind) = $self->_path2inode_sql($path);
    my $dbh    = $self->dbh;
    my $sth    = $dbh->prepare_cached($sql) or croak $dbh->errstr;
    $sth->execute(@bind);
    my @v      = $sth->fetchrow_array() or croak "$path not found";
    $sth->finish;
    return @v;
}

=head2 @paths = $fs->inode2paths($inode)

Given an inode, this method returns the path(s) that correspond to
it. There may be multiple paths since file inodes can have hard
links. In addition, there may be NO path corresponding to an inode, if
the file is open but all externally accessible links have been
unlinked.

Be aware that the B<path table> is indexed to make path to inode
searches fast, not the other way around. If you build a content search
engine on top of DBI::Filesystem and rely on this method, you may wish
to add an index to the path table's "inode" field.

=cut

# returns a list of paths that correspond to an inode
# because files can be hardlinked, there may be multiple paths!
sub inode2paths {
    my $self   = shift;
    my $inode  = shift;
    my $dbh    = $self->dbh;
    #BUG: inode is not indexed in this table, so this may be slow!
    # consider adding an index
    my $sth    = $dbh->prepare_cached('select name,parent from path where inode=?');
    $sth->execute($inode);
    my @results;
    while (my ($name,$parent) = $sth->fetchrow_array) {
	my $directory = $self->_inode2path($parent);
	push @results,"$directory/$name";
    }
    $sth->finish;
    return @results;
}

# recursive walk up the file tree
# this should only be called on directories, as we know
# they do not have hard links
sub _inode2path {
    my $self  = shift;
    my $inode = shift;
    return '' if $inode == 1;
    my $dbh  = $self->dbh;
    my ($name,$parent) = $dbh->selectrow_array("select name,parent from path where inode=$inode");
    return $self->_inode2path($parent)."/".$name;
}

sub _dirname {
    my $self = shift;
    my $path = shift;
    my $dir  = dirname($path);
    $dir     = '/' if $dir eq '.'; # work around funniness in dirname()    
    return $dir;
}

sub _path2inode_sql {
    my $self   = shift;
    my $path   = shift;
    my (undef,$dir,$name) = File::Spec->splitpath($path);
    my ($parent,@base)    = $self->_path2inode_subselect($dir); # something nicely recursive
    my $sql               = <<END;
select p.inode,p.parent,p.name from metadata as m,path as p 
       where p.name=? and p.parent in ($parent) 
         and m.inode=p.inode
END
;
    return ($sql,$name,@base);
}

sub _path2inode_subselect {
    my $self = shift;
    my $path = shift;
    return 'select 1' if $path eq '/' or !length($path);
    $path =~ s!/$!!;
    my (undef,$dir,$name) = File::Spec->splitpath($path);
    my ($parent,@base)    = $self->_path2inode_subselect($dir); # something nicely recursive
    return (<<END,$name,@base);
select p.inode from metadata as m,path as p
    where p.name=? and p.parent in ($parent)
    and m.inode=p.inode
END
;
}

=head2 $groups = $fs->get_groups($uid,$gid)

This method takes a UID and GID, and returns the primary and
supplemental groups to which the user is assigned, and is used during
permission checking. The result is a hashref in which the keys are the
groups to which the user belongs.

=cut

sub get_groups {
    my $self = shift;
    my ($uid,$gid) = @_;
    return $self->{_group_cache}{$uid} ||= $self->_get_groups($uid,$gid);
}

sub _get_groups {
    my $self = shift;
    my ($uid,$gid) = @_;
    my %result;
    $result{$gid}++;
    my $username = getpwuid($uid) or return \%result;
    while (my($name,undef,$id,$members) = getgrent) {
	next unless $members =~ /\b$username\b/;
	$result{$id}++;
    }
    endgrent;
    return \%result;
}

=head2 $ctx = $fs->get_context

This method is a wrapper around the fuse_get_context() function
described in L<Fuse>. If called before the filesystem is mounted, then
it fakes the call, returning a context object based on the information
in the current process.

=cut

sub get_context {
    my $self = shift;
    return fuse_get_context() if $self->mounted;
    my ($gid) = $( =~ /^(\d+)/;
    return {
	uid   => $<,
	gid   => $gid,
	pid   => $$,
	umask => umask()
    }
}

################# a few SQL fragments; most are inline or in the DBD-specific descendents ######
sub _fgetattr_sql {
    my $self  = shift;
    my $inode = shift;
    my $times = join ',',map{$self->_get_unix_timestamp_sql($_)} 'ctime','mtime','atime';
    return <<END;
select inode,mode,uid,gid,rdev,links,
       $times,size
 from metadata
 where inode=$inode
END
}

sub _create_inode_sql {
    my $self = shift;
    my $now = $self->_now_sql;
    return "insert into metadata (mode,uid,gid,rdev,links,mtime,ctime,atime) values(?,?,?,?,?,$now,$now,$now)";
}


1;

=head1 SUBCLASSING

Subclass this module as you ordinarily would by creating a new package
that has a "use base DBI::Filesystem". You can then tell the
command-line sqlfs.pl tool to load your subclass rather than the
original by providing a --module (or -M) option, as in:

 $ sqlfs.pl -MDBI::Filesystem::MyClass <database> <mtpt>

=head1 AUTHOR

Copyright 2013, Lincoln D. Stein <lincoln.stein@gmail.com>

=head1 LICENSE

This package is distributed under the terms of the Perl Artistic
License 2.0. See http://www.perlfoundation.org/artistic_license_2_0.

=cut

__END__
