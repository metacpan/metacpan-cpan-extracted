# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Test::MockFile;

use 5.016;
use strict;
use warnings;

# perl -MFcntl -E'eval "say q{$_: } . $_" foreach sort {eval "$a" <=> eval "$b"} qw/O_RDONLY O_WRONLY O_RDWR O_CREAT O_EXCL O_NOCTTY O_TRUNC O_APPEND O_NONBLOCK O_NDELAY O_EXLOCK O_SHLOCK O_DIRECTORY O_NOFOLLOW O_SYNC O_BINARY O_LARGEFILE/'
use Fcntl;    # O_RDONLY, etc.

use constant SUPPORTED_SYSOPEN_MODES => O_RDONLY | O_WRONLY | O_RDWR | O_APPEND | O_TRUNC | O_EXCL | O_CREAT | O_NOFOLLOW;

use constant BROKEN_SYMLINK   => bless {}, "A::BROKEN::SYMLINK";
use constant CIRCULAR_SYMLINK => bless {}, "A::CIRCULAR::SYMLINK";

# we're going to use carp but the errors should come from outside of our package.
use Carp qw(carp confess croak);

BEGIN {
    $Carp::Internal{ (__PACKAGE__) }++;
    $Carp::Internal{'Overload::FileCheck'}++;
}
use Cwd                        ();
use IO::File                   ();
use Test::MockFile::FileHandle ();
use Test::MockFile::DirHandle  ();
use Text::Glob                 ();
use File::Glob                 ();
use Scalar::Util               ();

use Symbol;

use Overload::FileCheck '-from-stat' => \&_mock_stat, q{:check};

use Errno qw/EPERM EACCES ENOENT EBADF ELOOP ENOTEMPTY EEXIST EISDIR ENOTDIR EINVAL EXDEV/;

use constant FOLLOW_LINK_MAX_DEPTH => 10;

=head1 NAME

Test::MockFile - Allows tests to validate code that can interact with
files without touching the file system.

=head1 VERSION

Version 0.039

=cut

our $VERSION = '0.039';

our %files_being_mocked;

# Original Cwd functions saved before override
my $_original_cwd_abs_path;

# Tracks directories with autovivify enabled: path => mock object (weak ref)
my %_autovivify_dirs;

# Auto-incrementing inode counter for unique inode assignment
my $_next_inode = 1;

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

Intercepts file system calls for specific files so unit testing can
take place without any files being altered on disk.

This is useful for L<small
tests|https://testing.googleblog.com/2010/12/test-sizes.html> where
file interaction is discouraged.

A strict mode is even provided (and turned on by default) which can
throw a die when files are accessed during your tests!

    # Loaded before Test::MockFile so uses the core perl functions without any hooks.
    use Module::I::Dont::Want::To::Alter;

    # strict mode by default
    use Test::MockFile ();

    # non-strict mode
    use Test::MockFile qw< nostrict >;

    # trace mode - logs unmocked file accesses to STDERR
    use Test::MockFile qw< :trace >;

    # warn mode (like strict, but warns instead of dying)
    use Test::MockFile qw< warnstrict >;

    # Load with one or more plugins

    use Test::MockFile plugin => 'FileTemp';
    use Test::MockFile plugin => [ 'FileTemp', ... ];

    # Be sure to assign the output of mocks, they disappear when they go out of scope
    my $foobar = Test::MockFile->file( "/foo/bar", "contents\ngo\nhere" );
    open my $fh, '<', '/foo/bar' or die;    # Does not actually open the file on disk
    say '/foo/bar exists' if -e $fh;
    close $fh;

    say '/foo/bar is a file' if -f '/foo/bar';
    say '/foo/bar is THIS BIG: ' . -s '/foo/bar';

    my $foobaz = Test::MockFile->file('/foo/baz');    # File starts out missing
    my $opened = open my $baz_fh, '<', '/foo/baz';    # File reports as missing so fails
    say '/foo/baz does not exist yet' if !-e '/foo/baz';

    open $baz_fh, '>', '/foo/baz' or die;             # open for writing
    print {$baz_fh} "first line\n";

    open $baz_fh, '>>', '/foo/baz' or die;            # open for append.
    print {$baz_fh} "second line";
    close $baz_fh;

    say "Contents of /foo/baz:\n>>" . $foobaz->contents() . '<<';

    # Unmock your file.
    # (same as the variable going out of scope
    undef $foobaz;

    # The file check will now happen on file system now the file is no longer mocked.
    say '/foo/baz is missing again (no longer mocked)' if !-e '/foo/baz';

    my $quux    = Test::MockFile->file( '/foo/bar/quux.txt', '' );
    my @matches = </foo/bar/*.txt>;

    # ( '/foo/bar/quux.txt' )
    say "Contents of /foo/bar directory: " . join "\n", @matches;

    @matches = glob('/foo/bar/*.txt');

    # same as above
    say "Contents of /foo/bar directory (using glob()): " . join "\n", @matches;

    # Create a symlink using the builtin
    my $target_mock = Test::MockFile->file('/foo/target', "data");
    my $link_mock   = Test::MockFile->file('/foo/mylink');  # start as non-existent
    symlink('/foo/target', '/foo/mylink');                   # now it's a symlink
    say 'is a symlink!' if -l '/foo/mylink';

    # Create a hard link using the builtin
    my $orig_mock = Test::MockFile->file('/foo/original', "shared data");
    my $hard_mock = Test::MockFile->file('/foo/hardlink');
    link('/foo/original', '/foo/hardlink');
    say 'hard link exists!' if -f '/foo/hardlink';

=head1 IMPORT

When the module is loaded with no parameters, strict mode is turned on.
Any file checks, C<open>, C<sysopen>, C<opendir>, C<stat>, C<lstat>,
C<symlink>, or C<link> will throw a die.

For example:

    use Test::MockFile;

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

If we want to load the module without strict mode:

    use Test::MockFile qw< nostrict >;

=head3 Trace mode

Trace mode logs all unmocked file access operations to STDERR. This is
useful during development to discover which files your code touches, so
you know what to mock.

    use Test::MockFile qw< :trace >;

Each unmocked file operation produces a line like:

    [trace] open('/etc/hosts') at t/mytest.t line 42

Trace mode can be combined with nostrict to log all accesses without
dying:

    use Test::MockFile qw< :trace :nostrict >;

Tags may also be used without the colon prefix for backwards
compatibility:

    use Test::MockFile qw< trace nostrict >;

If we want to be warned about unmocked file access without dying:

    use Test::MockFile qw< warnstrict >;

This is useful when migrating an existing test suite to strict mode.
It allows you to discover all unmocked file accesses at once,
rather than fixing them one at a time.

Relative paths are not supported:

    use Test::MockFile;

    # Checking relative vs absolute paths
    $file = Test::MockFile->file( '/foo/../bar', '...' ); # not ok - relative path
    $file = Test::MockFile->file( '/bar',        '...' ); # ok     - absolute path
    $file = Test::MockFile->file( 'bar', '...' );         # ok     - current dir

=cut

use constant STRICT_MODE_DISABLED => 1;
use constant STRICT_MODE_ENABLED  => 2;
use constant STRICT_MODE_UNSET    => 4;
use constant STRICT_MODE_WARN     => 8;
use constant STRICT_MODE_DEFAULT  => STRICT_MODE_ENABLED | STRICT_MODE_UNSET;    # default state when unset by user

our $STRICT_MODE_STATUS;

BEGIN {
    $STRICT_MODE_STATUS = STRICT_MODE_DEFAULT;
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

    # Ignore variables
    # Barewords are provided as strings, which means they're read-only
    # (Of course, readonly scalars here will fool us...)
    Internals::SvREADONLY( $_[0] )
      or return @args;

    # Upgrade the handle
    my $handle;
    {
        no strict 'refs';
        my $caller_pkg = caller(1);
        $handle = *{"$caller_pkg\::$args[1]"};
    }

    # Check that the upgrading worked
    ref \$handle eq 'GLOB'
      or return @args;

    # Set to bareword
    $args[0] = 1;

    # Override original handle variable/string
    $args[1] = $handle;

    return @args;
}

=head2 authorized_strict_mode_for_package( $pkg )

Add a package namespace to the list of authorize namespaces.

    authorized_strict_mode_for_package( 'Your::Package' );

=cut

our %authorized_strict_mode_packages;

sub authorized_strict_mode_for_package {
    my ($pkg) = @_;

    $authorized_strict_mode_packages{$pkg} = 1;

    return;
}

BEGIN {
    authorized_strict_mode_for_package($_) for qw{ DynaLoader lib };
}

=head2 file_arg_position_for_command

Args: ($command)

Provides a hint with the position of the argument most likely holding
the file name for the current C<$command> call.

This is used internaly to provide better error messages. This can be
used when plugging hooks to know what's the filename we currently try
to access.

=cut

my $_file_arg_post;

sub file_arg_position_for_command {    # can also be used by user hooks
    my ( $command, $at_under_ref ) = @_;

    $_file_arg_post //= {
        'chmod'    => 1,
        'chown'    => 2,
        'lstat'    => 0,
        'mkdir'    => 0,
        'open'     => 2,
        'opendir'  => 1,
        'link'     => 0,
        'readlink' => 0,
        'rename'   => 0,
        'rmdir'    => 0,
        'stat'     => 0,
        'symlink'  => 1,
        'sysopen'  => 1,
        'truncate' => 0,
        'unlink'   => 0,
        'utime'    => 2,
        'readdir'  => 0,
    };

    return -1 unless defined $command && defined $_file_arg_post->{$command};

    # exception for open
    return 1 if $command eq 'open' && ref $at_under_ref && scalar @$at_under_ref == 2;

    return $_file_arg_post->{$command};
}

use constant _STACK_ITERATION_MAX => 100;

sub _get_stack {
    my @stack;

    foreach my $stack_level ( 1 .. _STACK_ITERATION_MAX ) {
        @stack = caller($stack_level);
        last if !scalar @stack;
        last if !defined $stack[0];    # We don't know when this would ever happen.

        next if $stack[0] eq __PACKAGE__;
        next if $stack[0] eq 'Overload::FileCheck';    # companion package

        return if $authorized_strict_mode_packages{ $stack[0] };

        last;
    }

    return @stack;
}

=head2 add_strict_rule( $command_rule, $file_rule, $action )

Args: ($command_rule, $file_rule, $action)

Add a custom rule to validate strictness mode. This is the fundation to
add strict rules. You should use it, when none of the other helper to
add rules work for you.

=over

=item C<$command_rule> a string or regexp or list of any to indicate
which command to match

=item C<$file_rule> a string or regexp or undef or list of any to indicate
which files your rules apply to.

=item C<$action> a CODE ref or scalar to handle the exception.
Returning '1' skip all other rules and indicate an exception.

=back

    # Check open() on /this/file
    add_strict_rule( 'open', '/this/file', sub { ... } );

    # always bypass the strict rule
    add_strict_rule( 'open', '/this/file', 1 );

    # all available options
    add_strict_rule( 'open', '/this/file', sub {
        my ($context) = @_;

        return;   # Skip this rule and continue from the next one
        return 0; # Strict violation, stop testing rules and die
        return 1; # Strict passing, stop testing rules
    } );

    # Disallow open(), close() on everything in /tmp/
    add_strict_rule(
        [ qw< open close > ],
        qr{^/tmp}xms,
        0,
    );

    # Disallow open(), close() on everything (ignore filenames)
    # Use add_strict_rule_for_command() instead!
    add_strict_rule(
        [ qw< open close > ],
        undef,
        0,
    );

=cut

my @STRICT_RULES;

sub add_strict_rule {
    my ( $command_rule, $file_rule, $action ) = @_;

    defined $command_rule
      or croak("add_strict_rule( COMMAND, PATH, ACTION )");

    croak("Invalid rule: missing action code") unless defined $action;

    my @commands = ref $command_rule eq 'ARRAY' ? @{$command_rule} : ($command_rule);
    my @files    = ref $file_rule eq 'ARRAY'    ? @{$file_rule}    : ($file_rule);

    foreach my $c_rule (@commands) {
        foreach my $f_rule (@files) {
            push @STRICT_RULES, {
                'command_rule' => ref $c_rule eq 'Regexp'                         ? $c_rule : qr/^\Q$c_rule\E$/,
                'file_rule'    => ( ref $f_rule eq 'Regexp' || !defined $f_rule ) ? $f_rule : qr/^\Q$f_rule\E$/,
                'action'       => $action,
            };
        }
    }

    return;
}

=head2 clear_strict_rules()

Args: none

Clear all previously defined rules. (Mainly used for testing purpose)

=cut

sub clear_strict_rules {
    @STRICT_RULES = ();

    return;
}

=head2 add_strict_rule_for_filename( $file_rule, $action )

Args: ($file_rule, $action)

Prefer using that helper when trying to add strict rules targeting
files.

Apply a rule to one or more files.

    add_strict_rule_for_filename( '/that/file' => sub { ... } );

    add_strict_rule_for_filename( [ qw{list of files} ] => sub { ... } );

    add_strict_rule_for_filename( qr{*\.t$} => sub { ... } );

    add_strict_rule_for_filename( [ $dir, qr{^${dir}/} ] => 1 );

=cut

sub add_strict_rule_for_filename {
    my ( $file_rule, $action ) = @_;

    return add_strict_rule( qr/.*/, $file_rule, $action );
}

=head2 add_strict_rule_for_command( $command_rule, $action )

Args: ($command_rule, $action)

Prefer using that helper when trying to add strict rules targeting
specici commands.

Apply a rule to one or more files.

    add_strict_rule_for_command( 'open' => sub { ... } );

    add_strict_rule_for_command( [ qw{open readdir} ] => sub { ... } );

    add_strict_rule_for_command( qr{open.*} => sub { ... } );

    Test::MockFile::add_strict_rule_for_command(
        [qw{ readdir closedir readlink }],
        sub {
            my ($ctx) = @_;
            my $command = $ctx->{command} // 'unknown';

            warn( "Ignoring strict mode violation for $command" );
            return 1;
        }
    );

=cut

sub add_strict_rule_for_command {
    my ( $command_rule, $action, $extra ) = @_;

    if ($extra) {
        die q[Syntax not supported (extra arg) for 'add_strict_rule_for_command', please consider using 'add_strict_rule' instead.];
    }

    return add_strict_rule( $command_rule, undef, $action );
}

=head2 add_strict_rule_generic( $action )

Args: ($action)

Prefer using that helper when adding a rule which is global and does
not apply to a specific command or file.

Apply a rule to one or more files.

    add_strict_rule_generic( sub { ... } );

    add_strict_rule_generic( sub  {
        my ($ctx) = @_;

        my $filename = $ctx->{filename};

        return unless defined $filename;

        return 1 if UNIVERSAL::isa( $filename, 'GLOB' );

        return;
    } );

=cut

sub add_strict_rule_generic {
    my ($action) = @_;

    return add_strict_rule( qr/.*/, undef, $action );
}

=head2 is_strict_mode

Boolean helper to determine if strict mode is currently enabled.

=cut

sub is_strict_mode {
    return $STRICT_MODE_STATUS & STRICT_MODE_ENABLED ? 1 : 0;
}

=head2 is_warn_mode

Boolean helper to determine if warn mode is currently enabled.
When warn mode is active, strict mode violations produce warnings
instead of fatal errors.

=cut

sub is_warn_mode {
    return ( $STRICT_MODE_STATUS & STRICT_MODE_ENABLED && $STRICT_MODE_STATUS & STRICT_MODE_WARN ) ? 1 : 0;
}

sub _strict_mode_violation {
    my ( $command, $at_under_ref ) = @_;

    return unless is_strict_mode();

    # These commands deal with dir handles we should have already been in violation when we opened the thing originally.
    return if grep { $command eq $_ } qw/readdir telldir rewinddir seekdir closedir/;

    my @stack = _get_stack();
    return unless scalar @stack;    # skip the package

    my $filename;

    # check it later so we give priority to authorized_strict_mode_packages
    my $file_arg = file_arg_position_for_command( $command, $at_under_ref );

    if ( $file_arg >= 0 ) {
        $filename = scalar @$at_under_ref <= $file_arg ? '<not specified>' : $at_under_ref->[$file_arg];
    }

    # Ignore stats on STDIN, STDOUT, STDERR
    return if defined $filename && $filename =~ m/^\*?(?:main::)?[<*&+>]*STD(?:OUT|IN|ERR)$/;

    # The filename passed is actually a handle. This means that, usually,
    # we don't need to check if it's a violation since something else should
    # have opened it first. open and sysopen, though, require special care.
    #
    if ( UNIVERSAL::isa( $filename, 'GLOB' ) ) {
        return if $command ne 'open' && $command ne 'sysopen';
    }

    # open >& is for file dups. this isn't a real file access.
    return if $command eq 'open' && $at_under_ref->[1] && $at_under_ref->[1] =~ m/&/;

    my $path = _abs_path_to_file($filename);

    my $context = {
        command      => $command,
        filename     => $path,
        at_under_ref => $at_under_ref
    };    # object

    my $pass = _validate_strict_rules($context);
    return if $pass;

    if ( $file_arg == -1 ) {
        if ( $STRICT_MODE_STATUS & STRICT_MODE_WARN ) {
            carp("Unknown strict mode violation for $command");
            return;
        }
        croak("Unknown strict mode violation for $command");
    }

    my $msg = "Use of $command to access unmocked file or directory '$filename' in strict mode at $stack[1] line $stack[2]";
    if ( $STRICT_MODE_STATUS & STRICT_MODE_WARN ) {
        carp($msg);
        return;
    }
    confess($msg);
}

sub _validate_strict_rules {
    my ($context) = @_;

    # rules dispatch
    foreach my $rule (@STRICT_RULES) {

        # This is when a rule was added without a filename at all
        # intending to match whether there's a filename available or not
        # (open() can be used on a scalar, for example)
        if ( defined $rule->{'file_rule'} ) {
            defined $context->{'filename'} && $context->{'filename'} =~ $rule->{'file_rule'}
              or next;
        }

        $context->{'command'} =~ $rule->{'command_rule'}
          or next;

        my $answer = ref $rule->{'action'} ? $rule->{'action'}->($context) : $rule->{'action'};

        defined $answer
          and return $answer;
    }

    # We say it failed even though it didn't
    # It's because we want to test the internal violation rule check
    return;
}

my @plugins;

# Mock user identity for permission checks (GH #3)
# When set, file operations check Unix permissions against this identity.
# When undef, no permission checks are performed (backward compatible).
my $_mock_uid;
my @_mock_gids;

=head2 set_user

Args: ($uid, @gids)

Sets a mock user identity for permission checking. When set, all
mocked file operations will check Unix permissions (owner/group/other)
against this identity instead of the real process credentials.

The first gid in C<@gids> is the primary group. If no gids are provided,
the primary group defaults to 0.

    Test::MockFile->set_user(1000, 1000);  # uid=1000, gid=1000
    my $f = Test::MockFile->file('/foo', 'bar', { mode => 0600, uid => 0 });
    open(my $fh, '<', '/foo') or die;  # dies: EACCES (not owner)

    Test::MockFile->set_user(0, 0);  # root can read anything
    open(my $fh, '<', '/foo') or die;  # succeeds

=cut

sub set_user {
    my ( $class, $uid, @gids ) = @_;

    defined $uid or croak("set_user() requires a uid argument");

    $_mock_uid  = int $uid;
    @_mock_gids = @gids ? map { int $_ } @gids : (0);

    return;
}

=head2 clear_user

Clears the mock user identity, disabling permission checks.
File operations will succeed regardless of mode bits (the default
behavior).

    Test::MockFile->clear_user();

=cut

sub clear_user {
    $_mock_uid  = undef;
    @_mock_gids = ();

    return;
}

# _check_perms($mock, $access)
# Checks Unix permission bits on a mock file object.
# $access is a bitmask: 4=read, 2=write, 1=execute (same as R_OK/W_OK/X_OK)
# Returns 1 if access is allowed, 0 if denied.
# When no mock user is set ($_mock_uid is undef), always returns 1.
sub _check_perms {
    my ( $mock, $access ) = @_;

    return 1 unless defined $_mock_uid;

    my $mode = $mock->{'mode'} & S_IFPERMS;

    # Root bypass: root can read/write anything.
    # For execute, root needs at least one x bit set.
    if ( $_mock_uid == 0 ) {
        return ( $access & 1 ) ? ( $mode & 0111 ? 1 : 0 ) : 1;
    }

    # Determine which permission triad applies
    my $bits;
    if ( $_mock_uid == $mock->{'uid'} ) {
        $bits = ( $mode >> 6 ) & 07;
    }
    elsif ( grep { $_ == $mock->{'gid'} } @_mock_gids ) {
        $bits = ( $mode >> 3 ) & 07;
    }
    else {
        $bits = $mode & 07;
    }

    return ( $bits & $access ) == $access ? 1 : 0;
}

# _check_parent_perms($path, $access)
# Checks permissions on the parent directory of $path.
# Used for operations that modify directory contents (unlink, mkdir, rmdir).
# Returns 1 if allowed, 0 if denied.
sub _check_parent_perms {
    my ( $path, $access ) = @_;

    return 1 unless defined $_mock_uid;

    ( my $parent = $path ) =~ s{ / [^/]+ $ }{}xms;
    $parent = '/' if $parent eq '';

    my $parent_mock = _get_file_object($parent);
    return 1 unless $parent_mock;    # Parent not mocked, skip check

    return _check_perms( $parent_mock, $access );
}

my @_tmf_callers;

# Packages where autodie was active when T::MF was imported.
# Used as a fallback for Perl versions where caller(N)[10] hints
# may not be reliable after goto &sub.
my %_autodie_callers;

# Declared before import() which references them for :trace support
my @_public_access_hooks;
my @_internal_access_hooks = ( \&_strict_mode_violation );
my $TRACE_ENABLED;

sub import {
    my ( $class, @args ) = @_;

    my $strict_mode;
    if ( grep { $_ eq 'nostrict' || $_ eq ':nostrict' } @args ) {
        $strict_mode = STRICT_MODE_DISABLED;
    }
    elsif ( grep { $_ eq 'warnstrict' || $_ eq ':warnstrict' } @args ) {
        $strict_mode = STRICT_MODE_ENABLED | STRICT_MODE_WARN;
    }
    else {
        $strict_mode = STRICT_MODE_ENABLED;
    }

    if (
        defined $STRICT_MODE_STATUS
        && !( $STRICT_MODE_STATUS & STRICT_MODE_UNSET )    # mode is set by user
        && $STRICT_MODE_STATUS != $strict_mode
    ) {

        # could consider using authorized_strict_mode_packages for all packages
        die q[Test::MockFile is imported multiple times with different strict modes (not currently supported) ] . $class;
    }
    $STRICT_MODE_STATUS = $strict_mode;

    if ( grep { $_ eq 'trace' || $_ eq ':trace' } @args ) {
        if ( !$TRACE_ENABLED ) {
            $TRACE_ENABLED = 1;

            # Insert before _strict_mode_violation so trace fires even when strict mode will die
            unshift @_internal_access_hooks, \&_trace_hook;
        }
    }

    while ( my $opt = shift @args ) {
        next unless defined $opt && $opt eq 'plugin';
        my $what = shift @args;
        require Test::MockFile::Plugins;

        push @plugins, Test::MockFile::Plugins::load_plugin($what);
    }

    # Install per-package overrides to handle autodie compatibility.
    # autodie installs per-package wrappers that call CORE:: directly,
    # bypassing CORE::GLOBAL::. By also installing into the caller's
    # namespace, we ensure our overrides take precedence.
    my $caller = scalar caller;
    _install_package_overrides($caller);

    # Cache autodie state at import time as a fallback for Perl versions
    # where caller(N)[10] hints after goto &sub may not be reliable.
    if ( $INC{'autodie.pm'} || $INC{'Fatal.pm'} ) {
        my $hints = ( caller(0) )[10];
        if ( ref $hints eq 'HASH' && grep { /^(?:autodie|Fatal::)/ } keys %$hints ) {
            $_autodie_callers{$caller} = 1;
        }
    }

    return;
}

# Install a sub into a package, replicating the delete-glob trick used by
# autodie/Fatal.pm's install_subs.  Simple glob assignment (*pkg::func = \&sub)
# does not override builtins when autodie has already installed its wrapper —
# the glob entry must be deleted and recreated for Perl to pick up the new sub.
sub _install_sub {
    my ( $pkg, $name, $ref ) = @_;

    no strict 'refs';
    no warnings qw(redefine once);

    my $full_name  = "${pkg}::${name}";
    my $pkg_sym    = "${pkg}::";
    my $old_glob   = *$full_name;

    # Delete the stash entry so Perl re-resolves the symbol.
    delete $pkg_sym->{$name};

    # Restore non-CODE slots (SCALAR, ARRAY, HASH, IO) from the old glob
    # so we don't clobber unrelated data in the same symbol.
    local *alias = *$full_name;
    foreach my $slot (qw( SCALAR ARRAY HASH IO )) {
        next unless defined( *$old_glob{$slot} );
        *alias = *$old_glob{$slot};
    }

    *$full_name = $ref;
}

# Install goto-transparent wrappers into the caller's package namespace.
# These use goto to preserve @_ aliasing and caller() transparency.
# Uses the delete-glob technique so that Perl properly picks up our
# overrides even when autodie/Fatal.pm has already installed wrappers.
sub _install_package_overrides {
    my ($caller) = @_;

    return if $caller eq __PACKAGE__;
    return if $caller eq 'Test::MockFile::FileHandle';
    return if $caller eq 'Test::MockFile::DirHandle';

    push @_tmf_callers, $caller
      unless grep { $_ eq $caller } @_tmf_callers;

    my %subs = (
        'open'      => sub (*;$@)  { goto \&__open },
        'sysopen'   => sub (*$$;$) { goto \&__sysopen },
        'opendir'   => sub (*$)    { goto \&__opendir },
        'readdir'   => sub (*)     { goto \&__readdir },
        'telldir'   => sub (*)     { goto \&__telldir },
        'rewinddir' => sub (*)     { goto \&__rewinddir },
        'seekdir'   => sub (*$)    { goto \&__seekdir },
        'closedir'  => sub (*)     { goto \&__closedir },
        'unlink'    => sub (@)     { goto \&__unlink },
        'readlink'  => sub (_)     { goto \&__readlink },
        'mkdir'     => sub (_;$)   { goto \&__mkdir },
        'rmdir'     => sub (_)     { goto \&__rmdir },
        'chown'     => sub (@)     { goto \&__chown },
        'chmod'     => sub (@)     { goto \&__chmod },
        'rename'    => sub ($$)    { goto \&__rename },
        'link'      => sub ($$)    { goto \&__link },
        'symlink'   => sub ($$)    { goto \&__symlink },
        'truncate'  => sub ($$)    { goto \&__truncate },
        'flock'     => sub (*$)    { goto \&__flock },
        'utime'     => sub (@)     { goto \&__utime },
    );

    _install_sub( $caller, $_, $subs{$_} ) for keys %subs;
}

# Check if autodie is active for a given function in the caller's scope.
# autodie stores its state in the lexical hints hash (%^H),
# accessible via (caller($depth))[10]. The keys vary by version.
sub _caller_has_autodie_for {
    my ($func) = @_;
    return unless $INC{'autodie.pm'} || $INC{'Fatal.pm'};

    # Primary: walk the caller stack for lexical hints set by autodie.
    for my $depth ( 1 .. 10 ) {
        my @c = caller($depth);
        last unless @c;
        my $hints = $c[10];
        next unless ref $hints eq 'HASH';
        return 1
          if $hints->{'autodie'}
          || $hints->{"Fatal::$func"}
          || $hints->{"autodie::$func"};
    }

    # Fallback: check if the calling package had autodie active at import
    # time. On some Perl versions, caller(N)[10] hints may not propagate
    # reliably through goto &sub. This is less precise (doesn't respect
    # "no autodie" sub-scopes) but catches the common case.
    my $caller_pkg = caller(1);
    return $_autodie_callers{$caller_pkg} if $caller_pkg;

    return;
}

# Check-and-throw for autodie: combines _caller_has_autodie_for + _throw_autodie
# into a single call to reduce boilerplate at every error return site.
sub _maybe_throw_autodie {
    my ($func, @args) = @_;
    _throw_autodie($func, @args) if _caller_has_autodie_for($func);
}

# Throw an autodie-compatible exception for a failed CORE function.
# Creates a real autodie::exception if available, otherwise a plain die.
# $! must be saved before the eval since eval can clobber it.
sub _throw_autodie {
    my ($func, @args) = @_;
    my $saved_errno = int($!);
    my $saved_errstr = "$!";
    if ( eval { require autodie::exception; 1 } ) {
        local $! = $saved_errno;
        die autodie::exception->new(
            function => "CORE::$func",
            args     => \@args,
            errno    => $saved_errstr,
            context  => 'scalar',
            return   => undef,
        );
    }
    die sprintf( "Can't %s '%s': '%s'", $func, $args[0] // '', $saved_errstr );
}

# Re-install after all compilation to handle the case where
# autodie is loaded after Test::MockFile (autodie's import()
# would overwrite our per-package overrides during compilation).
# Wrapped in BEGIN+eval to avoid "Too late to run CHECK block"
# warning when the module is loaded at runtime via require.
BEGIN {
    eval 'CHECK {
        _install_package_overrides($_) for @_tmf_callers;
        # If autodie was loaded during compilation (possibly after T::MF),
        # mark all T::MF callers for the autodie fallback detection.
        if ($INC{"autodie.pm"} || $INC{"Fatal.pm"}) {
            $_autodie_callers{$_} = 1 for @_tmf_callers;
        }
    }'
      unless ${^GLOBAL_PHASE} eq 'RUN';
}

=head1 SUBROUTINES/METHODS

=head2 file

Args: ($file, $contents, $stats)

This will make cause $file to be mocked in all file checks, opens, etc.

C<undef> contents means that the file should act like it's not there.
You can only set the stats if you provide content.

If you give file content, the directory inside it will be mocked as
well.

    my $f = Test::MockFile->file( '/foo/bar' );
    -d '/foo' # not ok

    my $f = Test::MockFile->file( '/foo/bar', 'some content' );
    -d '/foo' # ok

See L<Mock Stats> for what goes into the stats hashref.

=cut

sub file {
    my ( $class, $file, $contents, @stats ) = @_;

    ( defined $file && length $file ) or confess("No file provided to instantiate $class");
    _is_path_mocked($file) and confess("It looks like $file is already being mocked. We don't support double mocking yet.");

    my $path = _abs_path_to_file($file);
    _validate_path($_) for $file, $path;

    if ( @stats > 1 ) {
        confess(
            sprintf 'Unknown arguments (%s) passed to file() as stats',
            join ', ', @stats
        );
    }

    !defined $contents && @stats
      and confess("You cannot set stats for non-existent file '$path'");

    my %stats;
    if (@stats) {
        ref $stats[0] eq 'HASH'
          or confess('->file( FILE_NAME, FILE_CONTENT, { STAT_INFORMATION } )');

        %stats = %{ $stats[0] };
    }

    my $perms = S_IFPERMS & ( defined $stats{'mode'} ? int( $stats{'mode'} ) : 0666 );
    $stats{'mode'} = ( $perms & ~umask ) | S_IFREG;

    # Check if directory for this file is an object we're mocking
    # If so, mark it now as having content
    # which is this file or - if this file is undef, . and ..
    ( my $dirname = $path ) =~ s{ / [^/]+ $ }{}xms;
    if ( defined $contents && $files_being_mocked{$dirname} ) {
        $files_being_mocked{$dirname}{'has_content'} = 1;
        _update_parent_dir_times($path);
    }

    return $class->new(
        {
            'path'     => $path,
            'contents' => $contents,
            %stats
        }
    );
}

=head2 file_from_disk

Args: C<($file_to_mock, $file_on_disk, $stats)>

This will make cause C<$file> to be mocked in all file checks, opens,
etc.

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

=head2 file_passthrough

Args: C<($file_or_glob)>

Registers a path (or shell glob pattern) with Test::MockFile but delegates
B<all> file operations (C<stat>, C<open>, C<-f>, etc.) to the real filesystem.
The path is not actually mocked: it is simply allowed through strict mode so
that XS-based modules (e.g. L<DBD::SQLite>, L<DBI>) that perform C-level I/O
can create and use the file while Perl-level checks remain consistent.

A glob pattern (containing C<*>, C<?>  or C<[>C<]>) matches any path that fits
the pattern.  This is useful for modules like L<DBD::SQLite> that create
auxiliary files alongside the main database (e.g. C<.db-wal>, C<.db-shm>):

    use Test::MockFile;    # strict mode by default
    use DBI;

    # Allow the SQLite database and any auxiliary files it creates.
    my $mock = Test::MockFile->file_passthrough('/tmp/test.db*');
    my $dbh  = DBI->connect("dbi:SQLite:dbname=/tmp/test.db", "", "");

    ok $dbh->ping,        'ping works';
    ok -f '/tmp/test.db', 'file exists on disk';

For a single, exact path:

    my $mock = Test::MockFile->file_passthrough('/tmp/test.db');

When the returned object goes out of scope, the strict-mode rule is
removed but the real file is B<not> deleted.  Clean up the file
yourself if needed:

    undef $mock;
    unlink '/tmp/test.db';

=cut

sub file_passthrough {
    my ( $class, $file ) = @_;

    ( defined $file && length $file ) or confess("No file provided to instantiate $class");

    my $path = _abs_path_to_file($file);

    # If the pattern contains glob metacharacters, build a regex from it.
    # Otherwise use a literal match.
    my $file_rule;
    if ( $path =~ /[*?\[\{]/ ) {
        $file_rule = Text::Glob::glob_to_regex($path);
    }
    else {
        $file_rule = qr/^\Q$path\E$/;
    }

    # Build a strict-mode rule that allows all operations on matching paths.
    my $rule = {
        'command_rule' => qr/.*/,
        'file_rule'    => $file_rule,
        'action'       => 1,
    };
    push @STRICT_RULES, $rule;

    # We intentionally do NOT register in %files_being_mocked.
    # This means _mock_stat, __open, etc. will all fall through to the
    # real filesystem via FALLBACK_TO_REAL_OP / goto &CORE::*.
    return bless {
        'path'              => $path,
        '_passthrough'      => 1,
        '_passthrough_rule' => $rule,
    }, $class;
}

=head2 symlink

Args: ($readlink, $file )

This will cause $file to be mocked in all file checks, opens, etc.

C<$readlink> indicates what "fake" file it points to. If the file
C<$readlink> points to is not mocked, it will act like a broken link,
regardless of what's on disk.

If C<$readlink> is undef, then the symlink is mocked but not
present.(lstat $file is empty.)

Stats are not able to be specified on instantiation but can in theory
be altered after the object is created. People don't normally mess with
the permissions on a symlink.

=cut

sub symlink {
    my ( $class, $readlink, $file ) = @_;

    ( defined $file && length $file )          or confess("No file provided to instantiate $class");
    ( !defined $readlink || length $readlink ) or confess("No file provided for $file to point to in $class");

    _is_path_mocked($file) and confess("It looks like $file is already being mocked. We don't support double mocking yet.");

    # Check if directory for this file is an object we're mocking
    # If so, mark it now as having content
    # which is this file or - if this file is undef, . and ..
    ( my $dirname = $file ) =~ s{ / [^/]+ $ }{}xms;
    if ( $files_being_mocked{$dirname} ) {
        $files_being_mocked{$dirname}{'has_content'} = 1;
        _update_parent_dir_times($file) if defined $readlink;
    }

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

    # Reject the following:
    # ./ ../ /. /.. /./ /../
    if ( $path =~ m{ ( ^ | / ) \.{2} ( / | $ ) }xms ) {
        confess('Relative paths are not supported');
    }

    return;
}

=head2 dir

Args: ($dir)

This will cause $dir to be mocked in all file checks, and C<opendir>
interactions.

The directory name is normalized so any trailing slash is removed.

    $dir = Test::MockFile->dir( 'mydir/', ... ); # ok
    $dir->path();                                # mydir

If there were previously mocked files (within the same scope), the
directory will exist. Otherwise, the directory will be nonexistent.

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

NOTE: Because C<.> and C<..> will always be the first things C<readdir>
returns, These files are automatically inserted at the front of the
array. The order of files is sorted.

If you want to affect the stat information of a directory, you need to
use the available core Perl keywords. (We might introduce a special
helper method for it in the future.)

    $d = Test::MockFile->dir( '/foo', [], { 'mode' => 0755 } );    # dies
    $d = Test::MockFile->dir( '/foo', undef, { 'mode' => 0755 } ); # dies

    $d = Test::MockFile->dir('/foo');
    mkdir $d, 0755;                   # ok

=head3 autovivify

When C<autovivify> is enabled, any file operation (open, stat, rename,
mkdir, etc.) on a path under the directory will automatically create a
mocked file entry. This supports the common pattern of writing to a temp
file and renaming it into place.

    my $dir = Test::MockFile->new_dir( '/data', { 'autovivify' => 1 } );

    # Files are auto-mocked when accessed -- no need to declare them
    open my $fh, '>', '/data/.tmp.cfg' or die;
    print $fh $config;
    close $fh;
    rename '/data/.tmp.cfg', '/data/config.ini';

    -e '/data/config.ini';   # true

Auto-vivified files are tied to the parent directory's lifetime: when
the directory mock goes out of scope, all auto-vivified children are
cleaned up.

=cut

sub dir {
    my ( $class, $dirname, $opts ) = @_;

    ( defined $dirname && length $dirname ) or confess("No directory name provided to instantiate $class");
    _is_path_mocked($dirname) and confess("It looks like $dirname is already being mocked. We don't support double mocking yet.");

    my $path = _abs_path_to_file($dirname);
    _validate_path($_) for $dirname, $path;

    # Cleanup trailing forward slashes
    $path ne '/'
      and $path =~ s{[/\\]$}{}xmsg;

    my $autovivify;
    if ( ref $opts eq 'HASH' ) {
        $autovivify = delete $opts->{'autovivify'};
        confess("You cannot set stats for nonexistent dir '$path'")
          if keys %{$opts};
    }
    elsif ( @_ > 2 ) {
        confess("You cannot set stats for nonexistent dir '$path'");
    }

    my $perms = S_IFPERMS & 0777;
    my %stats = ( 'mode' => ( $perms & ~umask ) | S_IFDIR );

    # TODO: Add stat information

    # Only count children that actually exist (not non-existent placeholders)
    my $has_content = grep {
        my $m = $files_being_mocked{$_};
        $m && $m->exists
    } grep m{^\Q$path/\E}xms, keys %files_being_mocked;
    my $self = $class->new(
        {
            'path'        => $path,
            'has_content' => $has_content,
            'autovivify'  => $autovivify ? 1 : 0,
            %stats
        }
    );

    if ($autovivify) {
        $_autovivify_dirs{$path} = $self;
        Scalar::Util::weaken( $_autovivify_dirs{$path} );
    }

    return $self;
}

=head2 new_dir

    # short form
    $new_dir = Test::MockFile->new_dir( '/path' );
    $new_dir = Test::MockFile->new_dir( '/path', { 'mode' => 0755 } );

    # longer form 1
    $dir = Test::MockFile->dir('/path');
    mkdir $dir->path(), 0755;

    # longer form 2
    $dir = Test::MockFile->dir('/path');
    mkdir $dir->path();
    chmod $dir->path();

This creates a new directory with an optional mode. This is a
short-hand that might be removed in the future when a stable, new
interface is introduced.

=cut

sub new_dir {
    my ( $class, $dirname, $opts ) = @_;

    my $mode;
    my %stat_overrides;
    my @args = $opts ? $opts : ();
    if ( ref $opts eq 'HASH' ) {
        $mode = delete $opts->{'mode'} if $opts->{'mode'};

        # Extract stat overrides that dir() doesn't accept
        for my $key (qw(uid gid)) {
            $stat_overrides{$key} = delete $opts->{$key} if exists $opts->{$key};
        }

        # This is to make sure the error checking still happens as expected
        if ( keys %{$opts} == 0 ) {
            @args = ();
        }
    }

    my $dir = $class->dir( $dirname, @args );
    if ($mode) {
        __mkdir( $dirname, $mode );
    }
    else {
        __mkdir($dirname);
    }

    # Apply stat overrides after mkdir has created the directory
    for my $key ( keys %stat_overrides ) {
        $dir->{$key} = $stat_overrides{$key};
    }

    return $dir;
}

=head2 Mock Stats

When creating mocked files or directories, we default their stats to:

    my $attrs = Test::MockFile->file( $file, $contents, {
            'dev'       => 0,            # stat[0]
            'inode'     => $next_inode,   # stat[1] - auto-assigned unique value
            'mode'      => $mode,         # stat[2]
            'nlink'     => 1,             # stat[3] - 1 for files/symlinks, 2 for dirs
            'uid'       => int $>,        # stat[4]
            'gid'       => int $),        # stat[5]
            'rdev'      => 0,             # stat[6]
            'atime'     => $now,          # stat[8]
            'mtime'     => $now,          # stat[9]
            'ctime'     => $now,          # stat[10]
            'blksize'   => 4096,          # stat[11]
            'fileno'    => undef,         # fileno()
    } );

You'll notice that mode, size, and blocks have been left out of this.
Mode is set to 666 (for files) or 777 (for directories), xored against
the current umask. Size and blocks are calculated based on the size of
'contents' a.k.a. the fake file. Each mock is assigned a unique inode
number, and nlink defaults to 1 for files and symlinks, 2 for
directories.

When you want to override one of the defaults, all you need to do is
specify that when you declare the file or directory. The rest will
continue to default.

    my $mfile = Test::MockFile->file("/root/abc", "...", {inode => 65, uid => 123, mtime => int((2000-1970) * 365.25 * 24 * 60 * 60 }));

    my $mdir = Test::MockFile->dir("/sbin", "...", { mode => 0700 }));

=head2 new

This class method is called by file/symlink/dir. There is no good
reason to call this directly.

=cut

# Returns the default attribute hash for a new mock object.
# Centralizes defaults so new(), _create_file_through_broken_symlink(),
# and _maybe_autovivify() stay in sync.
sub _default_mock_attrs {
    my $now = time;
    return (
        'dev'                    => 0,         # stat[0]
        'inode'                  => 0,         # stat[1]
        'mode'                   => 0,         # stat[2]
        'nlink'                  => 0,         # stat[3]
        'uid'                    => int $>,    # stat[4]
        'gid'                    => int $),    # stat[5]
        'rdev'                   => 0,         # stat[6]
        'atime'                  => $now,      # stat[8]
        'mtime'                  => $now,      # stat[9]
        'ctime'                  => $now,      # stat[10]
        'blksize'                => 4096,      # stat[11]
        'fileno'                 => undef,     # fileno()
        'tty'                    => 0,
        'readlink'               => '',
        'path'                   => undef,
        'contents'               => undef,
        'has_content'            => undef,
        'autovivify'             => 0,
        '_autovivified_children' => undef,
    );
}

# Creates a non-existent file mock (contents=undef) with default attrs.
# Used by _create_file_through_broken_symlink and _maybe_autovivify.
# The caller is responsible for registering the mock in %files_being_mocked
# and attaching it to a parent (for strong-ref lifetime management).
sub _new_nonexistent_file_mock {
    my ($abs_path) = @_;

    my $perms = S_IFPERMS & 0666;
    return bless {
        _default_mock_attrs(),
        'inode' => $_next_inode++,
        'mode'  => ( $perms & ~umask ) | S_IFREG,
        'nlink' => 1,
        'path'  => $abs_path,
    }, __PACKAGE__;
}

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

    my $self = bless { _default_mock_attrs(), }, $class;

    foreach my $key ( keys %opts ) {

        # Ignore Stuff that's not a valid key for this class.
        next unless exists $self->{$key};

        # If it's passed in, we override them.
        $self->{$key} = $opts{$key};
    }

    # Assign a unique inode if the user didn't provide one
    if ( !$self->{'inode'} ) {
        $self->{'inode'} = $_next_inode++;
    }

    # Set realistic nlink defaults if the user didn't provide one.
    # Real filesystems: files/symlinks have nlink=1, directories have nlink=2
    # (for the directory itself and its '.' entry).
    if ( !$self->{'nlink'} ) {
        $self->{'nlink'} = ( $self->{'mode'} & S_IFMT ) == S_IFDIR ? 2 : 1;
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

    # Broken symlink: target doesn't exist → ENOENT
    if ( defined $file && defined BROKEN_SYMLINK && $file eq BROKEN_SYMLINK ) {
        $! = ENOENT;
        return 0;
    }

    # Circular symlink: too many levels of indirection → ELOOP
    if ( defined $file && defined CIRCULAR_SYMLINK && $file eq CIRCULAR_SYMLINK ) {
        $! = ELOOP;
        return 0;
    }

    if ( !defined $file or !length $file ) {
        _real_file_access_hook( $type, [$file_or_fh] );
        return FALLBACK_TO_REAL_OP();
    }

    my $file_data = _get_file_object($file);
    if ( !$file_data ) {
        $file_data = _maybe_autovivify($file);
    }
    if ( !$file_data ) {
        _real_file_access_hook( $type, [$file_or_fh] ) unless ref $file_or_fh;
        return FALLBACK_TO_REAL_OP();
    }

    # File is not present so no stats for you!
    if ( !$file_data->exists() ) {
        $! = ENOENT;
        return 0;
    }

    # Make sure the file size is correct in the stats before returning its contents.
    return [ $file_data->stat ];
}

sub _is_path_mocked {
    my ($file_path) = @_;
    my $absolute_path_to_file = _find_file_or_fh($file_path) or return;

    return $files_being_mocked{$absolute_path_to_file} ? 1 : 0;
}

sub _get_file_object {
    my ($file_path) = @_;

    my $file = _find_file_or_fh($file_path) or return;

    return $files_being_mocked{$file};
}

# Like _get_file_object but follows symlinks (for chmod, chown, utime, truncate).
# Returns BROKEN_SYMLINK or CIRCULAR_SYMLINK sentinels on symlink errors,
# the mock object on success, or undef if not mocked.
sub _get_file_object_follow_link {
    my ($file_path) = @_;

    my $resolved = _find_file_or_fh( $file_path, 1 );    # follow symlinks

    # Propagate symlink error sentinels
    return $resolved if ref $resolved && ( $resolved == BROKEN_SYMLINK || $resolved == CIRCULAR_SYMLINK );

    return unless $resolved;
    return $files_being_mocked{$resolved};
}

# Creates a file mock at the target of a broken symlink chain.
# Used when open/sysopen with a create-capable mode needs to create the target.
# The new mock is attached to the last symlink in the chain (which holds the
# strong ref) so it stays alive as long as the symlink mock does.
# Returns the absolute path of the newly created mock, or undef on failure.
sub _create_file_through_broken_symlink {
    my ($path) = @_;

    my $abs = _abs_path_to_file($path);
    return unless defined $abs;

    my $depth           = 0;
    my $last_link_abs;
    while ( my $mock = $files_being_mocked{$abs} ) {
        return unless $mock->is_link;    # Not a symlink — nothing to resolve
        $last_link_abs = $abs;
        my $target = $mock->readlink;
        return unless defined $target && length $target;
        $abs = _abs_path_to_file($target);
        return unless defined $abs;
        return if ++$depth > FOLLOW_LINK_MAX_DEPTH;    # Circular — give up
        last unless $files_being_mocked{$abs};          # Found the broken end
    }

    return unless $last_link_abs;                        # Original path wasn't a symlink

    # If autovivify can handle it, prefer that path
    my $mock = _maybe_autovivify($abs);
    return $abs if $mock;

    # Create a non-existent file mock at the target path
    $mock = _new_nonexistent_file_mock($abs);

    $files_being_mocked{$abs} = $mock;
    Scalar::Util::weaken( $files_being_mocked{$abs} );

    # The last symlink in the chain holds the strong ref
    my $symlink_mock = $files_being_mocked{$last_link_abs};
    $symlink_mock->{'_autovivified_children'} //= [];
    push @{ $symlink_mock->{'_autovivified_children'} }, $mock;

    return $abs;
}

# This subroutine finds the absolute path to a file, returning the absolute path of what it ultimately points to.
# If it is a broken link or what was passed in is undef or '', then we return undef.

sub _find_file_or_fh {
    my ( $file_or_fh, $follow_link, $depth ) = @_;

    # Find the file handle or fall back to just using the abs path of $file_or_fh
    my $absolute_path_to_file = _fh_to_file($file_or_fh) // _abs_path_to_file($file_or_fh) // '';
    $absolute_path_to_file ne '/'
      and $absolute_path_to_file =~ s{[/\\]$}{}xmsg;

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
        my $mock = $files_being_mocked{$path};

        # Check file handles (multiple handles per file)
        my $fhs = $mock->{'fhs'};
        if ( $fhs && @{$fhs} ) {
            @{$fhs} = grep { defined $_ } @{$fhs};
            foreach my $mock_fh ( @{$fhs} ) {
                return $path if "$mock_fh" eq "$fh";
            }
        }

        # Check dir handle (stored as stringified handle)
        if ( $mock->{'fh'} && $mock->{'fh'} eq "$fh" ) {
            return $path;
        }
    }

    return;
}

sub _files_in_dir {
    my $dirname = shift;

    $dirname = _abs_path_to_file($dirname) if defined $dirname && $dirname !~ m{^/};

    my @files_in_dir = @files_being_mocked{
        grep m{^\Q$dirname/\E},
        keys %files_being_mocked
    };

    return @files_in_dir;
}

# Walk up the path to find the nearest ancestor directory with autovivify enabled.
# Returns the mock object if found, undef otherwise.
sub _find_autovivify_parent {
    my ($abs_path) = @_;

    return unless %_autovivify_dirs;

    my $dir = $abs_path;
    while ( $dir =~ s{/[^/]+$}{} && length $dir ) {
        if ( my $mock = $_autovivify_dirs{$dir} ) {
            return $mock;
        }
    }

    return;
}

# If $abs_path is under an autovivify directory, create a non-existent file mock
# for it and return the mock. Otherwise return undef.
sub _maybe_autovivify {
    my ($abs_path) = @_;

    return unless defined $abs_path && length $abs_path;

    # Already mocked? Nothing to do.
    return $files_being_mocked{$abs_path} if $files_being_mocked{$abs_path};

    my $parent = _find_autovivify_parent($abs_path) or return;

    # Create a non-existent file mock (contents=undef means "not there yet")
    my $mock = _new_nonexistent_file_mock($abs_path);

    # Store in global hash (weak ref, as usual)
    $files_being_mocked{$abs_path} = $mock;
    Scalar::Util::weaken( $files_being_mocked{$abs_path} );

    # Parent holds the strong ref so it stays alive until parent is destroyed
    $parent->{'_autovivified_children'} //= [];
    push @{ $parent->{'_autovivified_children'} }, $mock;

    return $mock;
}

sub _abs_path_to_file {
    my ($path) = shift;

    return unless defined $path;

    # Tilde expansion must happen before making the path absolute
    # ~
    # ~/...
    # ~sawyer
    if ( $path =~ m{ ^(~ ([^/]+)? ) }xms ) {
        my $req_homedir = $1;
        my $username    = $2 || getpwuid($<);
        my $pw_homedir;

        # Reset iterator so we *definitely* start from the first one
        # Then reset when done looping over pw entries
        endpwent;
        while ( my @pwdata = getpwent ) {
            if ( $pwdata[0] eq $username ) {
                $pw_homedir = $pwdata[7];
                endpwent;
                last;
            }
        }
        endpwent;

        $pw_homedir
          or die;

        $path =~ s{\Q$req_homedir\E}{$pw_homedir};
    }

    # Make path absolute if relative
    if ( $path !~ m{^/}xms ) {
        $path = Cwd::getcwd() . "/$path";
    }

    # Resolve path components: remove ".", resolve "..", collapse slashes
    my @resolved;
    for my $part ( split m{/}, $path ) {
        next if $part eq '' || $part eq '.';
        if ( $part eq '..' ) {
            pop @resolved;
            next;
        }
        push @resolved, $part;
    }

    return '/' . join( '/', @resolved );
}

# Override for Cwd::abs_path / Cwd::realpath that resolves mocked symlinks.
# When a path (or any component of it) involves a mocked symlink, we resolve
# the symlinks ourselves. Otherwise, we delegate to the original implementation.

sub __cwd_abs_path {
    my ($path) = @_;
    $path = '.' unless defined $path && length $path;

    # Make absolute without collapsing .. (symlink-aware resolution does that)
    if ( $path !~ m{^/} ) {
        $path = Cwd::getcwd() . "/$path";
    }

    my @remaining = grep { $_ ne '' && $_ ne '.' } split( m{/}, $path );
    my $resolved      = '';
    my $depth         = 0;
    my $involves_mock = 0;

    while (@remaining) {
        my $component = shift @remaining;

        if ( $component eq '..' ) {
            $resolved =~ s{/[^/]+$}{};
            next;
        }

        my $candidate = "$resolved/$component";
        my $mock_obj  = $files_being_mocked{$candidate};

        if ( $mock_obj && $mock_obj->is_link ) {
            $involves_mock = 1;
            $depth++;
            if ( $depth > FOLLOW_LINK_MAX_DEPTH ) {
                $! = ELOOP;
                return undef;
            }

            my $target = $mock_obj->readlink;

            # Broken symlink: undefined or empty target
            return undef unless defined $target && length $target;

            my @target_parts = grep { $_ ne '' && $_ ne '.' } split( m{/}, $target );

            if ( $target =~ m{^/} ) {

                # Absolute target: restart from root
                $resolved = '';
            }

            # Relative target: stays at current $resolved
            unshift @remaining, @target_parts;
        }
        elsif ($mock_obj) {
            $involves_mock = 1;
            $resolved = $candidate;
        }
        else {
            $resolved = $candidate;
        }
    }

    # If no mocked paths were involved, delegate to original
    return $_original_cwd_abs_path->($path) unless $involves_mock;

    return $resolved || '/';
}

sub DESTROY {
    my ($self) = @_;
    ref $self or return;

    # This is just a safety. It doesn't make much sense if we get here but
    # $self doesn't have a path. Either way we can't delete it.
    my $path = $self->{'path'};
    defined $path or return;

    # Passthrough mocks are not in %files_being_mocked — just remove
    # the strict-mode rule that was created for them.
    if ( $self->{'_passthrough'} ) {
        my $rule = $self->{'_passthrough_rule'};
        @STRICT_RULES = grep { $_ != $rule } @STRICT_RULES if $rule;
        return;
    }

    # Clean up autovivify tracking
    delete $_autovivify_dirs{$path};

    # Destroy auto-vivified children (dropping strong refs triggers their DESTROY)
    if ( $self->{'_autovivified_children'} ) {
        delete $self->{'_autovivified_children'};
    }

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

Only retrieves the content of the directory (as an arrayref).  You can
set directory contents with calling the C<file()> method described
above.

Symlinks have no contents.

=cut

sub contents {
    my ( $self, $new_contents ) = @_;
    $self or confess;

    # Symlinks have no contents — return undef.
    return if $self->is_link;

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

            # strip directory from the path
            ( my $basename = $_->path() ) =~ s{^\Q$dirname/\E}{}xms;

            # Is this content within another directory? strip that out
            $basename =~ s{^( [^/]+ ) / .*}{$1}xms;

            $_->exists() ? ($basename) : ();
        } _files_in_dir($dirname);

        my %uniq;
        $uniq{$_}++ for @existing_files;
        return [ '.', '..', sort keys %uniq ];
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

=head2 read

Returns the contents of a mocked file. Dies if called on a directory
or symlink.

In scalar context, returns the entire file contents as a single string.
In list context, splits the contents into lines using C<$/> as the
input record separator (preserving the separator in each element),
consistent with Perl's C<readline> behavior.

Returns C<undef> in scalar context (or an empty list in list context)
if the file does not currently exist.

    my $bar  = Test::MockFile->file( '/foo/bar', "line1\nline2\n" );
    my $text = $bar->read;     # "line1\nline2\n"
    my @lines = $bar->read;    # ( "line1\n", "line2\n" )

=cut

sub read {
    my ($self) = @_;
    $self or confess("read is a method");

    $self->is_link
      and confess("read is not supported for symlinks");
    $self->is_dir
      and confess("read is not supported for directories");

    my $contents = $self->{'contents'};
    return $contents unless wantarray;

    return () unless defined $contents;

    # If $/ is undef, slurp mode — return single element
    return ($contents) unless defined $/;

    # Split keeping the separator, like readline
    my @lines;
    while ( length $contents ) {
        my $idx = index( $contents, $/ );
        if ( $idx == -1 ) {
            push @lines, $contents;
            last;
        }
        push @lines, substr( $contents, 0, $idx + length($/) );
        $contents = substr( $contents, $idx + length($/) );
    }
    return @lines;
}

=head2 write

Sets the contents of a mocked file. Dies if called on a directory
or symlink.

Multiple arguments are concatenated. If the file does not currently
exist, calling C<write> brings it into existence.

Returns the mock object for chaining.

    my $bar = Test::MockFile->file( '/foo/bar' );  # non-existent file
    $bar->write("hello world");                     # now exists
    $bar->write("line1\n", "line2\n");              # concatenated

=cut

sub write {
    my ( $self, @args ) = @_;
    $self or confess("write is a method");

    $self->is_link
      and confess("write is not supported for symlinks");
    $self->is_dir
      and confess("write is not supported for directories");

    my $data = join '', @args;
    $self->{'contents'} = $data;

    my $now = time;
    $self->{'mtime'} = $now;
    $self->{'ctime'} = $now;

    return $self;
}

=head2 append

Appends to the contents of a mocked file. Dies if called on a
directory or symlink.

Multiple arguments are concatenated before appending. If the file does
not currently exist, calling C<append> brings it into existence (as if
writing to an empty file).

Returns the mock object for chaining.

    my $bar = Test::MockFile->file( '/foo/bar', "first\n" );
    $bar->append("second\n");                        # "first\nsecond\n"
    $bar->append("third\n", "fourth\n");             # concatenated

=cut

sub append {
    my ( $self, @args ) = @_;
    $self or confess("append is a method");

    $self->is_link
      and confess("append is not supported for symlinks");
    $self->is_dir
      and confess("append is not supported for directories");

    my $data = join '', @args;

    $self->{'contents'} //= '';
    $self->{'contents'} .= $data;

    my $now = time;
    $self->{'mtime'} = $now;
    $self->{'ctime'} = $now;

    return $self;
}

=head2 filename

Deprecated. Same as C<path>.

=cut

sub filename {
    carp('filename() is deprecated, use path() instead');
    goto &path;
}

=head2 path

The path (filename or dirname) of the file or directory this mock
object is controlling.

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
        if ( $] < 5.019 && ( $^O eq 'darwin' or $^O =~ m/bsd/i or $^O eq 'solaris' ) ) {
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

    # Decrement nlink on this mock and any other hard links sharing the same inode
    if ( $self->{'nlink'} > 0 ) {
        my $inode = $self->{'inode'};
        if ( $inode && $self->{'nlink'} > 1 ) {
            for my $path ( keys %files_being_mocked ) {
                my $m = $files_being_mocked{$path};
                next if !$m || $m == $self;
                next if !$m->exists;
                if ( defined $m->{'inode'} && $m->{'inode'} == $inode ) {
                    $m->{'nlink'}-- if $m->{'nlink'} > 0;
                }
            }
        }
        $self->{'nlink'}--;
    }

    _update_parent_dir_times( $self->path );
    return 1;
}

=head2 touch

Optional Args: ($epoch_time)

This function acts like the UNIX utility touch. It sets atime, mtime,
ctime to $epoch_time.

If no arguments are passed, $epoch_time is set to time(). If the file
does not exist, contents are set to an empty string.

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

Returns the stat of a mocked file (does not follow symlinks.) You can
also use this to change what your symlink is pointing to.

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

    return ( ( $self->{'mode'} & S_IFMT ) == S_IFLNK ) ? 1 : 0;
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

    # Lstat for a symlink returns the length of the target path.
    return length( $self->{'readlink'} ) if $self->is_link;

    # Directories have a fixed size (typically one filesystem block).
    # Previously, length($arrayref) stringified the contents() return,
    # producing a nonsensical ~20-byte value.
    return $self->{'blksize'} if $self->is_dir;

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

    my $size    = $self->size;
    return 0 unless $size;

    my $blksize = abs( $self->{'blksize'} );
    return int( ( $size + $blksize - 1 ) / $blksize );
}

=head2 chmod

Optional Arg: $perms

Allows you to alter the permissions of a file. This only allows you to
change the C<07777> bits of the file permissions. The number passed
should be the octal C<0755> form, not the alphabetic C<"755"> form

=cut

sub chmod {
    my ( $self, $mode ) = @_;

    $mode = int($mode) & S_IFPERMS;

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

Returns and optionally sets the mtime of the file if passed as an
integer.

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

Returns and optionally sets the ctime of the file if passed as an
integer.

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

Returns and optionally sets the atime of the file if passed as an
integer.

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

You can use B<add_file_access_hook> to add a code ref that gets called
every time a real file (not mocked) operation happens. We use this for
strict mode to die if we detect your program is unexpectedly accessing
files. You are welcome to use it for whatever you like.

Whenever the code ref is called, we pass 2 arguments:
C<$code-E<gt>($access_type, $at_under_ref)>. Be aware that altering the
variables in C<$at_under_ref> will affect the variables passed to open
/ sysopen, etc.

One use might be:

    Test::MockFile::add_file_access_hook(sub { my $type = shift; print "$type called at: " . Carp::longmess() } );

=cut

sub add_file_access_hook {
    my ($code_ref) = @_;

    ( $code_ref && ref $code_ref eq 'CODE' ) or confess("add_file_access_hook needs to be passed a code reference.");
    push @_public_access_hooks, $code_ref;

    return 1;
}

=head2 clear_file_access_hooks

Calling this subroutine will clear everything that was passed to
B<add_file_access_hook>

=cut

sub clear_file_access_hooks {
    @_public_access_hooks = ();

    return 1;
}

# This code is called whenever an unmocked file is accessed. Any hooks that are setup get called from here.

sub _real_file_access_hook {
    my ( $access_type, $at_under_ref ) = @_;

    foreach my $code ( @_internal_access_hooks, @_public_access_hooks ) {
        $code->( $access_type, $at_under_ref );
    }

    return 1;
}

# Update the parent directory's mtime and ctime when its contents change.
# This mirrors real filesystem behavior: adding or removing entries in a
# directory updates the directory's mtime and ctime.
sub _update_parent_dir_times {
    my ($path) = @_;

    $path = _abs_path_to_file($path) if defined $path && $path !~ m{^/};

    ( my $dirname = $path ) =~ s{ / [^/]+ $ }{}xms;
    return unless length $dirname;

    my $parent = $files_being_mocked{$dirname};
    return unless $parent && $parent->is_dir();

    my $now = time;
    $parent->{'mtime'} = $now;
    $parent->{'ctime'} = $now;

    return 1;
}

sub _trace_hook {
    my ( $access_type, $at_under_ref ) = @_;

    my $file_arg = file_arg_position_for_command( $access_type, $at_under_ref );
    my $filename = ( $file_arg >= 0 && defined $at_under_ref->[$file_arg] ) ? $at_under_ref->[$file_arg] : '<unknown>';

    my @caller;
    foreach my $level ( 1 .. _STACK_ITERATION_MAX ) {
        @caller = caller($level);
        last if !@caller;
        next if $caller[0] eq __PACKAGE__;
        next if $caller[0] eq 'Overload::FileCheck';
        last;
    }

    my $location = @caller ? "$caller[1] line $caller[2]" : 'unknown';

    # Use print STDERR rather than warn to avoid triggering Test2::Plugin::NoWarnings
    print STDERR "[trace] $access_type('$filename') at $location\n";

    return;
}

=head2 How this mocking is done:

Test::MockFile uses 2 methods to mock file access:

=head3 -X via L<Overload::FileCheck>

It is currently not possible in pure perl to override
L<stat|http://perldoc.perl.org/functions/stat.html>,
L<lstat|http://perldoc.perl.org/functions/lstat.html> and L<-X
operators|http://perldoc.perl.org/functions/-X.html>. In conjunction
with this module, we've developed L<Overload::FileCheck>.

This enables us to intercept calls to stat, lstat and -X operators
(like -e, -f, -d, -s, etc.) and pass them to our control. If the file
is currently being mocked, we return the stat (or lstat) information on
the file to be used to determine the answer to whatever check was made.
This even works for things like C<-e _>. If we do not control the file
in question, we return C<FALLBACK_TO_REAL_OP()> which then makes a
normal check.

=head3 CORE::GLOBAL:: overrides

Since 5.10, it has been possible to override function calls by defining
them. like:

    *CORE::GLOBAL::open = sub(*;$@) {...}

Any code which is loaded B<AFTER> this happens will use the alternate
open. This means you can place your C<use Test::MockFile> statement
after statements you don't want to be mocked and there is no risk that
the code will ever be altered by Test::MockFile.

We oveload the following statements and then return tied handles to
enable the rest of the IO functions to work properly. Only B<open> /
B<sysopen> are needed to address file operations. However B<opendir>
file handles were never setup for tie so we have to override all of
B<opendir>'s related functions.

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

# goto messed up refcount between 5.22 and 5.26.
# Broken in 7bdb4ff0943cf93297712faf504cdd425426e57f
# Fixed  in https://rt.perl.org/Public/Bug/Display.html?id=115814
sub _goto_is_available {
    return 1 if $] < 5.021;
    return 1 if $] > 5.027;
    return 0;
}

################
# IO::File     #
################

# IO::File::open() uses CORE::open internally, which bypasses CORE::GLOBAL::open.
# This means IO::File->new($mocked_file) would NOT use the mock.
# Fix: override IO::File::open to check for mocked files first.

my $_orig_io_file_open;

sub _io_file_mock_open {
    my ( $fh, $abs_path, $mode ) = @_;
    my $mock_file = _get_file_object($abs_path);

    # Can't open a directory as a file
    if ( $mock_file->is_dir ) {
        $! = EISDIR;
        return;
    }

    # If contents is undef and reading, file doesn't exist
    if ( !defined $mock_file->contents() && grep { $mode eq $_ } qw/< +</ ) {
        $! = ENOENT;
        return;
    }

    my $rw = '';
    $rw .= 'r' if grep { $_ eq $mode } qw/+< +> +>> </;
    $rw .= 'w' if grep { $_ eq $mode } qw/+< +> +>> > >>/;
    $rw .= 'a' if grep { $_ eq $mode } qw/>> +>>/;

    # Permission check (GH #3)
    if ( defined $_mock_uid ) {
        if ( defined $mock_file->contents() ) {
            # Existing file: check file permissions
            my $need = 0;
            $need |= 4 if $rw =~ /r/;
            $need |= 2 if $rw =~ /w/;
            if ( !_check_perms( $mock_file, $need ) ) {
                $! = EACCES;
                _throw_autodie( 'open', @_ ) if _caller_has_autodie_for('open');
                return undef;
            }
        }
        elsif ( $rw =~ /w/ ) {
            # Creating new file: check parent dir write+execute
            if ( !_check_parent_perms( $abs_path, 2 | 1 ) ) {
                $! = EACCES;
                _throw_autodie( 'open', @_ ) if _caller_has_autodie_for('open');
                return undef;
            }
        }
    }

    # Tie the existing IO::File glob directly (don't create a new one)
    tie *{$fh}, 'Test::MockFile::FileHandle', $abs_path, $rw;

    # Track the handle
    $mock_file->{'fh'} = $fh;
    Scalar::Util::weaken( $mock_file->{'fh'} ) if ref $fh;

    # Handle append/truncate modes
    if ( $mode eq '>>' or $mode eq '+>>' ) {
        $mock_file->{'contents'} //= '';
        seek $fh, length( $mock_file->{'contents'} ), 0;
    }
    elsif ( $mode eq '>' or $mode eq '+>' ) {
        $mock_file->{'contents'} = '';
    }

    return 1;
}

sub _io_file_open_override {
    @_ >= 2 && @_ <= 4
      or croak('usage: $fh->open(FILENAME [,MODE [,PERMS]])');

    my $fh   = $_[0];
    my $file = $_[1];

    # Numeric mode (sysopen flags)
    if ( @_ > 2 && $_[2] =~ /^\d+$/ ) {
        my $sysmode = $_[2];
        my $abs_path = _find_file_or_fh( $file, 1 );
        my $mock_file;
        if ( $abs_path && !ref $abs_path ) {
            $mock_file = _get_file_object($abs_path);
        }

        if ( !$mock_file ) {
            # Not mocked — fall through to real sysopen
            my $perms = defined $_[3] ? $_[3] : 0666;
            return sysopen( $fh, $file, $sysmode, $perms );
        }

        # Can't open a directory as a file
        if ( $mock_file->is_dir ) {
            $! = EISDIR;
            return;
        }

        # Handle O_CREAT / O_TRUNC / O_EXCL on the mock
        if ( $sysmode & Fcntl::O_EXCL && $sysmode & Fcntl::O_CREAT && defined $mock_file->{'contents'} ) {
            $! = EEXIST;
            return;
        }
        if ( $sysmode & Fcntl::O_CREAT && !defined $mock_file->{'contents'} ) {
            $mock_file->{'contents'} = '';
        }
        if ( !defined $mock_file->{'contents'} ) {
            $! = ENOENT;
            return;
        }

        # Convert sysopen flags to string mode for _io_file_mock_open
        my $rd_wr = $sysmode & 3;
        my $mode =
            $rd_wr == Fcntl::O_RDONLY ? '<'
          : $rd_wr == Fcntl::O_WRONLY ? '>'
          : $rd_wr == Fcntl::O_RDWR   ? '+<'
          :                             '<';

        if ( $sysmode & Fcntl::O_TRUNC ) {
            $mock_file->{'contents'} = '';
        }
        if ( $sysmode & Fcntl::O_APPEND ) {
            $mode = '>>' if $rd_wr == Fcntl::O_WRONLY;
            $mode = '+>>' if $rd_wr == Fcntl::O_RDWR;
        }

        return _io_file_mock_open( $fh, $abs_path, $mode );
    }

    my $mode;
    if ( @_ > 2 ) {
        if ( $_[2] =~ /:/ ) {

            # IO layer mode like "<:utf8" — extract base mode
            if ( $_[2] =~ /^([+]?[<>]{1,2})/ ) {
                $mode = $1;
            }
            else {
                # Pure layer spec without mode prefix — default to read
                $mode = '<';
            }
        }
        else {
            $mode = IO::Handle::_open_mode_string( $_[2] );
        }
    }
    else {
        # 2-arg form: mode may be embedded in filename
        if ( $file =~ /^\s*(>>|[+]?[<>])\s*(.+)\s*$/ ) {
            $mode = $1;
            $file = $2;
        }
        else {
            $mode = '<';
        }
    }

    # Pipe opens — not mockable
    if ( $mode eq '|-' || $mode eq '-|' ) {
        goto &$_orig_io_file_open;
    }

    # Check if file is mocked
    my $abs_path = _find_file_or_fh( $file, 1 );
    if ( !$abs_path || ( ref $abs_path && ( $abs_path eq BROKEN_SYMLINK || $abs_path eq CIRCULAR_SYMLINK ) ) ) {
        goto &$_orig_io_file_open;
    }

    my $mock_file = _get_file_object($abs_path);
    if ( !$mock_file ) {
        goto &$_orig_io_file_open;
    }

    # File is mocked — handle via mock layer
    return _io_file_mock_open( $fh, $abs_path, $mode );
}

############
# KEYWORDS #
############

sub __glob {
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

    # In nostrict mode, also return real filesystem matches (issue #158).
    # In strict mode, only mocked files are visible — no real FS access.
    if ( !is_strict_mode() ) {
        my @real_results = File::Glob::bsd_glob($spec);

        # Merge real results, excluding any paths that are being mocked
        # (mocked paths take precedence whether they exist or not)
        my %seen = map { $_ => 1 } @results;
        foreach my $real_path (@real_results) {
            my $abs = _abs_path_to_file($real_path);
            next if $files_being_mocked{$abs};
            next if $seen{$real_path}++;
            push @results, $real_path;
        }
    }

    return sort @results;
}

sub __open (*;$@) {
    my $likely_bareword;
    my $arg0;
    if ( defined $_[0] && !ref $_[0] ) {

        # We need to remember the first arg to override the typeglob for barewords
        $arg0 = $_[0];
        ( $likely_bareword, @_ ) = _upgrade_barewords(@_);
    }

    # We need to take out the mode and file
    # but we must keep using $_[0] for the file-handle to update the caller
    my ( undef, $mode, $file ) = @_;
    my $arg_count = @_;

    # Normalize two-arg to three-arg
    if ( $arg_count == 2 ) {

        # The order here matters: try +>> and >> before +> and >
        if ( $_[1] =~ /^ ( [+]?>> | [+]?> | [+]?< ) (.+) $/xms ) {
            $mode = $1;
            $file = $2;
        }
        elsif ( $_[1] =~ /^\|/xms ) {
            $mode = '|-';
            $file = $_[1];
        }
        elsif ( $_[1] =~ /\|$/xms ) {
            $mode = '-|';
            $file = $_[1];
        }
        else {
            # Any filename without a mode prefix defaults to read.
            # This handles filenames with spaces, special chars, etc.
            $mode = '<';
            $file = $_[1];
        }

        # We have all args
        $arg_count++;
    }

    # We're not supporting 1 arg opens yet
    if ( $arg_count != 3 ) {
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
    if ( ref $file && ref $file eq 'SCALAR' ) {
        goto \&CORE::open if _goto_is_available();
        return CORE::open( $_[0], $mode, $file );
    }

    my $abs_path = _find_file_or_fh( $file, 1 );    # Follow the link.
    confess() if !$abs_path && $mode ne '|-' && $mode ne '-|';

    # Broken symlinks: write-capable modes create the target (like real FS),
    # read-only modes return ENOENT.
    # Circular symlinks → ELOOP (too many levels of symlinks).
    if ( $abs_path eq BROKEN_SYMLINK ) {
        my $base_mode = $mode;
        $base_mode =~ s/:.+$//;    # strip encoding suffix for mode check
        if ( grep { $base_mode eq $_ } qw/> >> +> +>>/ ) {
            my $target = _create_file_through_broken_symlink($file);
            if ($target) {
                $abs_path = $target;

                # Fall through — new mock will be found by _get_file_object below
            }
            else {
                $! = ENOENT;
                _maybe_throw_autodie( 'open', @_ );
                return undef;
            }
        }
        else {
            $! = ENOENT;
            _maybe_throw_autodie( 'open', @_ );
            return undef;
        }
    }
    if ( $abs_path eq CIRCULAR_SYMLINK ) {
        $! = ELOOP;
        _maybe_throw_autodie( 'open', @_ );
        return undef;
    }

    my $mock_file = _get_file_object($abs_path);

    # Try autovivify if not mocked
    if ( !$mock_file ) {
        $mock_file = _maybe_autovivify($abs_path);
    }

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

    # Directories cannot be opened as regular files.
    if ( $mock_file->is_dir() ) {
        $! = EISDIR;
        _maybe_throw_autodie( 'open', @_ );
        return undef;
    }

    # If contents is undef, we act like the file isn't there.
    if ( !defined $mock_file->contents() && grep { $mode eq $_ } qw/< +</ ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'open', @_ );
        return undef;
    }

    my $rw = '';
    $rw .= 'r' if grep { $_ eq $mode } qw/+< +> +>> </;
    $rw .= 'w' if grep { $_ eq $mode } qw/+< +> +>> > >>/;
    $rw .= 'a' if grep { $_ eq $mode } qw/>> +>>/;

    # Permission check (GH #3) — IO::File path must match __open
    if ( defined $_mock_uid ) {
        if ( defined $mock_file->contents() ) {
            my $need = 0;
            $need |= 4 if $rw =~ /r/;
            $need |= 2 if $rw =~ /w/;
            if ( !_check_perms( $mock_file, $need ) ) {
                $! = EACCES;
                _throw_autodie( 'open', @_ ) if _caller_has_autodie_for('open');
                return undef;
            }
        }
        elsif ( $rw =~ /w/ ) {
            if ( !_check_parent_perms( $abs_path, 2 | 1 ) ) {
                $! = EACCES;
                _throw_autodie( 'open', @_ ) if _caller_has_autodie_for('open');
                return undef;
            }
        }
    }

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

    # Track all open file handles for this mock (supports multiple handles to same file).
    $mock_file->{'fhs'} //= [];
    push @{ $mock_file->{'fhs'} }, $_[0];
    Scalar::Util::weaken( $mock_file->{'fhs'}[-1] ) if ref $_[0];

    # Fix tell based on open options.
    # Track whether this open creates the file (transitions from non-existent).
    my $was_new = !defined $mock_file->{'contents'};

    if ( $mode eq '>>' or $mode eq '+>>' ) {
        $mock_file->{'contents'} //= '';
        seek $_[0], length( $mock_file->{'contents'} ), 0;
    }
    elsif ( $mode eq '>' or $mode eq '+>' ) {
        $mock_file->{'contents'} = '';

        # Truncating an existing file updates mtime/ctime (like real truncate(2)).
        if ( !$was_new ) {
            my $now = time;
            $mock_file->{'mtime'} = $now;
            $mock_file->{'ctime'} = $now;
        }
    }

    # POSIX open(2): creating a new file sets atime, mtime, and ctime.
    if ( $was_new && defined $mock_file->{'contents'} ) {
        my $now = time;
        $mock_file->{'atime'} = $now;
        $mock_file->{'mtime'} = $now;
        $mock_file->{'ctime'} = $now;
    }

    # Creating a new file in a directory updates the directory's mtime.
    _update_parent_dir_times($abs_path) if $was_new && defined $mock_file->{'contents'};

    return 1;
}

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

sub __sysopen (*$$;$) {
    my $sysopen_mode = $_[2];

    # Resolve the path, following symlinks unless O_NOFOLLOW is set.
    my $mock_file;
    my $abs_path;
    if ( $sysopen_mode & O_NOFOLLOW ) {
        $mock_file = _get_file_object( $_[1] );
        if ( $mock_file && $mock_file->is_link ) {
            $! = ELOOP;
            _maybe_throw_autodie( 'sysopen', @_ );
            return undef;
        }
    }
    else {
        $abs_path = _find_file_or_fh( $_[1], 1 );
        if ( $abs_path && $abs_path eq BROKEN_SYMLINK ) {

            # O_CREAT through a broken symlink should create the target file
            if ( $sysopen_mode & O_CREAT ) {
                my $target = _create_file_through_broken_symlink( $_[1] );
                if ($target) {
                    $abs_path = $target;

                    # Fall through — new mock continues below
                }
                else {
                    $! = ENOENT;
                    _maybe_throw_autodie( 'sysopen', @_ );
                    return undef;
                }
            }
            else {
                $! = ENOENT;
                _maybe_throw_autodie( 'sysopen', @_ );
                return undef;
            }
        }
        if ( $abs_path && $abs_path eq CIRCULAR_SYMLINK ) {
            $! = ELOOP;
            _maybe_throw_autodie( 'sysopen', @_ );
            return undef;
        }
        $mock_file = $abs_path ? $files_being_mocked{$abs_path} : undef;
    }

    if ( !$mock_file ) {
        $mock_file = _maybe_autovivify( _abs_path_to_file( $_[1] ) );
    }

    if ( !$mock_file ) {
        _real_file_access_hook( "sysopen", \@_ );
        goto \&CORE::sysopen if _goto_is_available();
        return CORE::sysopen( $_[0], $_[1], @_[ 2 .. $#_ ] );
    }

    # Not supported by my linux vendor: O_EXLOCK | O_SHLOCK
    if ( ( $sysopen_mode & SUPPORTED_SYSOPEN_MODES ) != $sysopen_mode ) {
        confess( sprintf( "Sorry, can't open %s with 0x%x permissions. Some of your permissions are not yet supported by %s", $_[1], $sysopen_mode, __PACKAGE__ ) );
    }

    # Directories cannot be opened as regular files.
    if ( $mock_file->is_dir() ) {
        $! = EISDIR;
        _maybe_throw_autodie( 'sysopen', @_ );
        return undef;
    }

    # O_EXCL
    if ( $sysopen_mode & O_EXCL && $sysopen_mode & O_CREAT && defined $mock_file->{'contents'} ) {
        $! = EEXIST;
        _maybe_throw_autodie( 'sysopen', @_ );
        return undef;
    }

    # O_CREAT — POSIX open(2): creating a new file sets atime, mtime, and ctime.
    if ( $sysopen_mode & O_CREAT && !defined $mock_file->{'contents'} ) {
        $mock_file->{'contents'} = '';
        my $now = time;
        $mock_file->{'atime'} = $now;
        $mock_file->{'mtime'} = $now;
        $mock_file->{'ctime'} = $now;
        _update_parent_dir_times( $_[1] );

        # Apply permissions from sysopen's 4th argument (mode/mask)
        # On a real filesystem, sysopen(FH, $file, O_CREAT|..., $perms)
        # creates the file with permissions ($perms & ~umask).
        if ( defined $_[3] ) {
            my $perms = int( $_[3] ) & S_IFPERMS;
            $mock_file->{'mode'} = ( $perms & ~umask ) | S_IFREG;
        }
    }

    # O_TRUNC
    if ( $sysopen_mode & O_TRUNC && defined $mock_file->{'contents'} ) {
        $mock_file->{'contents'} = '';
        my $now = time;
        $mock_file->{'mtime'} = $now;
        $mock_file->{'ctime'} = $now;
    }

    my $rd_wr_mode = $sysopen_mode & 3;
    my $rw =
        $rd_wr_mode == O_RDONLY ? 'r'
      : $rd_wr_mode == O_WRONLY ? 'w'
      : $rd_wr_mode == O_RDWR   ? 'rw'
      :                           confess("Unexpected sysopen read/write mode ($rd_wr_mode)");    # O_WRONLY| O_RDWR mode makes no sense and we should die.

    $rw .= 'a' if $sysopen_mode & O_APPEND;

    # If contents is undef, we act like the file isn't there.
    # This applies to ALL modes (O_RDONLY, O_WRONLY, O_RDWR) when O_CREAT is not set.
    # O_CREAT would have already populated contents above if it was requested.
    if ( !defined $mock_file->{'contents'} ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'sysopen', @_ );
        return undef;
    }

    # Permission check (GH #3)
    if ( defined $_mock_uid ) {
        if ( defined $mock_file->{'contents'} ) {
            my $need = 0;
            $need |= 4 if $rw =~ /r/;
            $need |= 2 if $rw =~ /w/;
            if ( !_check_perms( $mock_file, $need ) ) {
                $! = EACCES;
                _throw_autodie( 'sysopen', @_ ) if _caller_has_autodie_for('sysopen');
                return undef;
            }
        }
        elsif ( $rw =~ /w/ ) {
            if ( !_check_parent_perms( $mock_file->{'path'}, 2 | 1 ) ) {
                $! = EACCES;
                _throw_autodie( 'sysopen', @_ ) if _caller_has_autodie_for('sysopen');
                return undef;
            }
        }
    }

    $abs_path //= $mock_file->{'path'};

    $_[0] = IO::File->new;
    tie *{ $_[0] }, 'Test::MockFile::FileHandle', $abs_path, $rw;

    # Track all open file handles for this mock (supports multiple handles to same file).
    $files_being_mocked{$abs_path}->{'fhs'} //= [];
    push @{ $files_being_mocked{$abs_path}->{'fhs'} }, $_[0];
    Scalar::Util::weaken( $files_being_mocked{$abs_path}->{'fhs'}[-1] ) if ref $_[0];

    # O_APPEND
    if ( $sysopen_mode & O_APPEND ) {
        seek $_[0], length $mock_file->{'contents'}, 0;
    }

    return 1;
}

sub __opendir (*$) {

    # Upgrade but ignore bareword indicator
    ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0] && !ref $_[0];

    # 1 arg Opendir doesn't work??
    if ( scalar @_ != 2 or !defined $_[1] ) {
        _real_file_access_hook( "opendir", \@_ );

        goto \&CORE::opendir if _goto_is_available();

        no strict 'refs';    ## no critic - bareword filehandles need symbolic refs
        return CORE::opendir( $_[0], @_[ 1 .. $#_ ] );
    }

    # Follow symlinks — opendir resolves symlinks like stat does
    my $abs_path = _find_file_or_fh( $_[1], 1 );

    if ( defined $abs_path && $abs_path eq BROKEN_SYMLINK ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'opendir', @_ );
        return undef;
    }

    if ( defined $abs_path && $abs_path eq CIRCULAR_SYMLINK ) {
        $! = ELOOP;
        _maybe_throw_autodie( 'opendir', @_ );
        return undef;
    }

    my $mock_dir = defined $abs_path ? $files_being_mocked{$abs_path} : undef;

    if ( !$mock_dir ) {
        _real_file_access_hook( "opendir", \@_ );
        goto \&CORE::opendir if _goto_is_available();
        no strict 'refs';    ## no critic - bareword filehandles need symbolic refs
        return CORE::opendir( $_[0], $_[1] );
    }

    if ( !defined $mock_dir->contents ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'opendir', @_ );
        return undef;
    }

    if ( !( $mock_dir->{'mode'} & S_IFDIR ) ) {
        $! = ENOTDIR;
        _maybe_throw_autodie( 'opendir', @_ );
        return undef;
    }

    # Permission check: opendir needs read permission on directory (GH #3)
    if ( defined $_mock_uid && !_check_perms( $mock_dir, 4 ) ) {
        $! = EACCES;
        _throw_autodie( 'opendir', @_ ) if _caller_has_autodie_for('opendir');
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
    # $abs_path already holds the resolved path from _find_file_or_fh above.
    $mock_dir->{'obj'} = Test::MockFile::DirHandle->new( $abs_path, $mock_dir->contents() );
    $mock_dir->{'fh'}  = "$_[0]";

    return 1;

}

sub __readdir (*) {

    # Upgrade but ignore bareword indicator
    ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0] && !ref $_[0];

    my $mocked_dir = _get_file_object( $_[0] );

    if ( !$mocked_dir ) {
        _real_file_access_hook( 'readdir', \@_ );
        goto \&CORE::readdir if _goto_is_available();
        no strict 'refs';    ## no critic - bareword filehandles need symbolic refs
        return CORE::readdir( $_[0] );
    }

    my $obj = $mocked_dir->{'obj'};
    if ( !$obj ) {
        warnings::warnif( 'io', "readdir() attempted on invalid dirhandle $_[0]" );
        return;
    }

    if ( !defined $obj->{'files_in_readdir'} ) {
        confess("Did a readdir on an empty dir. This shouldn't have been able to have been opened!");
    }

    if ( !defined $obj->{'tell'} ) {
        confess("readdir called on a closed dirhandle");
    }

    # At EOF for the dir handle.
    # Must use bare return (not "return undef") so list context gets ()
    # instead of (undef). Otherwise while(@e = readdir $dh) never terminates.
    return if $obj->{'tell'} > $#{ $obj->{'files_in_readdir'} };

    if (wantarray) {
        my @return;
        foreach my $pos ( $obj->{'tell'} .. $#{ $obj->{'files_in_readdir'} } ) {
            push @return, $obj->{'files_in_readdir'}->[$pos];
        }
        $obj->{'tell'} = $#{ $obj->{'files_in_readdir'} } + 1;
        return @return;
    }

    return $obj->{'files_in_readdir'}->[ $obj->{'tell'}++ ];
}

sub __telldir (*) {

    # Upgrade but ignore bareword indicator
    ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0] && !ref $_[0];

    my ($fh) = @_;
    my $mocked_dir = _get_file_object($fh);

    if ( !$mocked_dir ) {
        _real_file_access_hook( 'telldir', \@_ );
        goto \&CORE::telldir if _goto_is_available();
        no strict 'refs';    ## no critic - bareword filehandles need symbolic refs
        return CORE::telldir($fh);
    }

    if ( !$mocked_dir->{'obj'} ) {
        warnings::warnif( 'io', "telldir() attempted on invalid dirhandle $fh" );
        return undef;
    }

    my $obj = $mocked_dir->{'obj'};

    if ( !defined $obj->{'files_in_readdir'} ) {
        confess("Did a telldir on an empty dir. This shouldn't have been able to have been opened!");
    }

    if ( !defined $obj->{'tell'} ) {
        confess("telldir called on a closed dirhandle");
    }

    return $obj->{'tell'};
}

sub __rewinddir (*) {

    # Upgrade but ignore bareword indicator
    ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0] && !ref $_[0];

    my ($fh) = @_;
    my $mocked_dir = _get_file_object($fh);

    if ( !$mocked_dir ) {
        _real_file_access_hook( 'rewinddir', \@_ );
        goto \&CORE::rewinddir if _goto_is_available();
        no strict 'refs';    ## no critic - bareword filehandles need symbolic refs
        return CORE::rewinddir( $_[0] );
    }

    if ( !$mocked_dir->{'obj'} ) {
        warnings::warnif( 'io', "rewinddir() attempted on invalid dirhandle $fh" );
        return;
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
}

sub __seekdir (*$) {

    # Upgrade but ignore bareword indicator
    ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0] && !ref $_[0];

    my ( $fh, $goto ) = @_;
    my $mocked_dir = _get_file_object($fh);

    if ( !$mocked_dir ) {
        _real_file_access_hook( 'seekdir', \@_ );
        goto \&CORE::seekdir if _goto_is_available();
        no strict 'refs';    ## no critic - bareword filehandles need symbolic refs
        return CORE::seekdir( $fh, $goto );
    }

    if ( !$mocked_dir->{'obj'} ) {
        warnings::warnif( 'io', "seekdir() attempted on invalid dirhandle $fh" );
        return;
    }

    my $obj = $mocked_dir->{'obj'};

    if ( !defined $obj->{'files_in_readdir'} ) {
        confess("Did a seekdir on an empty dir. This shouldn't have been able to have been opened!");
    }

    if ( !defined $obj->{'tell'} ) {
        confess("seekdir called on a closed dirhandle");
    }

    # Clamp negative positions to 0.  POSIX says behavior is undefined for
    # invalid positions; without this guard, Perl's negative-array-indexing
    # causes readdir to return entries from the end of the list.
    $obj->{'tell'} = $goto < 0 ? 0 : $goto;
    return 1;
}

sub __closedir (*) {

    # Upgrade but ignore bareword indicator
    ( undef, @_ ) = _upgrade_barewords(@_) if defined $_[0] && !ref $_[0];

    my ($fh) = @_;
    my $mocked_dir = _get_file_object($fh);

    if ( !$mocked_dir ) {
        _real_file_access_hook( 'closedir', \@_ );
        goto \&CORE::closedir if _goto_is_available();
        no strict 'refs';    ## no critic - bareword filehandles need symbolic refs
        return CORE::closedir($fh);
    }

    # Already closed — warn and return EBADF like real closedir
    if ( !$mocked_dir->{'obj'} ) {
        warnings::warnif( 'io', "closedir() attempted on invalid dirhandle $fh" );
        $! = EBADF;
        _maybe_throw_autodie( 'closedir', @_ );
        return undef;
    }

    delete $mocked_dir->{'obj'};

    # Keep $mocked_dir->{'fh'} so double-close is detected as mock, not CORE

    return 1;
}

sub __unlink (@) {
    my @files_to_unlink = @_ ? @_ : ($_);
    my $files_deleted   = 0;

    foreach my $file (@files_to_unlink) {
        my $mock = _get_file_object($file);

        if ( !$mock ) {
            _real_file_access_hook( "unlink", [$file] );
            $files_deleted += CORE::unlink($file);
        }
        else {
            # Permission check: unlink needs write+execute on parent dir (GH #3)
            if ( defined $_mock_uid && !_check_parent_perms( $mock->{'path'}, 2 | 1 ) ) {
                $! = EACCES;
                next;
            }
            $files_deleted += $mock->unlink;
        }
    }

    if ( $files_deleted < scalar(@files_to_unlink) ) {
        _maybe_throw_autodie( 'unlink', @_ );
    }

    return $files_deleted;

}

sub __readlink (_) {
    my ($file) = @_;

    if ( !defined $file ) {
        carp('Use of uninitialized value in readlink');
        if ( $^O eq 'freebsd' ) {
            $! = EINVAL;
        }
        else {
            $! = ENOENT;
        }
        _maybe_throw_autodie( 'readlink', @_ );
        return undef;
    }

    my $mock_object = _get_file_object($file);
    if ( !$mock_object ) {
        _real_file_access_hook( 'readlink', \@_ );
        goto \&CORE::readlink if _goto_is_available();
        return CORE::readlink($file);
    }

    if ( !$mock_object->exists() ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'readlink', @_ );
        return undef;
    }

    if ( !$mock_object->is_link ) {
        $! = EINVAL;
        _maybe_throw_autodie( 'readlink', @_ );
        return undef;
    }
    return $mock_object->readlink;
}

sub __symlink ($$) {
    my ( $oldname, $newname ) = @_;

    if ( !defined $newname ) {
        carp('Use of uninitialized value in symlink');
        $! = ENOENT;
        _maybe_throw_autodie( 'symlink', @_ );
        return 0;
    }

    my $mock = _get_file_object($newname);

    if ( !$mock ) {
        _real_file_access_hook( 'symlink', \@_ );
        goto \&CORE::symlink if _goto_is_available();
        return CORE::symlink( $oldname, $newname );
    }

    if ( $mock->exists ) {
        $! = EEXIST;
        _maybe_throw_autodie( 'symlink', @_ );
        return 0;
    }

    # Convert the mock to a symlink pointing to $oldname
    $mock->{'readlink'} = $oldname;
    $mock->{'mode'}     = 07777 | S_IFLNK;

    # POSIX symlink(2): creating a symlink sets atime, mtime, and ctime.
    my $now = time;
    $mock->{'atime'} = $now;
    $mock->{'mtime'} = $now;
    $mock->{'ctime'} = $now;

    # Mark parent directory as having content and update timestamps
    ( my $dirname = $mock->{'path'} ) =~ s{ / [^/]+ $ }{}xms;
    if ( $files_being_mocked{$dirname} ) {
        $files_being_mocked{$dirname}{'has_content'} = 1;
    }
    _update_parent_dir_times($newname);

    return 1;
}

sub __link ($$) {
    my ( $oldname, $newname ) = @_;

    if ( !defined $oldname || !defined $newname ) {
        carp('Use of uninitialized value in link');
        $! = ENOENT;
        _maybe_throw_autodie( 'link', @_ );
        return 0;
    }

    my $old_mock = _get_file_object($oldname);
    my $new_mock = _get_file_object($newname);

    # Neither path is mocked - passthrough to real link
    if ( !$old_mock && !$new_mock ) {
        _real_file_access_hook( 'link', \@_ );
        goto \&CORE::link if _goto_is_available();
        return CORE::link( $oldname, $newname );
    }

    # Source must exist
    if ( !$old_mock || !$old_mock->exists ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'link', @_ );
        return 0;
    }

    # Cannot hard-link directories
    if ( $old_mock->is_dir ) {
        $! = EPERM;
        _maybe_throw_autodie( 'link', @_ );
        return 0;
    }

    # Follow symlinks on the source (link() follows symlinks)
    my $source_mock = $old_mock;
    if ( $old_mock->is_link ) {
        my $target_path = _find_file_or_fh( $oldname, 1 );    # follow_link=1
        if ( !defined $target_path || $target_path eq BROKEN_SYMLINK ) {
            $! = ENOENT;
            _maybe_throw_autodie( 'link', @_ );
            return 0;
        }
        if ( $target_path eq CIRCULAR_SYMLINK ) {
            $! = ELOOP;
            _throw_autodie( 'link', @_ ) if _caller_has_autodie_for('link');
            return 0;
        }
        $source_mock = $files_being_mocked{$target_path};
        if ( !$source_mock || !$source_mock->exists ) {
            $! = ENOENT;
            _maybe_throw_autodie( 'link', @_ );
            return 0;
        }
    }

    # Destination must be a pre-declared mock
    if ( !$new_mock ) {
        $! = EXDEV;
        _maybe_throw_autodie( 'link', @_ );
        return 0;
    }

    # Destination must not already exist
    if ( $new_mock->exists ) {
        $! = EEXIST;
        _maybe_throw_autodie( 'link', @_ );
        return 0;
    }

    # Copy file attributes from source to destination
    $new_mock->{'contents'}    = $source_mock->{'contents'};
    $new_mock->{'has_content'} = 1;
    $new_mock->{'mode'}        = $source_mock->{'mode'};
    $new_mock->{'uid'}         = $source_mock->{'uid'};
    $new_mock->{'gid'}         = $source_mock->{'gid'};
    $new_mock->{'inode'}       = $source_mock->{'inode'};
    $new_mock->{'dev'}         = $source_mock->{'dev'};

    # Update link counts — propagate to ALL same-inode mocks (mirrors unlink behavior)
    $source_mock->{'nlink'}++;
    $new_mock->{'nlink'} = $source_mock->{'nlink'};
    my $inode = $source_mock->{'inode'};
    if ($inode) {
        for my $path ( keys %files_being_mocked ) {
            my $m = $files_being_mocked{$path};
            next if !$m || $m == $source_mock || $m == $new_mock;
            next if !$m->exists;
            if ( defined $m->{'inode'} && $m->{'inode'} == $inode ) {
                $m->{'nlink'} = $source_mock->{'nlink'};
            }
        }
    }

    # Update ctime (inode change) on both
    my $now = time;
    $source_mock->{'ctime'} = $now;
    $new_mock->{'ctime'}    = $now;
    $new_mock->{'atime'}    = $source_mock->{'atime'};
    $new_mock->{'mtime'}    = $source_mock->{'mtime'};

    # Mark parent directory as having content and update timestamps
    ( my $dirname = $new_mock->{'path'} ) =~ s{ / [^/]+ $ }{}xms;
    if ( $files_being_mocked{$dirname} ) {
        $files_being_mocked{$dirname}{'has_content'} = 1;
    }
    _update_parent_dir_times($newname);

    return 1;
}

# $file is always passed because of the prototype.
sub __mkdir (_;$) {
    my ( $file, $perms ) = @_;

    $perms = ( $perms // 0777 ) & S_IFPERMS;

    if ( !defined $file ) {

        # mkdir warns if $file is undef
        carp("Use of uninitialized value in mkdir");
        $! = ENOENT;
        _maybe_throw_autodie( 'mkdir', @_ );
        return 0;
    }

    my $mock = _get_file_object($file);

    if ( !$mock ) {
        $mock = _maybe_autovivify( _abs_path_to_file($file) );
    }

    if ( !$mock ) {
        _real_file_access_hook( 'mkdir', \@_ );
        goto \&CORE::mkdir if _goto_is_available();
        return CORE::mkdir(@_);
    }

    # Permission check: mkdir needs write+execute on parent dir (GH #3)
    if ( defined $_mock_uid && !_check_parent_perms( $mock->{'path'}, 2 | 1 ) ) {
        $! = EACCES;
        _throw_autodie( 'mkdir', @_ ) if _caller_has_autodie_for('mkdir');
        return 0;
    }

    # File or directory, this exists and should fail
    if ( $mock->exists ) {
        $! = EEXIST;
        _maybe_throw_autodie( 'mkdir', @_ );
        return 0;
    }

    # If the mock was a symlink or a file, we've just made it a dir.
    $mock->{'mode'} = ( $perms & ~umask ) | S_IFDIR;
    $mock->{'nlink'} = 2;    # directories have nlink=2 (self + '.')
    delete $mock->{'readlink'};

    # This should now start returning content
    $mock->{'has_content'} = 1;

    # POSIX mkdir(2): the new directory's timestamps are set to the current time.
    my $now = time;
    $mock->{'atime'} = $now;
    $mock->{'mtime'} = $now;
    $mock->{'ctime'} = $now;

    _update_parent_dir_times($file);
    return 1;
}

# $file is always passed because of the prototype.
sub __rmdir (_) {
    my ($file) = @_;

    # technically this is a minor variation from core. We don't seem to be able to
    # detect when they didn't pass an arg like core can.
    # Core sometimes warns: 'Use of uninitialized value $_ in rmdir'
    if ( !defined $file ) {
        carp('Use of uninitialized value in rmdir');
        $! = ENOENT;
        _maybe_throw_autodie( 'rmdir', @_ );
        return 0;
    }

    my $mock = _get_file_object($file);

    if ( !$mock ) {
        _real_file_access_hook( 'rmdir', \@_ );
        goto \&CORE::rmdir if _goto_is_available();
        return CORE::rmdir($file);
    }

    # Because we've mocked this to be a file and it doesn't exist we are going to die here.
    # The tester needs to fix this presumably.
    if ( $mock->exists ) {
        if ( $mock->is_file ) {
            $! = ENOTDIR;
            _maybe_throw_autodie( 'rmdir', @_ );
            return 0;
        }

        if ( $mock->is_link ) {
            $! = ENOTDIR;
            _maybe_throw_autodie( 'rmdir', @_ );
            return 0;
        }
    }

    if ( !$mock->exists ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'rmdir', @_ );
        return 0;
    }

    # Permission check: rmdir needs write+execute on parent dir (GH #3)
    if ( defined $_mock_uid && !_check_parent_perms( $mock->{'path'}, 2 | 1 ) ) {
        $! = EACCES;
        _throw_autodie( 'rmdir', @_ ) if _caller_has_autodie_for('rmdir');
        return 0;
    }

    if ( grep { $_->exists } _files_in_dir($file) ) {
        $! = ENOTEMPTY;
        _maybe_throw_autodie( 'rmdir', @_ );
        return 0;
    }

    $mock->{'has_content'} = undef;

    _update_parent_dir_times($file);
    return 1;
}

sub __rename ($$) {
    my ( $old, $new ) = @_;

    my $mock_old = _get_file_object($old);
    my $mock_new = _get_file_object($new);

    # Try autovivify for paths under mocked directories
    if ( !$mock_old ) {
        $mock_old = _maybe_autovivify( _abs_path_to_file($old) );
    }
    if ( !$mock_new ) {
        $mock_new = _maybe_autovivify( _abs_path_to_file($new) );
    }

    # If neither is mocked, pass through to real FS
    if ( !$mock_old && !$mock_new ) {
        _real_file_access_hook( 'rename', \@_ );
        goto \&CORE::rename if _goto_is_available();
        return CORE::rename( $old, $new );
    }

    # Can't rename between mocked and real filesystem
    if ( !$mock_old || !$mock_new ) {
        confess("rename: Cannot rename between mocked and real filesystem");
    }

    # Source must exist
    if ( !$mock_old->exists ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'rename', @_ );
        return 0;
    }

    # Renaming to self is a no-op (POSIX rename(2))
    return 1 if $mock_old == $mock_new;

    # Can't overwrite a directory with a non-directory
    if ( $mock_new->exists && $mock_new->is_dir && !$mock_old->is_dir ) {
        $! = EISDIR;
        _maybe_throw_autodie( 'rename', @_ );
        return 0;
    }

    # Can't overwrite a file with a directory
    if ( $mock_old->is_dir && $mock_new->exists && !$mock_new->is_dir ) {
        $! = ENOTDIR;
        _maybe_throw_autodie( 'rename', @_ );
        return 0;
    }

    # Can't overwrite a non-empty directory (POSIX rename(2))
    if ( $mock_old->is_dir && $mock_new->exists && $mock_new->is_dir ) {
        if ( grep { $_->exists } _files_in_dir( $mock_new->{'path'} ) ) {
            $! = ENOTEMPTY;
            _throw_autodie( 'rename', @_ ) if _caller_has_autodie_for('rename');
            return 0;
        }
    }

    # Move state from old to new
    if ( $mock_old->is_link ) {
        delete $mock_new->{'contents'};
        delete $mock_new->{'has_content'};
        $mock_new->{'readlink'} = $mock_old->{'readlink'};
        $mock_old->{'readlink'} = undef;
    }
    elsif ( $mock_old->is_dir ) {
        delete $mock_new->{'contents'};
        delete $mock_new->{'readlink'};
        $mock_new->{'has_content'} = $mock_old->{'has_content'};
        $mock_old->{'has_content'} = undef;

        # Transfer autovivify settings from old dir to new dir
        if ( $mock_old->{'autovivify'} ) {
            $mock_new->{'autovivify'} = delete $mock_old->{'autovivify'};
            delete $_autovivify_dirs{ $mock_old->{'path'} };
            $_autovivify_dirs{ $mock_new->{'path'} } = $mock_new;
            Scalar::Util::weaken( $_autovivify_dirs{ $mock_new->{'path'} } );
        }

        # Transfer ownership of autovivified children
        if ( $mock_old->{'_autovivified_children'} ) {
            $mock_new->{'_autovivified_children'} = delete $mock_old->{'_autovivified_children'};
        }

        # Re-key all children from old path prefix to new path prefix
        # in %files_being_mocked (and %_autovivify_dirs if applicable).
        # This ensures files under the renamed directory remain accessible.
        my $old_prefix = $mock_old->{'path'};
        my $new_prefix = $mock_new->{'path'};
        for my $key ( grep { m{^\Q$old_prefix/\E} } keys %files_being_mocked ) {
            my $child = $files_being_mocked{$key};
            ( my $new_key = $key ) =~ s{^\Q$old_prefix/\E}{$new_prefix/};

            delete $files_being_mocked{$key};
            $files_being_mocked{$new_key} = $child;
            $child->{'path'} = $new_key;

            # Update autovivify tracking for child directories
            if ( $_autovivify_dirs{$key} ) {
                $_autovivify_dirs{$new_key} = delete $_autovivify_dirs{$key};
            }
        }
    }
    else {
        delete $mock_new->{'readlink'};
        delete $mock_new->{'has_content'};
        $mock_new->{'contents'} = $mock_old->{'contents'};
        $mock_old->{'contents'} = undef;
    }

    # Copy mode, ownership, and inode metadata
    $mock_new->{'mode'}  = $mock_old->{'mode'};
    $mock_new->{'uid'}   = $mock_old->{'uid'};
    $mock_new->{'gid'}   = $mock_old->{'gid'};
    $mock_new->{'inode'} = $mock_old->{'inode'};
    $mock_new->{'nlink'} = $mock_old->{'nlink'};
    $mock_new->{'mtime'} = $mock_old->{'mtime'};
    $mock_new->{'atime'} = $mock_old->{'atime'};

    # rename updates ctime on both source and destination
    my $now = time;
    $mock_new->{'ctime'} = $now;
    $mock_old->{'ctime'} = $now;

    # Update parent directory timestamps (old dir loses entry, new dir gains entry)
    _update_parent_dir_times($old);
    _update_parent_dir_times($new);

    return 1;
}

sub __chown (@) {
    my ( $uid, $gid, @files ) = @_;

    $^O eq 'MSWin32'
      and return 0;    # does nothing on Windows

    # Not an error, report we changed zero files
    @files
      or return 0;

    # Follow symlinks: chown operates on the target, not the symlink itself
    my %mocked_files   = map +( $_ => _get_file_object_follow_link($_) ), @files;
    my @unmocked_files = grep !$mocked_files{$_}, @files;
    my @mocked_files   = map { ref $_ && ref $_ ne 'A::BROKEN::SYMLINK' && ref $_ ne 'A::CIRCULAR::SYMLINK' ? $_->{'path'} : () } values %mocked_files;

    # The idea is that if some are mocked and some are not,
    # it's probably a mistake.  Broken/circular symlinks are mocked paths
    # (handled per-file below), so they don't count as unmocked.
    if ( @mocked_files && @unmocked_files ) {
        confess(
            sprintf 'You called chown() on a mix of mocked (%s) and unmocked files (%s) ' . ' - this is very likely a bug on your side',
            ( join ', ', @mocked_files ),
            ( join ', ', @unmocked_files ),
        );
    }

    # Permission check uses the actual target uid/gid (not -1).
    # Use mock user identity if set, otherwise real process credentials (GH #3)
    my $eff_uid  = defined $_mock_uid ? $_mock_uid : $>;
    my $eff_gids = defined $_mock_uid ? join( ' ', @_mock_gids ) : $);

    # -1 means "keep as is" and is handled per-file below.
    my $target_uid = $uid == -1 ? $eff_uid : $uid;
    my ($primary_gid) = split /\s/, $eff_gids;
    my $target_gid = $gid == -1 ? $primary_gid : $gid;

    my $is_root     = $eff_uid == 0 || $eff_gids =~ /( ^ | \s ) 0 ( \s | $)/xms;
    my $is_in_group = grep /(^ | \s ) \Q$target_gid\E ( \s | $ )/xms, $eff_gids;

    # Only check permissions once (before the loop), not per-file.
    # -1 means "keep as is" — no permission needed for unchanged fields.
    # POSIX: non-root cannot change uid; can only change gid to a group they belong to.
    if ( !$is_root ) {
        if ( $uid != -1 && $eff_uid != $target_uid ) {
            $! = EPERM;
            _maybe_throw_autodie( 'chown', @_ );
            return 0;
        }
        if ( $gid != -1 && !$is_in_group ) {
            $! = EPERM;
            _maybe_throw_autodie( 'chown', @_ );
            return 0;
        }
    }

    my $num_changed = 0;
    foreach my $file (@files) {
        my $mock = $mocked_files{$file};

        # If this file is not mocked, none of the files are
        # which means we can send them all and let the CORE function handle it
        if ( !$mock ) {
            _real_file_access_hook( 'chown', \@_ );
            goto \&CORE::chown if _goto_is_available();
            return CORE::chown( $uid, $gid, @files );
        }

        # Handle broken/circular symlink errors
        if ( ref $mock eq 'A::BROKEN::SYMLINK' ) {
            $! = ENOENT;
            next;
        }
        if ( ref $mock eq 'A::CIRCULAR::SYMLINK' ) {
            $! = ELOOP;
            next;
        }

        # Even if you're root, nonexistent file is nonexistent
        if ( !$mock->exists() ) {
            $! = ENOENT;
            next;
        }

        # -1 means "keep as is" — preserve the file's current value
        $mock->{'uid'} = $uid == -1 ? $mock->{'uid'} : $uid;
        $mock->{'gid'} = $gid == -1 ? $mock->{'gid'} : $gid;
        $mock->{'ctime'} = time;

        $num_changed++;
    }

    if ( $num_changed < scalar(@files) ) {
        _maybe_throw_autodie( 'chown', @_ );
    }

    return $num_changed;
}

sub __chmod (@) {
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

    # Follow symlinks: chmod operates on the target, not the symlink itself
    my %mocked_files   = map +( $_ => _get_file_object_follow_link($_) ), @files;
    my @unmocked_files = grep !$mocked_files{$_}, @files;
    my @mocked_files   = map { ref $_ && ref $_ ne 'A::BROKEN::SYMLINK' && ref $_ ne 'A::CIRCULAR::SYMLINK' ? $_->{'path'} : () } values %mocked_files;

    # The idea is that if some are mocked and some are not,
    # it's probably a mistake.  Broken/circular symlinks are mocked paths
    # (handled per-file below), so they don't count as unmocked.
    if ( @mocked_files && @unmocked_files ) {
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
            return CORE::chmod( $mode, @files );
        }

        # Handle broken/circular symlink errors
        if ( ref $mock eq 'A::BROKEN::SYMLINK' ) {
            $! = ENOENT;
            next;
        }
        if ( ref $mock eq 'A::CIRCULAR::SYMLINK' ) {
            $! = ELOOP;
            next;
        }

        # chmod is less specific in such errors
        # chmod $mode, '/foo/' still yields ENOENT
        if ( !$mock->exists() ) {
            $! = ENOENT;
            next;
        }

        # Permission check: only owner or root can chmod (GH #3)
        if ( defined $_mock_uid && $_mock_uid != 0 && $_mock_uid != $mock->{'uid'} ) {
            $! = EPERM;
            next;
        }

        $mock->{'mode'} = ( $mock->{'mode'} & S_IFMT ) | ( $mode & S_IFPERMS );
        $mock->{'ctime'} = time;

        $num_changed++;
    }

    if ( $num_changed < scalar(@files) ) {
        _maybe_throw_autodie( 'chmod', @_ );
    }

    return $num_changed;
}

sub __flock (*$) {
    my ( $fh, $operation ) = @_;

    my $mock = _get_file_object($fh);
    if ($mock) {

        # Mocked files have no real file descriptor, so flock cannot
        # operate on them.  In a test context, the lock always succeeds.
        return 1;
    }

    # Not a mocked file — delegate to the real flock.
    _real_file_access_hook( 'flock', \@_ );
    goto \&CORE::flock if _goto_is_available();
    return CORE::flock( $fh, $operation );
}

sub __utime (@) {
    my ( $atime, $mtime, @files ) = @_;

    # Not an error, report we changed zero files
    @files
      or return 0;

    # Follow symlinks: utime operates on the target, not the symlink itself
    my %mocked_files   = map +( $_ => _get_file_object_follow_link($_) ), @files;
    my @unmocked_files = grep !$mocked_files{$_}, @files;

    # If no files are mocked, fall through to the real utime
    if ( @unmocked_files == @files ) {
        _real_file_access_hook( 'utime', \@_ );
        goto \&CORE::utime if _goto_is_available();
        return CORE::utime( $atime, $mtime, @files );
    }

    # Handle unmocked files via CORE::utime before processing mocks
    my $num_changed = 0;
    if (@unmocked_files) {
        $num_changed += CORE::utime( $atime, $mtime, @unmocked_files );
    }

    my $now = time;
    foreach my $file (@files) {
        my $mock = $mocked_files{$file}
          or next;    # unmocked — already handled above

        # Handle broken/circular symlink errors
        if ( ref $mock eq 'A::BROKEN::SYMLINK' ) {
            $! = ENOENT;
            next;
        }
        if ( ref $mock eq 'A::CIRCULAR::SYMLINK' ) {
            $! = ELOOP;
            next;
        }

        # The virtual file may not exist (e.g., file('/path', undef)).
        if ( !$mock->exists() ) {
            $! = ENOENT;
            next;
        }

        $mock->{'atime'} = defined $atime ? $atime : $now;
        $mock->{'mtime'} = defined $mtime ? $mtime : $now;
        $mock->{'ctime'} = $now;

        $num_changed++;
    }

    if ( $num_changed < scalar(@files) ) {
        _maybe_throw_autodie( 'utime', @_ );
    }

    return $num_changed;
}

sub __truncate ($$) {
    my ( $file_or_fh, $length ) = @_;

    # Follow symlinks: truncate operates on the target, not the symlink itself
    my $mock = _get_file_object_follow_link($file_or_fh);

    if ( !$mock ) {
        _real_file_access_hook( 'truncate', \@_ );
        return CORE::truncate( $file_or_fh, $length );
    }

    # Handle broken/circular symlink errors
    if ( ref $mock eq 'A::BROKEN::SYMLINK' ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'truncate', @_ );
        return 0;
    }
    if ( ref $mock eq 'A::CIRCULAR::SYMLINK' ) {
        $! = ELOOP;
        _maybe_throw_autodie( 'truncate', @_ );
        return 0;
    }

    if ( $mock->is_dir() ) {
        $! = EISDIR;
        _maybe_throw_autodie( 'truncate', @_ );
        return 0;
    }

    if ( !$mock->exists() ) {
        $! = ENOENT;
        _maybe_throw_autodie( 'truncate', @_ );
        return 0;
    }

    # When called with a filehandle, the handle must be open for writing.
    # POSIX ftruncate(2): EINVAL if fd is not open for writing.
    if ( ref $file_or_fh ) {
        my $tied = tied( *{$file_or_fh} );
        if ( $tied && !$tied->{'write'} ) {
            $! = EINVAL;
            _maybe_throw_autodie( 'truncate', @_ );
            return 0;
        }
    }

    if ( $length < 0 ) {
        $! = EINVAL;
        _maybe_throw_autodie( 'truncate', @_ );
        return 0;
    }

    my $contents = $mock->contents() // '';
    my $cur_len  = length $contents;

    if ( $length < $cur_len ) {
        $contents = substr( $contents, 0, $length );
    }
    elsif ( $length > $cur_len ) {
        $contents .= "\0" x ( $length - $cur_len );
    }

    $mock->contents($contents);

    # POSIX truncate(2): marks mtime and ctime for update
    my $now = time;
    $mock->{'mtime'} = $now;
    $mock->{'ctime'} = $now;

    return 1;
}

BEGIN {
    no warnings 'redefine';
    *CORE::GLOBAL::glob = !$^V || $^V lt 5.18.0
      ? sub {
        pop;
        goto &__glob;
      }
      : sub (_;) { goto &__glob; };

    *CORE::GLOBAL::open      = \&__open;
    *CORE::GLOBAL::sysopen   = \&__sysopen;
    *CORE::GLOBAL::opendir   = \&__opendir;
    *CORE::GLOBAL::readdir   = \&__readdir;
    *CORE::GLOBAL::telldir   = \&__telldir;
    *CORE::GLOBAL::rewinddir = \&__rewinddir;
    *CORE::GLOBAL::seekdir   = \&__seekdir;
    *CORE::GLOBAL::closedir  = \&__closedir;
    *CORE::GLOBAL::unlink    = \&__unlink;
    *CORE::GLOBAL::readlink  = \&__readlink;
    *CORE::GLOBAL::symlink   = \&__symlink;
    *CORE::GLOBAL::link      = \&__link;
    *CORE::GLOBAL::mkdir     = \&__mkdir;

    *CORE::GLOBAL::rename = \&__rename;
    *CORE::GLOBAL::rmdir  = \&__rmdir;
    *CORE::GLOBAL::chown = \&__chown;
    *CORE::GLOBAL::chmod = \&__chmod;
    *CORE::GLOBAL::flock    = \&__flock;
    *CORE::GLOBAL::utime    = \&__utime;
    *CORE::GLOBAL::truncate = \&__truncate;

    # Override Cwd functions to resolve mocked symlinks (GH #139)
    $_original_cwd_abs_path = \&Cwd::abs_path;
    {
        no warnings 'redefine';
        *Cwd::abs_path      = \&__cwd_abs_path;
        *Cwd::realpath      = \&__cwd_abs_path;
        *Cwd::fast_abs_path = \&__cwd_abs_path;
        *Cwd::fast_realpath = \&__cwd_abs_path;
    }

    # Override IO::File::open to intercept mocked files.
    # IO::File uses CORE::open internally which bypasses CORE::GLOBAL::open.
    $_orig_io_file_open = \&IO::File::open;
    {
        no warnings 'redefine';
        *IO::File::open = \&_io_file_open_override;
    }
}

=head1 CAVEATS AND LIMITATIONS

=head2 DEBUGGER UNDER STRICT MODE

If you want to use the Perl debugger (L<perldebug>) on any code that
uses L<Test::MockFile> in strict mode, you will need to load
L<Term::ReadLine> beforehand, because it loads a file. Under the
debugger, the debugger will load the module after L<Test::MockFile> and
get mad.

    # Load it from the command line
    perl -MTerm::ReadLine -d code.pl

    # Or alternatively, add this to the top of your code:
    use Term::ReadLine

=head2 HARD LINKS

The C<link()> override copies file contents and metadata from the
source to the destination mock. However, unlike real hard links,
writes to one file will B<not> be reflected in the other. The
C<nlink> count is incremented on both files.

The destination path must be a pre-declared mock (via C<file()> or
C<dir()>). Attempting to C<link()> a mocked source to an unmocked
destination will fail with C<EXDEV>.

=head2 FILENO IS UNSUPPORTED

Filehandles can provide the file descriptor (in number) using the
C<fileno> keyword but this is purposefully unsupported in
L<Test::MockFile>.

The reason is that by mocking a file, we're creating an alternative
file system. Returning a C<fileno> (file descriptor number) would
require creating file descriptor numbers that would possibly conflict
with the file descriptors you receive from the real filesystem.

In short, this is a recipe for buggy tests or worse - truly destructive
behavior. If you have a need for a real file, we suggest L<File::Temp>.

=head2 BAREWORD FILEHANDLE FAILURES

There is a particular type of bareword filehandle failures that cannot
be fixed.

These errors occur because there's compile-time code that uses bareword
filehandles in a function call that cannot be expressed by this
module's prototypes for core functions.

The only solution to these is loading `Test::MockFile` after the other
code:

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

Please report any bugs or feature requests to
L<https://github.com/cpanel/Test-MockFile>.

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

Thanks to Nicolas R., C<< <atoomic at cpan.org> >> for help with
L<Overload::FileCheck>. This module could not have been completed
without it.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 cPanel L.L.C.

All rights reserved.

L<http://cpanel.net>

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

1;    # End of Test::MockFile
