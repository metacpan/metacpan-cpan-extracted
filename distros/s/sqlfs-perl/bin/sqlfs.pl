#!/usr/bin/perl
 
=head1 NAME

sqlfs.pl - Mount Fuse filesystem on a SQL database

=head1 SYNOPSIS

 % sqlfs.pl [options] dbi:<driver_name>:database=<name>;<other_args> <mount point>

Options:

  --initialize                  initialize an empty filesystem
  --quiet                       don't ask for confirmation of initialization
  --allow_magic                 allow "magic" directories (see below)
  --unmount                     unmount the indicated directory
  --foreground                  remain in foreground (false)
  --nothreads                   disable threads (false)
  --debug                       enable Fuse debugging messages
  --module=<ModuleName>         Use a subclass of DBI::Filesystem

  --option=allow_other          allow other accounts to access filesystem (false)
  --option=default_permissions  enable permission checking by kernel (false)
  --option=fsname=<name>        set filesystem name (none)
  --option=use_ino              let filesystem set inode numbers (false)
  --option=direct_io            disable page cache (false)
  --option=nonempty             allow mounts over non-empty file/dir (false)
  --option=ro                   mount read-only
  -o ro,direct_io,etc           shorter version of options

  --help                        this text
  --man                         full manual page

Options can be abbreviated to single letters.

=head1 DESCRIPTION

This script will create a userspace filesystem stored entirely in a
SQL database. Only the MySQL, SQLite and PostgreSQL database engines
are currently supported. Most functionality is supported, including
hard and symbolic links, seek() and tell(), binary data, sparse files,
and the ability to unlink a file while there is still a filehandle
open on it.

The mandatory first argument is a DBI driver database source name,
such as:

 dbi:mysql:database=my_filesystem

The database must already exist, and you must have insert, update,
create table, and select privileges on it.  If you need to provide
hostname, port, username, etc, these must be included in the source
string, e.g.:

 dbi:mysql:database=my_filesystem;host=my_host;user=fred;password=xyzzy

If you request unmounting (using --unmount or -u), the first
non-option argument is interpreted as the mountpoint, not database
name.

After initial checks, this command will go into the background. To
keep it in the foreground, pass the --foreground option. Interrupting
the foreground process will (try to) unmount the filesystem.

=head1 MORE INFORMATION

This is a front end to the DBI::Filesystem module, which creates a
fully-functioning userspace filesystem on top of a relational
database. Unlike other filesystem-to-DBM mappings, such as Fuse::DBI,
this one creates and manages a specific schema designed to support
filesystem operations. If you wish to mount a filesystem on an
arbitrary DBM schema, you want Fuse::DBI, not this.

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

=head2 "Magic" Directories

The --allow_magic option enables a form of "view" directory in which
the directory is automagically populated with the results of running a
simple (or complex) SQL query across the entire filesystem. To try
this out, create one or more directories that begin with the magic
characters "%%", and then create a dotfile within this directory named
".query".  ".query" must contain a SQL query that returns a series of
one or more inodes. These will be used to populate the directory
automagically. The query can span multiple lines, and lines that begin
with "#" will be ignored.

You must understand the simple schema used by this module to be able
to write such queries. To learn about the schema, see
L<DBI::Filesystem>.

Here is a simple example which will run on all DBMSs:

 # display all files greater than 2 Mb in size
 select inode from metadata where size>2000000

Another example, which uses MySQL-specific date/time
math:

 # all .jpg files created/modified within the last day
 select m.inode from metadata as m,path as p
     where p.name like '%.jpg'
       and (now()-interval 1 day) <= m.mtime
       and m.inode=p.inode

(The date/time math syntax is very slightly different for PostgreSQL
and very much different for SQLite)

The files contained within the magic directories can be read and
written just like normal files, but cannot be removed or
renamed. Directories are excluded from magic directories. If two or
more files from different parts of the filesystem have name clashes,
the filesystem will append a number to their end to distinguish them.

=head2 Unsupported Features

The following features are not implemented:

 * statfs -- df on the filesystem will not provide any useful information
            on free space or other filesystem information.

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

=head1 AUTHOR

Copyright 2013, Lincoln D. Stein <lincoln.stein@gmail.com>

=head1 LICENSE

This package is distributed under the terms of the Perl Artistic
License 2.0. See http://www.perlfoundation.org/artistic_license_2_0.

=cut

use strict;
use warnings;
use DBI::Filesystem;
use File::Spec;
use Config;
use POSIX 'setsid';
use POSIX qw(SIGINT SIGTERM SIGHUP);

use Getopt::Long qw(:config no_ignore_case bundling_override);
use Pod::Usage;

my (@FuseOptions,$Module,$UnMount,$Initialize,$Debug,$Quiet,
    $AllowMagic,$NoDaemon,$NoThreads,$Help,$Man);

GetOptions(
    'help|h|?'     => \$Help,
    'man|m'        => \$Man,
    'initialize|i' => \$Initialize,
    'allow_magic|a' => \$AllowMagic,
    'option|o:s'   => \@FuseOptions,
    'foreground|f' => \$NoDaemon,
    'nothreads|n'  => \$NoThreads,
    'unmount|u'    => \$UnMount,
    'module|m|M:s' => \$Module,
    'debug|d'      => \$Debug,
    'quiet|q'      => \$Quiet,
 ) or pod2usage(-verbose=>2);

 pod2usage(1)                          if $Help;
 pod2usage(-exitstatus=>0,-verbose=>2) if $Man;

$NoThreads  ||= check_disable_threads();
$Debug      ||= 0;

if ($UnMount) {
    my $mountpoint = shift;
    exec 'fusermount','-u',$mountpoint;
}
if ($Initialize && !$Quiet && -t STDIN) {
    print STDERR "WARNING: any existing data will be overwritten. Proceed? [y/N] ";
    my $result = <STDIN>;
    die "Aborted\n" unless $result =~ /^[yY]/;
}

my $dsn        = shift or pod2usage(1);
my $mountpoint = shift or pod2usage(1);
$mountpoint    = File::Spec->rel2abs($mountpoint);

my $action = POSIX::SigAction->new(sub { warn "unmounting $mountpoint\n"; 
					 exec 'fusermount','-u',$mountpoint; });

foreach (SIGTERM,SIGINT,SIGHUP) {
    POSIX::sigaction($_=>$action) or die "Couldn't set $_ handler: $!";
}

my $mountopts  = join(',',@FuseOptions);

$Module ||= 'DBI::Filesystem';
eval "require $Module;1"        or die $@;
$Module->isa('DBI::Filesystem') or die "$Module does not inherit from DBI::Filesystem. Abort!\n";
my $filesystem = $Module->new($dsn,{initialize=>$Initialize,allow_magic_dirs=>$AllowMagic});

# become daemon after loading the module, to avoid paths getting confused
become_daemon() unless $NoDaemon;

$filesystem->mount($mountpoint,{debug=>$Debug,threaded=>!$NoThreads,mountopts=>$mountopts});

exit 0;

sub check_disable_threads {
    unless ($Config{useithreads}) {
	warn "This version of perl is not compiled for ithreads. Running with slower non-threaded version.\n";
	return 1;
    }
    if ($] >= 5.014 && $Fuse::VERSION < 0.15) {
	warn "You need Fuse version 0.15 or higher to run under this version of Perl.\n";
	warn "Threads will be disabled. Running with slower non-threaded version.\n";
	return 1;
    }

    return 0;
}

sub become_daemon {
    fork() && exit 0;
    # this actually messes with 
    #  chdir ('/');  
    setsid();
    open STDIN,"</dev/null";
    fork() && exit 0;
}

__END__
