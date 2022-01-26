# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Test::MockFile;

use strict;
use warnings;

# perl -MFcntl -E'eval "say q{$_: } . $_" foreach sort {eval "$a" <=> eval "$b"} qw/O_RDONLY O_WRONLY O_RDWR O_CREAT O_EXCL O_NOCTTY O_TRUNC O_APPEND O_NONBLOCK O_NDELAY O_EXLOCK O_SHLOCK O_DIRECTORY O_NOFOLLOW O_SYNC O_BINARY O_LARGEFILE/'
use Fcntl;    # O_RDONLY, etc.

use constant SUPPORTED_SYSOPEN_MODES => O_RDONLY | O_WRONLY | O_RDWR | O_APPEND | O_TRUNC | O_EXCL | O_CREAT | O_NOFOLLOW;

use constant BROKEN_SYMLINK   => bless {}, "A::BROKEN::SYMLINK";
use constant CIRCULAR_SYMLINK => bless {}, "A::CIRCULAR::SYMLINK";

# we're going to use carp but the errors should come from outside of our package.
use Carp qw(carp confess);
$Carp::Internal{__PACKAGE__}++;
$Carp::Internal{'Overload::FileCheck'}++;

use Cwd                        ();
use IO::File                   ();
use Test::MockFile::FileHandle ();
use Test::MockFile::DirHandle  ();
use Text::Glob                 ();
use Scalar::Util               ();

use Symbol;

use Overload::FileCheck '-from-stat' => \&_mock_stat, q{:check};

use Errno qw/EPERM ENOENT ELOOP EEXIST EISDIR ENOTDIR EINVAL/;

use constant FOLLOW_LINK_MAX_DEPTH => 10;

=head1 NAME

Test::MockFile - Allows tests to validate code that can interact with files without touching the file system.

=head1 VERSION

Version 0.025

=cut

our $VERSION = '0.025';

our %files_being_mocked;

# From http://man7.org/linux/man-pages/man7/inode.7.html
use constant S_IFMT    => 0170000;    # bit mask for the file type bit field
use constant S_IFPERMS => 07777;      # bit mask for file perms.

use constant S_IFSOCK => 0140000;     # socket
use constant S_IFLNK  => 0120000;     # symbolic link
use constant S_IFREG  => 0100000;     # regular file
use constant S_IFBLK  => 0060000;     # block device
use constant S_IFDIR  => 0040000;     # directory
use constant S_IFCHR  => 0020000;     # character device
use constant S_IFIFO  => 0010000;     # FIFO

=head1 SYNOPSIS

Intercepts file system calls for specific files so unit testing can take place without any files being altered on disk.

This is useful for L<small tests|https://en.wikipedia.org/wiki/Google_Test#Small_Tests_(Unit_Tests)> where file interaction is discouraged.

A strict mode is even provided which can throw a die when files are accessed during your tests!

    # Loaded before Test::MockFile so uses the core perl functions without any hooks.
    use Module::I::Dont::Want::To::Alter;

    # strict mode
    use Test::MockFile qw< strict >;

    # Be sure to assign the output of mocks, they disappear when they go out of scope
    my $mock_file = Test::MockFile->file("/foo/bar", "contents\ngo\nhere");
    open my $fh, '<', '/foo/bar' or die; # Does not actually open the file on disk
    say 'ok' if -e $fh;
    close $fh;
    say 'ok' if -f '/foo/bar';
    say '/foo/bar is THIS BIG: ' . -s '/foo/bar';

    my $missing_mocked_file = Test::MockFile->file('/foo/baz'); # File starts out missing
    my $opened              = open my $baz_fh, '<', '/foo/baz'; # File reports as missing so fails
    say 'ok' if !-e '/foo/baz';

    open $baz_fh, '>', '/foo/baz' or die; # open for writing
    print {$baz_fh} "replace contents\n";

    open $baz_fh, '>>', '/foo/baz' or die; # open for append.
    print {$baz_fh} "second line";
    close $baz_fh;

    say $baz->contents;

    # Unmock your file.
    undef $missing_mocked_file;

    # The file check will now happen on file system now the file is no longer mocked.
    say 'ok' if !-e '/foo/baz';

    my $quux    = Test::MockFile->file('/foo/bar/quux.txt');
    my @matches = </foo/bar/*.txt>;       # ( 'quux.txt' )
    my @matches = glob('/foo/bar/*.txt'); # same as above

=head1 IMPORT

If the module is loaded in strict mode, any file checks, open, sysopen, opendir, stat, or lstat will throw a die.

For example:

    use Test::MockFile qw< strict >;

    # This will not die.
    my $file    = Test::MockFile->file("/bar", "...");
    my $symlink = Test::MockFile->symlink("/foo", "/bar");
    -l '/foo' or print "ok\n";
    open my $fh, '>', '/foo';

    # All of these will die
    open my $fh, '>', '/unmocked/file'; # Dies
    sysopen my $fh, '/other/file', O_RDONLY;
    opendir my $fh, '/dir';
    -e '/file';
    -l '/file';

Relative paths are not supported:

    use Test::MockFile;

    # Checking relative vs absolute paths
    $file = Test::MockFile->file( '/foo/../bar', '...' ); # not ok - relative path
    $file = Test::MockFile->file( '/bar',        '...' ); # ok     - absolute path
    $file = Test::MockFile->file( 'bar', '...' );         # ok     - current dir

And if you have multiple forward slashes, it will confess as well:

    use Test::MockFile;
    $file = Test::MockFile->file( '//bar', '...' );

=cut

our %authorized_strict_mode_packages;

BEGIN {
    %authorized_strict_mode_packages = (
        'DynaLoader' => 1,
        'lib'        => 1,
    );
}

# Perl understands barewords are filehandles during compilation and
# parsing. If we override the functions, Perl will not show these as
# filehandles, but as strings
# We can try to convert it to the typeglob in the right namespace
sub _upgrade_barewords {
    my @args   = @_;
    my $caller = caller(1);

    # Add bareword information to the args
    # Default: no
    unshift @args, 0;

    # Ignore handle objects
    ref $args[1]
      and return @args;

    # Ignore variables
    # Barewords are provided as strings, which means they're read-only
    # (Of course, readonly scalars here will fool us...)
    Internals::SvREADONLY( $_[0] )
      or return @args;

    # Upgrade the handle
    my $handle;
    {
        no strict 'refs';
        $handle = Symbol::qualify_to_ref( $args[1], caller(1) );
    }

    # Check that the upgrading worked
    ref $handle eq 'GLOB'
      or return @args;

    # Set to bareword
    $args[0] = 1;

    # Override original handle variable/string
    $args[1] = $handle;

    return @args;
}

sub _strict_mode_violation {
    my ( $command, $at_under_ref ) = @_;

    my $file_arg =
        $command eq 'open'    ? 2
      : $command eq 'sysopen' ? 1
      : $command eq 'opendir' ? 1
      : $command eq 'stat'    ? 0
      : $command eq 'lstat'   ? 0
      : $command eq 'chown'   ? 2
      : $command eq 'chmod'   ? 2
      :                         confess("Unknown strict mode violation for $command");

    my @stack;
    foreach my $stack_level ( 1 .. 100 ) {
        @stack = caller($stack_level);
        last if !scalar @stack;
        last if !defined $stack[0];                       # We don't know when this would ever happen.
        next if ( $stack[0] eq __PACKAGE__ );
        next if ( $stack[0] eq 'Overload::FileCheck' );

        # We found a package that isn't one of ours. Is it allowed to access files?
        # If so we're not going to die.
        return if $authorized_strict_mode_packages{ $stack[0] };

        #
        last;
    }

    if ( $command eq 'open' and scalar @$at_under_ref != 3 ) {
        $file_arg = 1 if scalar @$at_under_ref == 2;
    }

    my $filename = scalar @$at_under_ref <= $file_arg ? '<not specified>' : $at_under_ref->[$file_arg];

    # Ignore stats on STDIN, STDOUT, STDERR
    return if $filename =~ m/^\*?(?:main::)?[<*&+>]*STD(?:OUT|IN|ERR)$/;

    confess("Use of $command to access unmocked file or directory '$filename' in strict mode at $stack[1] line $stack[2]");
}

sub import {
    my ( $class, @args ) = @_;

    if ( grep { $_ =~ m/strict/i } @args ) {
        add_file_access_hook( \&_strict_mode_violation );
    }
}

=head1 SUBROUTINES/METHODS

=head2 file

Args: ($file, $contents, $stats)

This will make cause $file to be mocked in all file checks, opens, etc.

C<undef> contents means that the file should act like it's not there. You can
only set the stats if you provide content.

If you give file content, the directory inside it will be mocked as well.

    my $f = Test::MockFile->file( '/foo/bar' );
    -d '/foo' # not ok

    my $f = Test::MockFile->file( '/foo/bar', 'some content' );
    -d '/foo' # ok

See L<Mock Stats> for what goes into the stats hashref.

=cut

sub file {
    my ( $class, $file, $contents, @stats ) = @_;

    ( defined $file && length $file ) or confess("No file provided to instantiate $class");
    _get_file_object($file) and confess("It looks like $file is already being mocked. We don't support double mocking yet.");

    _validate_path($file);

    if ( @stats > 1 ) {
        confess(
            sprintf 'Unkownn arguments (%s) passed to file() as stats',
            join ', ', @stats
        );
    }

    !defined $contents && @stats
      and confess("You cannot set stats for non-existent file '$file'");

    my %stats;
    if (@stats) {
        ref $stats[0] eq 'HASH'
          or confess('->file( FILE_NAME, FILE_CONTENT, { STAT_INFORMATION } )');

        %stats = %{ $stats[0] };
    }

    my $perms = S_IFPERMS & ( defined $stats{'mode'} ? int( $stats{'mode'} ) : 0666 );
    $stats{'mode'} = ( $perms ^ umask ) | S_IFREG;

    # Check if directory for this file is an object we're mocking
    # If so, mark it now as having content
    # which is this file or - if this file is undef, . and ..
    ( my $dirname = $file ) =~ s{ / [^/]+ $ }{}xms;
    if ( defined $contents && $files_being_mocked{$dirname} ) {
        $files_being_mocked{$dirname}{'has_content'} = 1;
    }

    return $class->new(
        {
            'path'     => $file,
            'contents' => $contents,
            %stats
        }
    );
}

=head2 file_from_disk

Args: C<($file_to_mock, $file_on_disk, $stats)>

This will make cause C<$file> to be mocked in all file checks, opens, etc.

If C<file_on_disk> isn't present, then this will die.

See L<Mock Stats> for what goes into the stats hashref.

=cut

sub file_from_disk {
    my ( $class, $file, $file_on_disk, @stats ) = @_;

    my $fh;
    local $!;
    if ( !CORE::open( $fh, '<', $file_on_disk ) ) {
        $file_on_disk //= '<no file specified>';
        confess("Sorry, I cannot read from $file_on_disk to mock $file. It doesn't appear to be present ($!)");
    }

    local $/;
    my $contents = <$fh>;    # Slurp!
    close $fh;

    return __PACKAGE__->file( $file, $contents, @stats );
}

=head2 symlink

Args: ($readlink, $file )

This will cause $file to be mocked in all file checks, opens, etc.

C<$readlink> indicates what "fake" file it points to. If the file C<$readlink> points to is not mocked, it will act like a broken link, regardless of what's on disk.

If C<$readlink> is undef, then the symlink is mocked but not present.(lstat $file is empty.)

Stats are not able to be specified on instantiation but can in theory be altered after the object is created. People don't normally mess with the permissions on a symlink.

=cut

sub symlink {
    my ( $class, $readlink, $file ) = @_;

    ( defined $file && length $file )          or confess("No file provided to instantiate $class");
    ( !defined $readlink || length $readlink ) or confess("No file provided for $file to point to in $class");

    _get_file_object($file) and confess("It looks like $file is already being mocked. We don't support double mocking yet.");

    return $class->new(
        {
            'path'     => $file,
            'contents' => undef,
            'readlink' => $readlink,
            'mode'     => 07777 | S_IFLNK,
        }
    );
}

sub _validate_path {
    my $path = shift;

    # Multiple forward slashes
    if ( $path =~ m[/{2,}] ) {
        confess('Repeated forward slashes in path');
    }

    # Reject the following:
    # ./ ../ /. /.. /./ /../
    if ( $path =~ m{ ( ^ | / ) \.{1,2} ( / | $ ) }xms ) {
        confess('Relative paths are not supported');
    }
}

=head2 dir

Args: ($dir)

This will cause $dir to be mocked in all file checks, and C<opendir> interactions.

The directory name is normalized so any trailing slash is removed.

    $dir = Test::MockFile->dir( 'mydir/', ... ); # ok
    $dir->path();                                # mydir

If there were previously mocked files (within the same scope), the directory will
exist. Otherwise, the directory will be nonexistent.

    my $dir = Test::MockFile->dir('/etc');
    -d $dir;          # not ok since directory wasn't created yet
    $dir->contents(); # undef

    # Now we can create an empty directory
    mkdir '/etc';
    $dir_etc->contents(); # . ..

    # Alternatively, we can already create files with ->file()
    $dir_log  = Test::MockFile->dir('/var');
    $file_log = Test::MockFile->file( '/var/log/access_log', $some_content );
    $dir_log->contents(); # . .. access_log

    # If you create a nonexistent file but then give it content, it will create
    # the directory for you
    my $file = Test::MockFile->file('/foo/bar');
    my $dir  = Test::MockFile->dir('/foo');
    -d '/foo'                 # false
    -e '/foo/bar';            # false
    $dir->contents();         # undef

    $file->contents('hello');
    -e '/foo/bar';            # true
    -d '/foo';                # true
    $dir->contents();         # . .. bar

NOTE: Because C<.> and C<..> will always be the first things C<readdir> returns,
These files are automatically inserted at the front of the array. The order of
files is sorted.

If you want to affect the stat information of a directory, you need to use the
available core Perl keywords. (We might introduce a special helper method for it
in the future.)

    $d = Test::MockFile->dir( '/foo', [], { 'mode' => 0755 } );    # dies
    $d = Test::MockFile->dir( '/foo', undef, { 'mode' => 0755 } ); # dies

    $d = Test::MockFile->dir('/foo');
    mkdir $d, 0755;                   # ok

=cut

sub dir {
    my ( $class, $dir_name ) = @_;

    ( defined $dir_name && length $dir_name ) or confess("No directory name provided to instantiate $class");
    _get_file_object($dir_name)
      and confess("It looks like $dir_name is already being mocked. We don't support double mocking yet.");

    _validate_path($dir_name);

    # Cleanup trailing forward slashes
    $dir_name =~ s{[/\\]$}{}xmsg;

    @_ > 2
      and confess("You cannot set stats for nonexistent dir '$dir_name'");

    my $perms = S_IFPERMS & 0777;
    my %stats = ( 'mode' => ( $perms ^ umask ) | S_IFDIR );

    # TODO: Add stat information

    # FIXME: Quick and dirty: provide a helper method?
    my $has_content = grep m{^\Q$dir_name/\E}xms, %files_being_mocked;
    return $class->new(
        {
            'path'        => $dir_name,
            'has_content' => $has_content,
            %stats
        }
    );
}

=head2 Mock Stats

When creating mocked files or directories, we default their stats to:

    my $attrs = Test::MockFile->file( $file, $contents, {
            'dev'       => 0,        # stat[0]
            'inode'     => 0,        # stat[1]
            'mode'      => $mode,    # stat[2]
            'nlink'     => 0,        # stat[3]
            'uid'       => int $>,   # stat[4]
            'gid'       => int $),   # stat[5]
            'rdev'      => 0,        # stat[6]
            'atime'     => $now,     # stat[8]
            'mtime'     => $now,     # stat[9]
            'ctime'     => $now,     # stat[10]
            'blksize'   => 4096,     # stat[11]
            'fileno'    => undef,    # fileno()
    } );

You'll notice that mode, size, and blocks have been left out of this. Mode is set to 666 (for files) or 777 (for directories), xored against the current umask.
Size and blocks are calculated based on the size of 'contents' a.k.a. the fake file.

When you want to override one of the defaults, all you need to do is specify that when you declare the file or directory. The rest will continue to default.

    my $mfile = Test::MockFile->file("/root/abc", "...", {inode => 65, uid => 123, mtime => int((2000-1970) * 365.25 * 24 * 60 * 60 }));

    my $mdir = Test::MockFile->dir("/sbin", "...", { mode => 0700 }));

=head2 new

This class method is called by file/symlink/dir. There is no good reason to call this directly.

=cut

sub new {
    my $class = shift @_;

    my %opts;
    if ( scalar @_ == 1 && ref $_[0] ) {
        %opts = %{ $_[0] };
    }
    elsif ( scalar @_ % 2 ) {
        confess( sprintf( "Unknown args (%d) passed to new", scalar @_ ) );
    }
    else {
        %opts = @_;
    }

    my $path = $opts{'path'} or confess("Mock file created without a path (filename or dirname)!");

    if ( $path !~ m{^/} ) {
        $path = $opts{'path'} = _abs_path_to_file($path);
    }

    my $now = time;

    my $self = bless {
        'dev'         => 0,         # stat[0]
        'inode'       => 0,         # stat[1]
        'mode'        => 0,         # stat[2]
        'nlink'       => 0,         # stat[3]
        'uid'         => int $>,    # stat[4]
        'gid'         => int $),    # stat[5]
        'rdev'        => 0,         # stat[6]
                                    # 'size'     => undef,    # stat[7] -- Method call
        'atime'       => $now,      # stat[8]
        'mtime'       => $now,      # stat[9]
        'ctime'       => $now,      # stat[10]
        'blksize'     => 4096,      # stat[11]
                                    # 'blocks'   => 0,        # stat[12] -- Method call
        'fileno'      => undef,     # fileno()
        'tty'         => 0,         # possibly this is already provided in mode?
        'readlink'    => '',        # what the symlink points to.
        'path'        => undef,
        'contents'    => undef,
        'has_content' => undef,
    }, $class;

    foreach my $key ( keys %opts ) {

        # Ignore Stuff that's not a valid key for this class.
        next unless exists $self->{$key};

        # If it's passed in, we override them.
        $self->{$key} = $opts{$key};
    }

    $self->{'fileno'} //= _unused_fileno();

    $files_being_mocked{$path} = $self;
    Scalar::Util::weaken( $files_being_mocked{$path} );

    return $self;
}

#Overload::FileCheck::mock_stat(\&mock_stat);
sub _mock_stat {
    my ( $type, $file_or_fh ) = @_;

    $type or confess("_mock_stat called without a stat type");

    my $follow_link =
        $type eq 'stat'  ? 1
      : $type eq 'lstat' ? 0
      :                    confess("Unexpected stat type '$type'");

    # Overload::FileCheck should always send 2 args.
    if ( scalar @_ != 2 ) {
        _real_file_access_hook( $type, [$file_or_fh] );
        return FALLBACK_TO_REAL_OP();
    }

    # Overload::FileCheck should always send something and be handling undef on its own??
    if ( !defined $file_or_fh || !length $file_or_fh ) {
        _real_file_access_hook( $type, [$file_or_fh] );
        return FALLBACK_TO_REAL_OP();
    }

    # Find the path, following the symlink if required.
    my $file = _find_file_or_fh( $file_or_fh, $follow_link );

    return [] if $file && $file eq BROKEN_SYMLINK;      # Allow an ELOOP to fall through here.
    return [] if $file && $file eq CIRCULAR_SYMLINK;    # Allow an ELOOP to fall through here.

    if ( !defined $file or !length $file ) {
        _real_file_access_hook( $type, [$file_or_fh] );
        return FALLBACK_TO_REAL_OP();
    }

    my $file_data = _get_file_object($file);
    if ( !$file_data ) {
        _real_file_access_hook( $type, [$file_or_fh] ) unless ref $file_or_fh;
        return FALLBACK_TO_REAL_OP();
    }

    # File is not present so no stats for you!
    return [] if !$file_data->is_link && !defined $file_data->contents();

    # Make sure the file size is correct in the stats before returning its contents.
    return [ $file_data->stat ];
}

sub _get_file_object {
    my ($file_path) = @_;

    my $file = _find_file_or_fh($file_path) or return;

    return $files_being_mocked{$file};
}

# This subroutine finds the absolute path to a file, returning the absolute path of what it ultimately points to.
# If it is a broken link or what was passed in is undef or '', then we return undef.

sub _find_file_or_fh {
    my ( $file_or_fh, $follow_link, $depth ) = @_;

    # Find the file handle or fall back to just using the abs path of $file_or_fh
    my $absolute_path_to_file = _fh_to_file($file_or_fh) // _abs_path_to_file($file_or_fh) // '';

    # Get the pointer to the object.
    my $mock_object = $files_being_mocked{$absolute_path_to_file};

    # If we're following a symlink and the path we came to is a dead end (broken symlink), then return BROKEN_SYMLINK up the stack.
    return BROKEN_SYMLINK if $depth and !$mock_object;

    # If the link we followed isn't a symlink, then return it.
    return $absolute_path_to_file unless $mock_object && $mock_object->is_link;

    # ##############
    # From here on down we're only dealing with symlinks.
    # ##############

    # If we weren't told to follow the symlink then SUCCESS!
    return $absolute_path_to_file unless $follow_link;

    # This is still a symlink keep going. Bump our depth counter.
    $depth++;

    #Protect against circular symlink loops.
    if ( $depth > FOLLOW_LINK_MAX_DEPTH ) {
        $! = ELOOP;
        return CIRCULAR_SYMLINK;
    }

    return _find_file_or_fh( $mock_object->readlink, 1, $depth );
}

# Tries to find $fh as a open file handle in one of the mocked files.

sub _fh_to_file {
    my ($fh) = @_;

    return unless defined $fh && length $fh;

    # See if $fh is a file handle. It might be a path.
    foreach my $path ( sort keys %files_being_mocked ) {
        my $mock_fh = $files_being_mocked{$path}->{'fh'};

        next unless $mock_fh;               # File isn't open.
        next unless "$mock_fh" eq "$fh";    # This mock doesn't have this file handle open.

        return $path;
    }

    return;
}

sub _files_in_dir {
    my $dirname      = shift;
    my @files_in_dir = @files_being_mocked{
        grep m{^\Q$dirname/\E},
        keys %files_being_mocked
    };

    return @files_in_dir;
}

sub _abs_path_to_file {
    my ($path) = shift;

    defined $path or return;
    return $path if $path =~ m{^/};

    return Cwd::getcwd() . "/$path";
}

sub DESTROY {
    my ($self) = @_;
    ref $self or return;

    # This is just a safety. It doesn't make much sense if we get here but
    # $self doesn't have a path. Either way we can't delete it.
    my $path = $self->{'path'};
    defined $path or return;

    # If the object survives into global destruction, the object which is
    # the value of $files_being_mocked{$path} might destroy early.
    # As a result, don't worry about the self == check just delete the key.
    if ( defined $files_being_mocked{$path} ) {
        $self == $files_being_mocked{$path} or confess("Tried to destroy object for $path ($self) but something else is mocking it?");
    }

    delete $files_being_mocked{$path};
}

=head2 contents

Optional Arg: $contents

Retrieves or updates the current contents of the file.

Only retrieves the content of the directory (as an arrayref).  You can set
directory contents with calling the C<file()> method described above.

Symlinks have no contents.

=cut

sub contents {
    my ( $self, $new_contents ) = @_;
    $self or confess;

    $self->is_link
      and confess("checking or setting contents on a symlink is not supported");

    # handle directories
    if ( $self->is_dir() ) {
        $new_contents
          and confess('To change the contents of the dir, you must work on its files');

        $self->{'has_content'}
          or return;

        # TODO: Quick and dirty, but works (maybe provide a ->basename()?)
        # Retrieve the files in this directory and removes prefix
        my $dirname        = $self->path();
        my @existing_files = sort map {
            ( my $basename = $_->path() ) =~ s{^\Q$dirname/\E}{}xms;
            defined $_->{'contents'} ? ($basename) : ();
        } _files_in_dir($dirname);

        return [ '.', '..', @existing_files ];
    }

    # handle files
    if ( $self->is_file() ) {
        if ( defined $new_contents ) {
            ref $new_contents
              and confess('File contents must be a simple string');

            # XXX Why use $_[1] directly?
            $self->{'contents'} = $_[1];
        }

        return $self->{'contents'};
    }

    confess('This seems to be neither a file nor a dir - what is it?');
}

=head2 filename

Deprecated. Same as C<path>.

=cut

sub filename {
    warn 'filename() is deprecated, use path() instead';
    goto &path;
}

=head2 path

The path (filename or dirname) of the file or directory this mock object is
controlling.

=cut

sub path {
    my ($self) = @_;
    $self or confess("path is a method");

    return $self->{'path'};
}

=head2 unlink

Makes the virtual file go away. NOTE: This also works for directories.

=cut

sub unlink {
    my ($self) = @_;
    $self or confess("unlink is a method");

    if ( !$self->exists ) {
        $! = ENOENT;
        return 0;
    }

    if ( $self->is_dir ) {
        if ( $] < 5.019 && ( $^O eq 'darwin' or $^O =~ m/bsd/i ) ) {
            $! = EPERM;
        }
        else {
            $! = EISDIR;
        }
        return 0;
    }

    if ( $self->is_link ) {
        $self->{'readlink'} = undef;
    }
    else {
        $self->{'has_content'} = undef;
        $self->{'contents'}    = undef;
    }
    return 1;
}

=head2 touch

Optional Args: ($epoch_time)

This function acts like the UNIX utility touch. It sets atime, mtime, ctime to $epoch_time.

If no arguments are passed, $epoch_time is set to time(). If the file does not exist, contents are set to an empty string.

=cut

sub touch {
    my ( $self, $now ) = @_;
    $self or confess("touch is a method");
    $now //= time;

    $self->is_file or confess("touch only supports files");

    my $pre_size = $self->size();

    if ( !defined $pre_size ) {
        $self->contents('');
    }

    # TODO: Should this happen any time contents goes from undef to existing? Should we be setting perms?
    # Normally I'd say yes but it might not matter much for a .005 second test.
    $self->mtime($now);
    $self->ctime($now);
    $self->atime($now);

    return 1;
}

=head2 stat

Returns the stat of a mocked file (does not follow symlinks.)

=cut

sub stat {
    my $self = shift;

    return (
        $self->{'dev'},        # stat[0]
        $self->{'inode'},      # stat[1]
        $self->{'mode'},       # stat[2]
        $self->{'nlink'},      # stat[3]
        $self->{'uid'},        # stat[4]
        $self->{'gid'},        # stat[5]
        $self->{'rdev'},       # stat[6]
        $self->size,           # stat[7]
        $self->{'atime'},      # stat[8]
        $self->{'mtime'},      # stat[9]
        $self->{'ctime'},      # stat[10]
        $self->{'blksize'},    # stat[11]
        $self->blocks,         # stat[12]
    );
}

sub _unused_fileno {
    return 900;                # TODO
}

=head2 readlink

Optional Arg: $readlink

Returns the stat of a mocked file (does not follow symlinks.) You can also use this to change what your symlink is pointing to.

=cut

sub readlink {
    my ( $self, $readlink ) = @_;

    $self->is_link or confess("readlink is only supported for symlinks");

    if ( scalar @_ == 2 ) {
        if ( defined $readlink && ref $readlink ) {
            confess("readlink can only be set to simple strings.");
        }

        $self->{'readlink'} = $readlink;
    }

    return $self->{'readlink'};
}

=head2 is_link

returns true/false, depending on whether this object is a symlink.

=cut

sub is_link {
    my ($self) = @_;

    return ( defined $self->{'readlink'} && length $self->{'readlink'} && $self->{'mode'} & S_IFLNK ) ? 1 : 0;
}

=head2 is_dir

returns true/false, depending on whether this object is a directory.

=cut

sub is_dir {
    my ($self) = @_;

    return ( ( $self->{'mode'} & S_IFMT ) == S_IFDIR ) ? 1 : 0;
}

=head2 is_file

returns true/false, depending on whether this object is a regular file.

=cut

sub is_file {
    my ($self) = @_;

    return ( ( $self->{'mode'} & S_IFMT ) == S_IFREG ) ? 1 : 0;
}

=head2 size

returns the size of the file based on its contents.

=cut

sub size {
    my ($self) = @_;

    # Lstat for a symlink returns 1 for its size.
    return 1 if $self->is_link;

    # length undef is 0 not undef in perl 5.10
    if ( $] < 5.012 ) {
        return undef unless $self->exists;
    }

    return length $self->contents;
}

=head2 exists

returns true or false based on if the file exists right now.

=cut

sub exists {
    my ($self) = @_;

    $self->is_link()
      and return defined $self->{'readlink'} ? 1 : 0;

    $self->is_file()
      and return defined $self->{'contents'} ? 1 : 0;

    $self->is_dir()
      and return $self->{'has_content'} ? 1 : 0;

    return 0;
}

=head2 blocks

Calculates the block count of the file based on its size.

=cut

sub blocks {
    my ($self) = @_;

    my $blocks = int( $self->size / abs( $self->{'blksize'} ) + 1 );
    if ( int($blocks) > $blocks ) {
        $blocks = int($blocks) + 1;
    }
    return $blocks;
}

=head2 chmod

Optional Arg: $perms

Allows you to alter the permissions of a file. This only allows you to change the C<07777> bits of the file permissions.
The number passed should be the octal C<0755> form, not the alphabetic C<"755"> form

=cut

sub chmod {
    my ( $self, $mode ) = @_;

    $mode = ( int($mode) & S_IFPERMS ) ^ umask;

    $self->{'mode'} = ( $self->{'mode'} & S_IFMT ) + $mode;

    return $mode;
}

=head2 permissions

Returns the permissions of the file.

=cut

sub permissions {
    my ($self) = @_;

    return int( $self->{'mode'} ) & S_IFPERMS;
}

=head2 mtime

Optional Arg: $new_epoch_time

Returns and optionally sets the mtime of the file if passed as an integer.

=cut

sub mtime {
    my ( $self, $time ) = @_;

    if ( scalar @_ == 2 && defined $time && $time =~ m/^[0-9]+$/ ) {
        $self->{'mtime'} = $time;
    }

    return $self->{'mtime'};
}

=head2 ctime

Optional Arg: $new_epoch_time

Returns and optionally sets the ctime of the file if passed as an integer.

=cut

sub ctime {
    my ( $self, $time ) = @_;

    if ( @_ == 2 && defined $time && $time =~ m/^[0-9]+$/ ) {
        $self->{'ctime'} = $time;
    }

    return $self->{'ctime'};
}

=head2 atime

Optional Arg: $new_epoch_time

Returns and optionally sets the atime of the file if passed as an integer.

=cut

sub atime {
    my ( $self, $time ) = @_;

    if ( @_ == 2 && defined $time && $time =~ m/^[0-9]+$/ ) {
        $self->{'atime'} = $time;
    }

    return $self->{'atime'};
}

=head2 add_file_access_hook

Args: ( $code_ref )

You can use B<add_file_access_hook> to add a code ref that gets called every time a real file (not mocked) operation happens.
We use this for strict mode to die if we detect your program is unexpectedly accessing files. You are welcome to use it for whatever you like.

Whenever the code ref is called, we pass 2 arguments: C<$code-E<gt>($access_type, $at_under_ref)>. Be aware that altering the variables in
C<$at_under_ref> will affect the variables passed to open / sysopen, etc.

One use might be:

    Test::MockFile::add_file_access_hook(sub { my $type = shift; print "$type called at: " . Carp::longmess() } );

=cut

my @file_access_hooks;

sub add_file_access_hook {
    my ($code_ref) = @_;

    ( $code_ref && ref $code_ref eq 'CODE' ) or confess("add_file_access_hook needs to be passed a code reference.");
    push @file_access_hooks, $code_ref;

    return 1;
}

=head2 clear_file_access_hooks

Calling this subroutine will clear everything that was passed to B<add_file_access_hook>

=cut

sub clear_file_access_hooks {
    @file_access_hooks = ();

    return 1;
}

# This code is called whenever an unmocked file is accessed. Any hooks that are setup get called from here.

sub _real_file_access_hook {
    my ( $access_type, $at_under_ref ) = @_;

    foreach my $code (@file_access_hooks) {
        $code->( $access_type, $at_under_ref );
    }

    return 1;
}

=head2 How this mocking is done:

Test::MockFile uses 2 methods to mock file access:

=head3 -X via L<Overload::FileCheck>

It is currently not possible in pure perl to override L<stat|http://perldoc.perl.org/functions/stat.html>, L<lstat|http://perldoc.perl.org/functions/lstat.html> and L<-X operators|http://perldoc.perl.org/functions/-X.html>.
In conjunction with this module, we've developed L<Overload::FileCheck>.

This enables us to intercept calls to stat, lstat and -X operators (like -e, -f, -d, -s, etc.) and pass them to our control. If the file is currently being mocked, we return the stat (or lstat) information on the file to be used to determine the answer to whatever check was made. This even works for things like C<-e _>.
If we do not control the file in question, we return C<FALLBACK_TO_REAL_OP()> which then makes a normal check.

=head3 CORE::GLOBAL:: overrides

Since 5.10, it has been possible to override function calls by defining them. like:

    *CORE::GLOBAL::open = sub(*;$@) {...}

Any code which is loaded B<AFTER> this happens will use the alternate open. This means you can place your C<use Test::MockFile> statement after statements you don't want to be mocked and
there is no risk that the code will ever be altered by Test::MockFile.

We oveload the following statements and then return tied handles to enable the rest of the IO functions to work properly. Only B<open> / B<sysopen> are needed to address file operations.
However B<opendir> file handles were never setup for tie so we have to override all of B<opendir>'s related functions.

=over

=item * open

=item * sysopen

=item * opendir

=item * readdir

=item * telldir

=item * seekdir

=item * rewinddir

=item * closedir

=back

=cut

# goto doesn't work below 5.16
#
# goto messed up refcount between 5.22 and 5.26.
# Broken in 7bdb4ff0943cf93297712faf504cdd425426e57f
# Fixed  in https://rt.perl.org/Public/Bug/Display.html?id=115814
sub _goto_is_available {
    return 0 if $] < 5.015;
    return 1 if $] < 5.021;
    return 1 if $] > 5.027;
    return 0;    # 5.
}

BEGIN {
    my $_handle_glob = sub {
        my $spec = shift;

        # Text::Glob does not understand multiple patterns
        my @patterns = split /\s+/xms, $spec;

        # Text::Glob does not accept directories in globbing
        # But csh (and thus, Perl) does, so we need to add them
        my @mocked_files = grep $files_being_mocked{$_}->exists(), keys %files_being_mocked;
        @mocked_files = map /^(.+)\/[^\/]+$/xms ? ( $_, $1 ) : ($_), @mocked_files;

        # Might as well be consistent
        @mocked_files = sort @mocked_files;

        my @results = map Text::Glob::match_glob( $_, @mocked_files ), @patterns;
        return @results;
    };

    *CORE::GLOBAL::glob = !$^V || $^V lt 5.18.0
      ? sub {
        pop;
        goto &$_handle_glob;
      }
      : sub (_;) { goto &$_handle_glob; };

    *CORE::GLOBAL::open = sub(*;$@) {
        my $likely_bareword;
        my $arg0;
        if ( defined $_[0] ) {

            # We need to remember the first arg to override the typeglob for barewords
            $arg0 = $_[0];
            ( $likely_bareword, @_ ) = _upgrade_barewords(@_);
        }

        # We're not supporting 2 arg or 1 arg opens yet.
        # open(my $fh, ">filehere"); # Just don't do this. It's bad.
        if ( scalar @_ != 3 ) {
            _real_file_access_hook( "open", \@_ );
            goto \&CORE::open if _goto_is_available();
            if ( @_ == 1 ) {
                return CORE::open( $_[0] );
            }
            elsif ( @_ == 2 ) {
                return CORE::open( $_[0], $_[1] );
            }
            elsif ( @_ >= 3 ) {
                return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
            }
        }

        # Allows for scalar file handles.
        if ( ref $_[2] && ref $_[2] eq 'SCALAR' ) {
            goto \&CORE::open if _goto_is_available();
            return CORE::open( $_[0], $_[1], $_[2] );
        }

        my $abs_path = _find_file_or_fh( $_[2], 1 );    # Follow the link.
        confess() if !$abs_path;
        confess() if $abs_path eq BROKEN_SYMLINK;
        my $mock_file = _get_file_object($abs_path);

        my $mode = $_[1];

        # For now we're going to just strip off the binmode and hope for the best.
        $mode =~ s/(:.+$)//;
        my $encoding_mode = $1;

        # TODO: We don't yet support |- or -|
        # TODO: We don't yet support modes outside of > < >> +< +> +>>
        # We just pass through to open if we're not mocking the file right now.
        if (   ( $mode eq '|-' || $mode eq '-|' )
            or !grep { $_ eq $mode } qw/> < >> +< +> +>>/
            or !defined $mock_file ) {
            _real_file_access_hook( "open", \@_ );
            goto \&CORE::open if _goto_is_available();
            if ( @_ == 1 ) {
                return CORE::open( $_[0] );
            }
            elsif ( @_ == 2 ) {
                return CORE::open( $_[0], $_[1] );
            }
            elsif ( @_ >= 3 ) {
                return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
            }
        }

        # At this point we're mocking the file. Let's do it!

        # If contents is undef, we act like the file isn't there.
        if ( !defined $mock_file->contents() && grep { $mode eq $_ } qw/< +</ ) {
            $! = ENOENT;
            return;
        }

        my $rw = '';
        $rw .= 'r' if grep { $_ eq $mode } qw/+< +> +>> </;
        $rw .= 'w' if grep { $_ eq $mode } qw/+< +> +>> > >>/;

        my $filefh = IO::File->new;
        tie *{$filefh}, 'Test::MockFile::FileHandle', $abs_path, $rw;

        if ($likely_bareword) {
            my $caller = caller();
            no strict;
            *{"${caller}::$arg0"} = $filefh;
            @_ = ( $filefh, $_[1] ? @_[ 1 .. $#_ ] : () );
        }
        else {
            $_[0] = $filefh;
        }

        # This is how we tell if the file is open by something.

        $mock_file->{'fh'} = $_[0];
        Scalar::Util::weaken( $mock_file->{'fh'} ) if ref $_[0];    # Will this make it go out of scope?

        # Fix tell based on open options.
        if ( $mode eq '>>' or $mode eq '+>>' ) {
            $mock_file->{'contents'} //= '';
            seek $_[0], length( $mock_file->{'contents'} ), 0;
        }
        elsif ( $mode eq '>' or $mode eq '+>' ) {
            $mock_file->{'contents'} = '';
        }

        return 1;
    };

    # sysopen FILEHANDLE, FILENAME, MODE, MASK
    # sysopen FILEHANDLE, FILENAME, MODE

    # We curently support:
    # 1 - O_RDONLY - Read only.
    # 2 - O_WRONLY - Write only.
    # 3 - O_RDWR - Read and write.
    # 6 - O_APPEND - Append to the file.
    # 7 - O_TRUNC - Truncate the file.
    # 5 - O_EXCL - Fail if the file already exists.
    # 4 - O_CREAT - Create the file if it doesn't exist.
    # 8 - O_NOFOLLOW - Fail if the last path component is a symbolic link.

    *CORE::GLOBAL::sysopen = sub(*$$;$) {
        my $mock_file = _get_file_object( $_[1] );

        if ( !$mock_file ) {
            _real_file_access_hook( "sysopen", \@_ );
            goto \&CORE::sysopen if _goto_is_available();
            return CORE::sysopen( $_[0], $_[1], @_[ 2 .. $#_ ] );
        }

        my $sysopen_mode = $_[2];

        # Not supported by my linux vendor: O_EXLOCK | O_SHLOCK
        if ( ( $sysopen_mode & SUPPORTED_SYSOPEN_MODES ) != $sysopen_mode ) {
            confess( sprintf( "Sorry, can't open %s with 0x%x permissions. Some of your permissions are not yet supported by %s", $_[1], $sysopen_mode, __PACKAGE__ ) );
        }

        # O_NOFOLLOW
        if ( ( $sysopen_mode & O_NOFOLLOW ) == O_NOFOLLOW && $mock_file->is_link ) {
            $! = 40;
            return undef;
        }

        # O_EXCL
        if ( $sysopen_mode & O_EXCL && $sysopen_mode & O_CREAT && defined $mock_file->{'contents'} ) {
            $! = EEXIST;
            return;
        }

        # O_CREAT
        if ( $sysopen_mode & O_CREAT && !defined $mock_file->{'contents'} ) {
            $mock_file->{'contents'} = '';
        }

        # O_TRUNC
        if ( $sysopen_mode & O_TRUNC && defined $mock_file->{'contents'} ) {
            $mock_file->{'contents'} = '';

        }

        my $rd_wr_mode = $sysopen_mode & 3;
        my $rw =
            $rd_wr_mode == O_RDONLY ? 'r'
          : $rd_wr_mode == O_WRONLY ? 'w'
          : $rd_wr_mode == O_RDWR   ? 'rw'
          :                           confess("Unexpected sysopen read/write mode ($rd_wr_mode)");    # O_WRONLY| O_RDWR mode makes no sense and we should die.

        # If contents is undef, we act like the file isn't there.
        if ( !defined $mock_file->{'contents'} && $rd_wr_mode == O_RDONLY ) {
            $! = ENOENT;
            return;
        }

        my $abs_path = $mock_file->{'path'};

        $_[0] = IO::File->new;
        tie *{ $_[0] }, 'Test::MockFile::FileHandle', $abs_path, $rw;

        # This is how we tell if the file is open by something.
        $files_being_mocked{$abs_path}->{'fh'} = $_[0];
        Scalar::Util::weaken( $files_being_mocked{$abs_path}->{'fh'} ) if ref $_[0];    # Will this make it go out of scope?

        # O_TRUNC
        if ( $sysopen_mode & O_TRUNC ) {
            $mock_file->{'contents'} = '';
        }

        # O_APPEND
        if ( $sysopen_mode & O_APPEND ) {
            seek $_[0], length $mock_file->{'contents'}, 0;
        }

        return 1;
    };

    *CORE::GLOBAL::opendir = sub(*$) {

        # Upgrade but ignore bareword indicator
        ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0];

        my $mock_dir = _get_file_object( $_[1] );

        # 1 arg Opendir doesn't work??
        if ( scalar @_ != 2 or !defined $_[1] ) {
            _real_file_access_hook( "opendir", \@_ );

            goto \&CORE::opendir if _goto_is_available();

            return CORE::opendir( $_[0], @_[ 1 .. $#_ ] );
        }

        if ( !$mock_dir ) {
            _real_file_access_hook( "opendir", \@_ );
            goto \&CORE::opendir if _goto_is_available();
            return CORE::opendir( $_[0], $_[1] );
        }

        if ( !defined $mock_dir->contents ) {
            $! = ENOENT;
            return undef;
        }

        if ( !( $mock_dir->{'mode'} & S_IFDIR ) ) {
            $! = ENOTDIR;
            return undef;
        }

        if ( !defined $_[0] ) {
            $_[0] = Symbol::gensym;
        }
        elsif ( ref $_[0] ) {
            no strict 'refs';
            *{ $_[0] } = Symbol::geniosym;
        }

        # This is how we tell if the file is open by something.
        my $abs_path = $mock_dir->{'path'};
        $mock_dir->{'obj'} = Test::MockFile::DirHandle->new( $abs_path, $mock_dir->contents() );
        $mock_dir->{'fh'}  = "$_[0]";

        return 1;

    };

    *CORE::GLOBAL::readdir = sub(*) {

        # Upgrade but ignore bareword indicator
        ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0];

        my $mocked_dir = _get_file_object( $_[0] );

        if ( !$mocked_dir ) {
            goto \&CORE::readdir if _goto_is_available();
            return CORE::readdir( $_[0] );
        }

        my $obj = $mocked_dir->{'obj'};
        if ( !$obj ) {
            confess("Read on a closed handle");
        }

        if ( !defined $obj->{'files_in_readdir'} ) {
            confess("Did a readdir on an empty dir. This shouldn't have been able to have been opened!");
        }

        if ( !defined $obj->{'tell'} ) {
            confess("readdir called on a closed dirhandle");
        }

        # At EOF for the dir handle.
        return undef if $obj->{'tell'} > $#{ $obj->{'files_in_readdir'} };

        if (wantarray) {
            my @return;
            foreach my $pos ( $obj->{'tell'} .. $#{ $obj->{'files_in_readdir'} } ) {
                push @return, $obj->{'files_in_readdir'}->[$pos];
            }
            $obj->{'tell'} = $#{ $obj->{'files_in_readdir'} } + 1;
            return @return;
        }

        return $obj->{'files_in_readdir'}->[ $obj->{'tell'}++ ];
    };

    *CORE::GLOBAL::telldir = sub(*) {

        # Upgrade but ignore bareword indicator
        ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0];

        my ($fh) = @_;
        my $mocked_dir = _get_file_object($fh);

        if ( !$mocked_dir || !$mocked_dir->{'obj'} ) {
            goto \&CORE::telldir if _goto_is_available();
            return CORE::telldir($fh);
        }

        my $obj = $mocked_dir->{'obj'};

        if ( !defined $obj->{'files_in_readdir'} ) {
            confess("Did a telldir on an empty dir. This shouldn't have been able to have been opened!");
        }

        if ( !defined $obj->{'tell'} ) {
            confess("telldir called on a closed dirhandle");
        }

        return $obj->{'tell'};
    };

    *CORE::GLOBAL::rewinddir = sub(*) {

        # Upgrade but ignore bareword indicator
        ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0];

        my ($fh) = @_;
        my $mocked_dir = _get_file_object($fh);

        if ( !$mocked_dir || !$mocked_dir->{'obj'} ) {
            goto \&CORE::rewinddir if _goto_is_available();
            return CORE::rewinddir( $_[0] );
        }

        my $obj = $mocked_dir->{'obj'};

        if ( !defined $obj->{'files_in_readdir'} ) {
            confess("Did a rewinddir on an empty dir. This shouldn't have been able to have been opened!");
        }

        if ( !defined $obj->{'tell'} ) {
            confess("rewinddir called on a closed dirhandle");
        }

        $obj->{'tell'} = 0;
        return 1;
    };

    *CORE::GLOBAL::seekdir = sub(*$) {

        # Upgrade but ignore bareword indicator
        ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0];

        my ( $fh, $goto ) = @_;
        my $mocked_dir = _get_file_object($fh);

        if ( !$mocked_dir || !$mocked_dir->{'obj'} ) {
            goto \&CORE::seekdir if _goto_is_available();
            return CORE::seekdir( $fh, $goto );
        }

        my $obj = $mocked_dir->{'obj'};

        if ( !defined $obj->{'files_in_readdir'} ) {
            confess("Did a seekdir on an empty dir. This shouldn't have been able to have been opened!");
        }

        if ( !defined $obj->{'tell'} ) {
            confess("seekdir called on a closed dirhandle");
        }

        return $obj->{'tell'} = $goto;
    };

    *CORE::GLOBAL::closedir = sub(*) {

        # Upgrade but ignore bareword indicator
        ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0];

        my ($fh) = @_;
        my $mocked_dir = _get_file_object($fh);

        if ( !$mocked_dir || !$mocked_dir->{'obj'} ) {
            goto \&CORE::closedir if _goto_is_available();
            return CORE::closedir($fh);
        }

        delete $mocked_dir->{'obj'};
        delete $mocked_dir->{'fh'};

        return 1;
    };

    *CORE::GLOBAL::unlink = sub(@) {
        my @files_to_unlink = @_;
        my $files_deleted   = 0;

        foreach my $file (@files_to_unlink) {
            my $mock = _get_file_object($file);

            if ( !$mock ) {
                _real_file_access_hook( "unlink", [$file] );
                $files_deleted += CORE::unlink($file);
            }
            else {
                $files_deleted += $mock->unlink;
            }
        }

        return $files_deleted;

    };

    *CORE::GLOBAL::readlink = sub(_) {
        my ($file) = @_;

        if ( !defined $file ) {
            warn 'Use of uninitialized value in readlink';
            $! = ENOENT;
            return;
        }

        my $mock_object = _get_file_object($file);
        if ( !$mock_object ) {
            goto \&CORE::readlink if _goto_is_available();
            return CORE::readlink($file);
        }

        if ( !$mock_object->is_link ) {
            $! = EINVAL;
            return;
        }
        return $mock_object->readlink;
    };

    # $file is always passed because of the prototype.
    *CORE::GLOBAL::mkdir = sub(_;$) {
        my ( $file, $perms ) = @_;

        $perms = ( $perms // 0777 ) & S_IFPERMS;

        if ( !defined $file ) {

            # mkdir warns if $file is undef
            carp("Use of uninitialized value in mkdir");
            $! = ENOENT;
            return 0;
        }

        my $mock = _get_file_object($file);

        if ( !$mock ) {
            goto \&CORE::mkdir if _goto_is_available();

            return CORE::mkdir(@_);
        }

        # File or directory, this exists and should fail
        if ( $mock->exists ) {
            $! = EEXIST;
            return 0;
        }

        # If the mock was a symlink or a file, we've just made it a dir.
        $mock->{'mode'} = ( $perms ^ umask ) | S_IFDIR;
        delete $mock->{'readlink'};

        # This should now start returning content
        $mock->{'has_content'} = 1;

        return 1;
    };

    # $file is always passed because of the prototype.
    *CORE::GLOBAL::rmdir = sub(_) {
        my ($file) = @_;

        # technically this is a minor variation from core. We don't seem to be able to
        # detect when they didn't pass an arg like core can.
        # Core sometimes warns: 'Use of uninitialized value $_ in rmdir'
        if ( !defined $file ) {
            carp('Use of uninitialized value in rmdir');
            return 0;
        }

        my $mock = _get_file_object($file);

        if ( !$mock ) {
            goto \&CORE::rmdir if _goto_is_available();
            return CORE::rmdir($file);
        }

        # Because we've mocked this to be a file and it doesn't exist we are going to die here.
        # The tester needs to fix this presumably.
        if ( $mock->exists ) {
            if ( $mock->is_file ) {
                $! = ENOTDIR;
                return 0;
            }

            if ( $mock->is_link ) {
                $! = ENOTDIR;
                return 0;
            }
        }

        if ( !$mock->exists ) {
            $! = ENOENT;
            return 0;
        }

        if ( _files_in_dir($file) ) {
            $! = 39;
            return 0;
        }

        $mock->{'has_content'} = undef;
        return 1;
    };

    *CORE::GLOBAL::chown = sub(@) {
        my ( $uid, $gid, @files ) = @_;

        $^O eq 'MSWin32'
          and return 0;    # does nothing on Windows

        # Not an error, report we changed zero files
        @files
          or return 0;

        my %mocked_files   = map +( $_ => _get_file_object($_) ), @files;
        my @unmocked_files = grep !$mocked_files{$_}, @files;
        my @mocked_files   = map ref $_ ? $_->{'path'} : (), values %mocked_files;

        # The idea is that if some are mocked and some are not,
        # it's probably a mistake
        if ( @mocked_files && @mocked_files != @files ) {
            confess(
                sprintf 'You called chown() on a mix of mocked (%s) and unmocked files (%s) ' . ' - this is very likely a bug on your side',
                ( join ', ', @mocked_files ),
                ( join ', ', @unmocked_files ),
            );
        }

        # -1 means "keep as is"
        $uid == -1 and $uid = $>;
        $gid == -1 and $gid = $);

        my $is_root     = $> == 0 || $) =~ /( ^ | \s ) 0 ( \s | $)/xms;
        my $is_in_group = grep /(^ | \s ) \Q$gid\E ( \s | $ )/xms, $);

        # TODO: Perl has an odd behavior that -1, -1 on a file that isn't owned by you still works
        # Not sure how to write a test for it though...

        my $set_error;
        my $num_changed = 0;
        foreach my $file (@files) {
            my $mock = $mocked_files{$file};

            # If this file is not mocked, none of the files are
            # which means we can send them all and let the CORE function handle it
            if ( !$mock ) {
                _real_file_access_hook( 'chown', \@_ );
                goto \&CORE::chown if _goto_is_available();
                return CORE::chown(@files);
            }

            # Even if you're root, nonexistent file is nonexistent
            if ( !$mock->exists() ) {

                # Only set the error once
                $set_error
                  or $! = ENOENT;

                next;
            }

            # root can do anything, but you can't
            # and if we are here, no point in keep trying
            if ( !$is_root ) {
                if ( $> != $uid || !$is_in_group ) {
                    $set_error
                      or $! = EPERM;

                    last;
                }
            }

            $mock->{'uid'} = $uid;
            $mock->{'gid'} = $gid;

            $num_changed++;
        }

        return $num_changed;
    };

    *CORE::GLOBAL::chmod = sub(@) {
        my ( $mode, @files ) = @_;

        # Not an error, report we changed zero files
        @files
          or return 0;

        # Grab numbers - nothing means "0" (which is the behavior of CORE::chmod)
        # (This will issue a warning, that's also the expected behavior)
        {
            no warnings;
            $mode =~ /^[0-9]+/xms
              or warn "Argument \"$mode\" isn't numeric in chmod";
            $mode = int $mode;
        }

        my %mocked_files   = map +( $_ => _get_file_object($_) ), @files;
        my @unmocked_files = grep !$mocked_files{$_}, @files;
        my @mocked_files   = map ref $_ ? $_->{'path'} : (), values %mocked_files;

        # The idea is that if some are mocked and some are not,
        # it's probably a mistake
        if ( @mocked_files && @mocked_files != @files ) {
            confess(
                sprintf 'You called chmod() on a mix of mocked (%s) and unmocked files (%s) ' . ' - this is very likely a bug on your side',
                ( join ', ', @mocked_files ),
                ( join ', ', @unmocked_files ),
            );
        }

        my $num_changed = 0;
        foreach my $file (@files) {
            my $mock = $mocked_files{$file};

            if ( !$mock ) {
                _real_file_access_hook( 'chmod', \@_ );
                goto \&CORE::chmod if _goto_is_available();
                return CORE::chmod(@files);
            }

            # chmod is less specific in such errors
            # chmod $mode, '/foo/' still yields ENOENT
            if ( !$mock->exists() ) {
                $! = ENOENT;
                next;
            }

            $mock->{'mode'} = ( $mock->{'mode'} & S_IFMT ) + $mode;

            $num_changed++;
        }

        return $num_changed;
    };
}

=head1 BAREWORD FILEHANDLE FAILURES

There is a particular type of bareword filehandle failures that cannot be
fixed.

These errors occur because there's compile-time code that uses bareword
filehandles in a function call that cannot be expressed by this module's
prototypes for core functions.

The only solution to these is loading `Test::MockFile` after the other code:

This will fail:

    # This will fail because Test2::V0 will eventually load Term::Table::Util
    # which calls open() with a bareword filehandle that is misparsed by this module's
    # opendir prototypes
    use Test::MockFile ();
    use Test2::V0;

This will succeed:

    # This will succeed because open() will be parsed by perl
    # and only then we override those functions
    use Test2::V0;
    use Test::MockFile ();

(Using strict-mode will not fix it, even though you should use it.)

=head1 AUTHOR

Todd Rinaldo, C<< <toddr at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/CpanelInc/Test-MockFile>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::MockFile


You can also look for information at:

=over 4

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Test-MockFile>

=item * Search CPAN

L<https://metacpan.org/release/Test-MockFile>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Nicolas R., C<< <atoomic at cpan.org> >> for help with L<Overload::FileCheck>. This module could not have been completed without it.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 cPanel L.L.C.

All rights reserved.

L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut

1;    # End of Test::MockFile
