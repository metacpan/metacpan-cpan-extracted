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

# we're going to use carp but the errors should come from outside of our package.
use Carp ();
$Carp::Internal{__PACKAGE__}++;
$Carp::Internal{'Overload::FileCheck'}++;

use Cwd                        ();
use IO::File                   ();
use Test::MockFile::FileHandle ();
use Test::MockFile::DirHandle  ();
use Scalar::Util               ();
use Overload::FileCheck '-from-stat' => \&_mock_stat, q{:check};

use Errno qw/ENOENT ELOOP EEXIST/;

use constant FOLLOW_LINK_MAX_DEPTH => 10;

=head1 NAME

Test::MockFile - Lets tests validate code which interacts with files without the file system ever being touched. 

=head1 VERSION

Version 0.009

=cut

our $VERSION = '0.009';

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

    # Loaded before Test::MockModule so uses the core perl functions without any hooks.
    use Module::I::Dont::Want::To::Alter;

    use Test::MockFile;

    my $mock_file = Test::MockFile->file("/foo/bar", "contents\ngo\nhere");
    open(my $fh, "<", "/foo/bar") or die; # Does not actually open the file on disk.
    say "ok" if -e $fh;
    close $fh;
    say "ok" if (-f "/foo/bar");
    say "/foo/bar is THIS BIG: " . -s "/foo/bar"

    my $missing_mocked_file = Test::MockFile->file("/foo/baz"); # File starts out missing.
    my $opened = open(my $baz_fh, "<", "/foo/baz"); # File reports as missing so fails.
    say "ok" if !-e "/foo/baz";
    
    open($baz_fh, ">", "/foo/baz") or die; # open for writing
    print <$baz_fh> "replace contents\n";
    
    open($baz_fh, ">>", "/foo/baz") or die; # open for append.
    print <$baz_fh> "second line";
    close $baz_fh;
    
    say $baz->contents;
    
    # Unmock your file.
    undef $missing_mocked_file;
    
    # The file check will now happen on file system now the file is no longer mocked.
    say "ok" if !-e "/foo/baz";

=head1 IMPORT

If the module is loaded in strict mode, any file checks, open, sysopen, opendir, stat, or lstat will throw a die.

For example:

    use Test::MockFile qw/strict/;

    # This will not die.
    Test::MockFile->file("/bar", "...");
    Test::MockFile->link("/foo", "/bar");
    -l "/foo" or print "ok\n";
    open(my $fh, ">", "/foo");
    
    # All of these will die
    open(my $fh, ">", "/unmocked/file"); # Dies
    sysopen(my $fh, "/other/file", O_RDONLY);
    opendir(my $fh, "/dir");
    -e "/file";
    -l "/file"

=cut

sub _strict_mode_violation {
    my ( $command, $at_under_ref ) = @_;

    my $file_arg =
        $command eq 'open'    ? 2
      : $command eq 'sysopen' ? 1
      : $command eq 'opendir' ? 1
      : $command eq 'stat'    ? 0
      : $command eq 'lstat'   ? 0
      :                         Carp::croak("Unknown strict mode violation for $command");

    if ( $command eq 'open' and scalar @$at_under_ref != 3 ) {
        $file_arg = 1 if scalar @$at_under_ref == 2;
    }

    my $filename = scalar @$at_under_ref <= $file_arg ? '<not specified>' : $at_under_ref->[$file_arg];

    Carp::croak("Use of $command on unmocked file $filename in strict mode");
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

undef contents means that the file should act like it's not there.

See L<Mock Stats> for what goes in this hash ref.

=cut

sub file {
    my ( $class, $file, $contents, @stats ) = @_;

    length $file or die("No file provided to instantiate $class");
    $files_being_mocked{$file} and die("It looks like $file is already being mocked. We don't support double mocking yet.");

    my %stats;
    if ( scalar @stats == 1 ) {
        %stats = %{ $stats[0] };
    }
    elsif ( scalar @stats % 2 ) {
        die sprintf( "Unknown args (%d) passed to file", scalar @_ );
    }
    else {
        %stats = @stats;
    }

    my $perms = S_IFPERMS & ( defined $stats{'mode'} ? int( $stats{'mode'} ) : 0666 );
    $stats{'mode'} = ( $perms ^ umask ) | S_IFREG;

    return $class->new(
        {
            'file_name' => $file,
            'contents'  => $contents,
            %stats
        }
    );
}

=head2 symlink

Args: ($file, $readlink )

This will cause $file to be mocked in all file checks, opens, etc.

$readlink indicates what "fake" file it points to. If the file $readlink points to is not mocked, it will act like a broken link, regardless of what's on disk.

Stats are not able to be specified on instantiation but can in theory be altered after the object is created. People don't normally mess with the permissions on a symlink.

=cut

sub symlink {
    my ( $class, $file, $readlink ) = @_;

    length $file     or die("No file provided to instantiate $class");
    length $readlink or die("No file provided for $file to point to in $class");

    $files_being_mocked{$file} and die("It looks like $file is already being mocked. We don't support double mocking yet.");

    return $class->new(
        {
            'file_name' => $file,
            'contents'  => undef,
            'readlink'  => $readlink,
            'mode'      => 07777 | S_IFLNK,
        }
    );
}

=head2 dir

Args: ($dir, \@contents, $stats)

This will cause $dir to be mocked in all file checks, and opendir interactions.

@contents should be provided in the sort order you expect to see the files from readdir.
NOTE: Because "." and ".." will always be the first things readdir returns, These files are automatically inserted at the front of the array.

See L<Mock Stats> for what goes in this hash ref.

=cut

sub dir {
    my ( $class, $dir_name, $contents, @stats ) = @_;

    length $dir_name or die("No directory name provided to instantiate $class");
    $files_being_mocked{$dir_name} and die("It looks like $dir_name is already being mocked. We don't support double mocking yet.");

    # Because undef means it's a missing dir.
    if ( defined $contents ) {
        ref $contents eq 'ARRAY' or die("directory contents must be an array ref or undef if the directory is to be missing.");

        # Push . and .. on if not listed in the dir.
        if ( !grep { $_ eq '..' } @$contents ) {
            unshift @$contents, '..';
        }
        if ( !grep { $_ eq '.' } @$contents ) {
            unshift @$contents, '.';
        }
    }

    my %stats;
    if ( scalar @stats == 1 ) {
        %stats = %{ $stats[0] };
    }
    elsif ( scalar @stats % 2 ) {
        die sprintf( "Unknown args (%d) passed to file", scalar @_ );
    }
    else {
        %stats = @stats;
    }

    my $perms = S_IFPERMS & ( defined $stats{'mode'} ? int( $stats{'mode'} ) : 0666 );
    $stats{'mode'} = ( $perms ^ umask ) | S_IFDIR;

    return $class->new(
        {
            'file_name' => $dir_name,
            'contents'  => $contents,
            %stats
        }
    );
}

=head2 Mock Stats

When creating mocked files or directories, we default their stats to:

    Test::MockModule->new( $file, $contents, {
            'dev'       => 0,        # stat[0]
            'inode'     => 0,        # stat[1]
            'mode'      => $mode,    # stat[2]
            'nlink'     => 0,        # stat[3]
            'uid'       => 0,        # stat[4]
            'gid'       => 0,        # stat[5]
            'rdev'      => 0,        # stat[6]
            'atime'     => $now,     # stat[8]
            'mtime'     => $now,     # stat[9]
            'ctime'     => $now,     # stat[10]
            'blksize'   => 4096,     # stat[11]
            'fileno'    => undef,    # fileno()
    };
    
You'll notice that mode, size, and blocks have been left out of this. Mode is set to 666 (for files) or 777 (for directories), xored against the current umask.
Size and blocks are calculated based on the size of 'contents' a.k.a. the fake file.

When you want to override one of the defaults, all you need to do is specify that when you declare the file or directory. The rest will continue to default.

    Test::MockModule->file("/root/abc", "...", {inode => 65, uid => 123, mtime => int((2000-1970) * 365.25 * 24 * 60 * 60 }));

    Test::MockModule->dir("/sbin", "...", { mode => 0700 }));

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
        die sprintf( "Unknown args (%d) passed to new", scalar @_ );
    }
    else {
        %opts = @_;
    }

    my $file_name = $opts{'file_name'} or die("Mock file created without a file name!");

    if ( $file_name !~ m{^/} ) {
        $file_name = $opts{'file_name'} = _abs_path_to_file($file_name);
    }

    my $now = time;

    my $self = bless {
        'dev'       => 0,        # stat[0]
        'inode'     => 0,        # stat[1]
        'mode'      => 0,        # stat[2]
        'nlink'     => 0,        # stat[3]
        'uid'       => 0,        # stat[4]
        'gid'       => 0,        # stat[5]
        'rdev'      => 0,        # stat[6]
                                 # 'size'     => undef,    # stat[7] -- Method call
        'atime'     => $now,     # stat[8]
        'mtime'     => $now,     # stat[9]
        'ctime'     => $now,     # stat[10]
        'blksize'   => 4096,     # stat[11]
                                 # 'blocks'   => 0,        # stat[12] -- Method call
        'fileno'    => undef,    # fileno()
        'tty'       => 0,        # possibly this is already provided in mode?
        'readlink'  => '',       # what the symlink points to.
        'file_name' => undef,
        'contents'  => undef,
    }, $class;

    foreach my $key ( keys %opts ) {

        # Ignore Stuff that's not a valid key for this class.
        next unless exists $self->{$key};

        # If it's passed in, we override them.
        $self->{$key} = $opts{$key};
    }

    $self->{'fileno'} //= _unused_fileno();

    $files_being_mocked{$file_name} = $self;
    Scalar::Util::weaken( $files_being_mocked{$file_name} );

    return $self;
}

#Overload::FileCheck::mock_stat(\&mock_stat);
sub _mock_stat {
    my ( $type, $file_or_fh ) = @_;

    $type or die("_mock_stat called without a stat type");

    my $follow_link =
        $type eq 'stat'  ? 1
      : $type eq 'lstat' ? 0
      :                    die("Unexpected stat type '$type'");

    if ( scalar @_ != 2 ) {
        _real_file_access_hook( $type, [$file_or_fh] );
        return FALLBACK_TO_REAL_OP();
    }

    if ( !length $file_or_fh ) {
        _real_file_access_hook( $type, [$file_or_fh] );
        return FALLBACK_TO_REAL_OP();
    }

    my $file = _find_file_or_fh( $file_or_fh, $follow_link );
    return $file if ref $file eq 'ARRAY';    # Allow an ELOOP to fall through here.

    if ( !length $file ) {
        _real_file_access_hook( $type, [$file_or_fh] );
        return FALLBACK_TO_REAL_OP();
    }

    my $file_data = $files_being_mocked{$file};
    if ( !$file_data ) {
        _real_file_access_hook( $type, [$file_or_fh] );
        return FALLBACK_TO_REAL_OP();
    }

    # File is not present so no stats for you!
    return [] if !defined $file_data->{'contents'};

    # Make sure the file size is correct in the stats before returning its contents.
    return [ $file_data->stat ];
}

sub _find_file_or_fh {
    my ( $file_or_fh, $follow_link, $depth, $parent ) = @_;

    my $file        = _fh_to_file($file_or_fh);
    my $mock_object = $files_being_mocked{$file};

    if ( $parent and !$mock_object ) {
        die( sprintf( "Mocked file %s points to unmocked file %s", $parent, $file || '??' ) );
    }

    return $file unless $follow_link && $mock_object && $mock_object->is_link;

    if ( !$mock_object ) {
        return [] if $depth;
        return $file;
    }

    return $file unless $files_being_mocked{$file}->is_link;

    $depth ||= 0;
    $depth++;

    #Protect against circular loops.
    if ( $depth > FOLLOW_LINK_MAX_DEPTH ) {
        $! = ELOOP;
        return [];
    }

    return _find_file_or_fh( $files_being_mocked{$file}->readlink, 1, $depth, $file );
}

sub _fh_to_file {
    my ($fh) = @_;

    # Return if it's a string. Nothing to do here!
    return _abs_path_to_file($fh) unless ref $fh;

    foreach my $file_name ( keys %files_being_mocked ) {
        my $mock_fh = $files_being_mocked{$file_name}->{'fh'};
        next unless $mock_fh;              # File isn't open.
        next unless "$mock_fh" eq "$fh";

        return $file_name;
    }

    return;
}

sub _abs_path_to_file {
    my ($path) = shift;

    defined $path or return;
    return $path if $path =~ m{^/};

    return Cwd::getcwd() . "/$path";
}

sub DESTROY {
    my ($self) = @_;
    $self or return;
    ref $self or return;

    my $file_name = $self->{'file_name'} or return;

    $self == $files_being_mocked{$file_name} or die("Tried to destroy object for $file_name ($self) but something else is mocking it?");
    delete $files_being_mocked{$file_name};
}

=head2 contents

Optional Arg: $contents

Reports or updates the current contents of the file.

To update, pass an array ref of strings for a dir or a string for a file. Symlinks have no contents.

=cut

sub contents {
    my ( $self, $new_contents ) = @_;
    $self or die;

    die("checking or setting contents on a symlink is not supported") if $self->is_link;

    # If 2nd arg was passed.
    if ( scalar @_ == 2 ) {
        if ( defined $new_contents ) {    # undef is legal everywhere.
            if ( $self->is_file && ref $new_contents ) {
                die("File contents should be a simple string");
            }
            elsif ( $self->is_dir && ref $new_contents ne 'ARRAY' ) {
                die("Directory contents should be an array ref of strings corresponding to what you want readdir to return.");
            }
        }
        return $self->{'contents'} = $_[1];
    }

    return $self->{'contents'};
}

=head2 unlink

Makes the virtual file go away by making its contents undef.

=cut

sub unlink {
    my ($self) = @_;
    $self or die("unlink is a method");

    $self->is_file or die("unlink only supports files");

    $self->contents(undef);

    return 1;
}

=head2 touch

Optional Args: ($epoch_time)

This function acts like the UNIX utility touch. It sets atime, mtime, ctime to $epoch_time.

If no arguments are passed, $epoch_time is set to time(). If the file does not exist, contents are set to an empty string.

=cut

sub touch {
    my ( $self, $now ) = @_;
    $self or die("touch is a method");
    $now //= time;

    $self->is_file or die("touch only supports files");

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

    $self->is_link or die("readlink is only supported for symlinks");

    if ( scalar @_ == 2 ) {
        if ( defined $readlink && ref $readlink ) {
            die("readlink can only be set to simple strings.");
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

    return ( length $self->{'readlink'} && $self->{'mode'} & S_IFLNK ) ? 1 : 0;
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

    # length undef is 0 not undef in perl 5.10
    if ( $] < 5.012 ) {
        return undef if !defined $self->contents;
    }

    return length $self->contents;
}

=head2 blocks

Calculates the block count of the file based on its size.

=cut

sub blocks {
    my ($self) = @_;

    my $blocks = $self->size / abs( $self->{'blksize'} || 1 );
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

    $mode = int($mode) | S_IFPERMS;

    $self->{'mode'} = ( $self->{'mode'} | S_IFMT ) + $mode;

    return $mode;
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

    ( $code_ref && ref $code_ref eq 'CODE' ) or die("add_file_access_hook needs to be passed a code reference.");
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

Test::MockModule uses 2 methods to mock file access:

=head3 -X via L<Overload::FileCheck>

It is currently not possible in pure perl to override L<stat|http://perldoc.perl.org/functions/stat.html>, L<lstat|http://perldoc.perl.org/functions/lstat.html> and L<-X operators|http://perldoc.perl.org/functions/-X.html>.
In conjunction with this module, we've developed L<Overload::FileCheck>.

This enables us to intercept calls to stat, lstat and -X operators (like -e, -f, -d, -s, etc.) and pass them to our control. If the file is currently being mocked, we return the stat (or lstat) information on the file to be used to determine the answer to whatever check was made. This even works for things like C<-e _>.
If we do not control the file in question, we return C<FALLBACK_TO_REAL_OP()> which then makes a normal check.

=head3 CORE::GLOBAL:: overrides

Since 5.10, it has been possible to override function calls by defining them. like:

    *CORE::GLOBAL::open = sub(*;$@) {...}
    
Any code which is loaded B<AFTER> this happens will use the alternate open. This means you can place your C<use Test::MockFile> statement after statements you don't want mocked and
there is no risk that that code will ever be altered by Test::MockModule.

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

BEGIN {
    *CORE::GLOBAL::open = sub(*;$@) {
        my $abs_path = _abs_path_to_file( $_[2] );

        # open(my $fh, ">filehere"); # Just don't do this. It's bad.
        if ( scalar @_ != 3 ) {
            _real_file_access_hook( "open", \@_ );
            goto \&CORE::open if $] > 5.015;
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

        my $mode = $_[1];

        # TODO: We technically need to support this.
        # open(my $fh, "-|", "/bin/hostname"); # Read from command
        # open(my $fh, "|-", "/bin/passwd"); # Write to command
        if (   ( $mode eq '|-' || $mode eq '-|' )
            or !grep { $_ eq $mode } qw/> < >> +< +> +>>/
            or !defined $files_being_mocked{$abs_path} ) {
            _real_file_access_hook( "open", \@_ );
            goto \&CORE::open if $] > 5.015;
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

        #
        my $mock_file = $files_being_mocked{$abs_path};

        # If contents is undef, we act like the file isn't there.
        if ( !defined $mock_file->{'contents'} && grep { $mode eq $_ } qw/< +</ ) {
            $! = ENOENT;
            return;
        }

        my $rw = '';
        $rw .= 'r' if grep { $_ eq $mode } qw/+< +> +>> </;
        $rw .= 'w' if grep { $_ eq $mode } qw/+< +> +>> > >>/;

        $_[0] = IO::File->new;
        tie *{ $_[0] }, 'Test::MockFile::FileHandle', $abs_path, $rw;

        # This is how we tell if the file is open by something.

        $files_being_mocked{$abs_path}->{'fh'} = $_[0];
        Scalar::Util::weaken( $_[0] );    # Will this make it go out of scope?

        # Fix tell based on open options.
        if ( $mode eq '>>' or $mode eq '+>>' ) {
            $files_being_mocked{$abs_path}->{'contents'} //= '';
            seek $_[0], length( $files_being_mocked{$abs_path}->{'contents'} ), 0;
        }
        elsif ( $mode eq '>' or $mode eq '+>' ) {
            $files_being_mocked{$abs_path}->{'contents'} = '';
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
        my $abs_path = _abs_path_to_file( $_[1] );

        if ( !defined $files_being_mocked{$abs_path} ) {
            _real_file_access_hook( "sysopen", \@_ );
            goto \&CORE::sysopen if $] > 5.015;
            return CORE::sysopen( $_[0], $_[1], @_[ 2 .. $#_ ] );
        }

        my $mock_file    = $files_being_mocked{$abs_path};
        my $sysopen_mode = $_[2];

        # Not supported by my linux vendor: O_EXLOCK | O_SHLOCK
        if ( ( $sysopen_mode & SUPPORTED_SYSOPEN_MODES ) != $sysopen_mode ) {
            die( sprintf( "Sorry, can't open %s with 0x%x permissions. Some of your permissions are not yet supported by %s", $_[1], $sysopen_mode, __PACKAGE__ ) );
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
          :                           die("Unexpected sysopen read/write mode ($rd_wr_mode)");    # O_WRONLY| O_RDWR mode makes no sense and we should die.

        # If contents is undef, we act like the file isn't there.
        if ( !defined $mock_file->{'contents'} && $rd_wr_mode == O_RDONLY ) {
            $! = ENOENT;
            return;
        }

        $_[0] = IO::File->new;
        tie *{ $_[0] }, 'Test::MockFile::FileHandle', $abs_path, $rw;

        # This is how we tell if the file is open by something.
        $files_being_mocked{$abs_path}->{'fh'} = $_[0];
        Scalar::Util::weaken( $_[0] );    # Will this make it go out of scope?

        # O_TRUNC
        if ( $sysopen_mode & O_TRUNC ) {
            $mock_file->{'contents'} = '';
        }

        # O_APPEND
        if ( $sysopen_mode & O_APPEND ) {
            $_[0]->{'tell'} = length( $mock_file->{'contents'} );
        }

        return 1;
    };

    *CORE::GLOBAL::opendir = sub(*$) {

        my $abs_path = _abs_path_to_file( $_[1] );

        if ( scalar @_ != 2 ) {
            _real_file_access_hook( "opendir", \@_ );
            if ( $] > 5.015 ) {
                goto \&CORE::opendir;
            }
            return CORE::opendir( $_[0], @_[ 1 .. $#_ ] );
        }

        if ( !defined $files_being_mocked{$abs_path} ) {
            _real_file_access_hook( "opendir", \@_ );
            goto \&CORE::opendir if $] > 5.015;
            return CORE::opendir( $_[0], $_[1] );
        }

        my $mock_dir = $files_being_mocked{$abs_path};
        if ( !defined $mock_dir->{'contents'} ) {
            $! = ENOENT;
            return undef;
        }

        # This isn't a real IO::Dir.
        $_[0] = Test::MockFile::DirHandle->new( $abs_path, $mock_dir->{'contents'} );

        # This is how we tell if the file is open by something.
        $files_being_mocked{$abs_path}->{'fh'} = $_[0];
        Scalar::Util::weaken( $_[0] );    # Will this make it go out of scope?

        return 1;

    };

    *CORE::GLOBAL::readdir = sub(*) {
        my ($self) = @_;

        if ( $] > 5.015 ) {
            goto \&CORE::readdir if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            goto \&CORE::readdir unless defined $files_being_mocked{ $self->{'dir'} };
        }
        else {
            return CORE::readdir( $_[0] ) if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            return CORE::readdir( $_[0] ) unless defined $files_being_mocked{ $self->{'dir'} };
        }

        if ( !defined $self->{'files_in_readdir'} ) {
            die("Did a readdir on an empty dir. This shouldn't have been able to have been opened!");
        }

        if ( !defined $self->{'tell'} ) {
            die("readdir called on a closed dirhandle");
        }

        # At EOF for the dir handle.
        return undef if $self->{'tell'} > $#{ $self->{'files_in_readdir'} };

        if (wantarray) {
            my @return;
            foreach my $pos ( $self->{'tell'} .. $#{ $self->{'files_in_readdir'} } ) {
                push @return, $self->{'files_in_readdir'}->[$pos];
            }
            $self->{'tell'} = $#{ $self->{'files_in_readdir'} } + 1;
            return @return;
        }

        return $self->{'files_in_readdir'}->[ $self->{'tell'}++ ];
    };

    *CORE::GLOBAL::telldir = sub(*) {
        my ($self) = @_;

        if ( $] > 5.015 ) {
            goto \&CORE::telldir if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            goto \&CORE::telldir unless defined $files_being_mocked{ $self->{'dir'} };
        }
        else {
            return CORE::telldir($self) if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            return CORE::telldir($self) unless defined $files_being_mocked{ $self->{'dir'} };
        }

        if ( !defined $self->{'files_in_readdir'} ) {
            die("Did a telldir on an empty dir. This shouldn't have been able to have been opened!");
        }

        if ( !defined $self->{'tell'} ) {
            die("telldir called on a closed dirhandle");
        }

        return $self->{'tell'};
    };

    *CORE::GLOBAL::rewinddir = sub(*) {
        my ($self) = @_;

        if ( $] > 5.015 ) {
            goto \&CORE::rewinddir if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            goto \&CORE::rewinddir unless defined $files_being_mocked{ $self->{'dir'} };
        }
        else {
            return CORE::rewinddir($self) if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            return CORE::rewinddir($self) unless defined $files_being_mocked{ $self->{'dir'} };
        }

        if ( !defined $self->{'files_in_readdir'} ) {
            die("Did a rewinddir on an empty dir. This shouldn't have been able to have been opened!");
        }

        if ( !defined $self->{'tell'} ) {
            die("rewinddir called on a closed dirhandle");
        }

        $self->{'tell'} = 0;
        return 1;
    };

    *CORE::GLOBAL::seekdir = sub(*$) {
        my ( $self, $goto ) = @_;

        if ( $] > 5.015 ) {
            goto \&CORE::seekdir if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            goto \&CORE::seekdir unless defined $files_being_mocked{ $self->{'dir'} };
        }
        else {
            return CORE::seekdir( $self, $goto ) if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            return CORE::seekdir( $self, $goto ) unless defined $files_being_mocked{ $self->{'dir'} };
        }

        if ( !defined $self->{'files_in_readdir'} ) {
            die("Did a seekdir on an empty dir. This shouldn't have been able to have been opened!");
        }

        if ( !defined $self->{'tell'} ) {
            die("seekdir called on a closed dirhandle");
        }

        return $self->{'tell'} = $goto;
    };

    *CORE::GLOBAL::closedir = sub(*) {
        my ($self) = @_;

        if ( $] > 5.015 ) {
            goto \&CORE::closedir if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            goto \&CORE::closedir unless defined $files_being_mocked{ $self->{'dir'} };
        }
        else {
            return CORE::closedir($self) if !ref $self || ref $self ne 'Test::MockFile::DirHandle';
            return CORE::closedir($self) unless defined $files_being_mocked{ $self->{'dir'} };
        }

        if ( !defined $self->{'files_in_readdir'} ) {
            die("Did a closedir on an empty dir. This shouldn't have been able to have been opened!");
        }

        # Already closed?
        return if !defined $self->{'tell'};

        delete $self->{'tell'};
        return 1;
    };
}

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
