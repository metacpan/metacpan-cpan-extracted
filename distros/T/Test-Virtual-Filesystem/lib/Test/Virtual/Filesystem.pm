#######################################################################
#      $URL: svn+ssh://equilibrious@equilibrious.net/home/equilibrious/svnrepos/chrisdolan/Test-Virtual-Filesystem/lib/Test/Virtual/Filesystem.pm $
#     $Date: 2008-07-27 21:28:05 -0500 (Sun, 27 Jul 2008) $
#   $Author: equilibrious $
# $Revision: 785 $
########################################################################

package Test::Virtual::Filesystem;

use warnings;
use strict;
use 5.008;

use English qw(-no_match_vars);
use Carp qw(croak);
use File::Spec;
use List::MoreUtils qw(any);
use Attribute::Handlers;
use Config;
use POSIX qw(:errno_h strerror);
use Readonly;
use Test::More;
use base 'Test::Class';

our $VERSION = '0.13';

Readonly::Scalar my $TIME_LENIENCE => 2; # seconds of tolerance between CPU clock and disk mtime

# Currently this must not nest more than one level deep!
# (due to implementation of deep copy in new() and the static accessor/mutator constructor)
Readonly::Hash my %feature_defaults => (
      xattr => 0,
      time => {
         atime => 0,
         mtime => 1,
         ctime => 1,
      },
      permissions => 0,
      special => {
         fifo => 0,
      },
      symlink => 1,
      hardlink => {
         nlink => 1,
      },
      chown => 0,
);

# if true, the feature is disabled no matter what.  For example, most versions
# of Windows at this writing do not support symlinks at all, regardless of
# whether your virtual filesystem supports them
Readonly::Hash my %feature_disabled => (
   $Config{d_symlink} ? () : (symlink => 1),
   $Config{d_chown} ? () : (chown => 1),
   eval {require File::ExtAttr; 1;} ? () : (xattr => 1),
);

=pod

=for stopwords TODO CPAN MSWin32

=head1 NAME

Test::Virtual::Filesystem - Validate a filesystem

=head1 SYNOPSIS

    use Test::Virtual::Filesystem;
    Test::Virtual::Filesystem->new({mountdir => '/path/to/test'})->runtests;

or with more customization:

    use Test::Virtual::Filesystem;
    my $test = Test::Virtual::Filesystem->new({mountdir => '/path/to/test', compatible => '0.03'});
    $test->enable_test_xattr(1);
    $test->enable_test_chown(1);
    $test->enable_test_atime(1);
    $test->runtests;

See the file F<t/filesys.t> in this distribution or the file F<t/fusepdf.t> in
the L<Fuse::PDF> distribution for thorough examples.

WARNING: all of the files in the C<mountdir> will be deleted in the C<teardown>
method so BE CAREFUL that you specify the right folder!

=head1 LICENSE

Copyright 2008 Chris Dolan, I<cdolan@cpan.org>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DESCRIPTION

If you are creating a filesystem, say via L<Fuse> or L<Filesys::Virtual>, you
need a fairly mundane set of tests to try out lots of typical filesystem
operations.  This package attempts to accumulate a bunch of those tests into a
handy suite to make it easier for you to test your filesystem.

This suite is based on C<Test::Class>, a fantastic library for organizing
tests into bite-sized bundles.  The power of Test::Class lets you select a
subset of tests to run at author time.  For example, when I was working on the
extended attribute (aka C<xattr>) tests, I found myself typing this:

  env TEST_METHOD='xattr_.*' perl -Ilib t/filesys.t

which runs just the test methods that begin with C<xattr_>.

There are several methods that let you turn on or off a subset of the tests.
For example, if you do not intend that your filesystem will support symbolic
links, you can invoke C<$test->enable_test_symlink(0)> in your test program
just before you call C<$test->runtests>.

=head1 COMPATIBILITY POLICY

Every time I add a new test to this suite, I annotate it with a
version number.  If client code specifies an expected version number
(say, 1.10) and it's running against a newer version or this module
(say, 1.20) then any newer test will be marked as a TODO test.  That
way if the test fails, it won't regress published code that used to
work.

This policy will allow us to continue adding new filesystem tests
without worrying about breaking existing CPAN modules.

=head1 CAVEATS AND LIMITATIONS

This module needs a more complete suite of test cases.  In particular, tests
are needed for the following filesystem features:

    hardlinks
    nlink
    seek/rewinddir, tell/telldir
    read, sysread, syswrite
    overwrite (with open '+<')
    deep directories
    very full directories
    large files
    filenames with spaces
    non-ASCII filenames (maybe constructor should specify the encoding?)
    permissions
    special file types (fifos, sockets, character and block devices, etc)
    chown
    binmode, non-binmode
    eof
    fileno
    statfs (AKA `df` or `mount`)
    rename corner cases:
     * dest inside src
     * src or dest leaf is '.' or '..'
     * src or dest is FS root
     * dest leaf is symlink
    threading and re-entrancy
    file locking?
    async I/O??

Any help writing tests (or adapting tests from existing suites) will
be appreciated!

=head1 METHODS

This module is a subclass of L<Test::Class>.  All methods from that class are
available, particularly C<runtests()>.

=over

=item $pkg->new({mountdir =E<gt> $mountdir, ...})

Create a new test suite which will operate on files contained within the
specified mount directory.  WARNING: any and all files and folders in that
mount directory will be deleted!

The supported options are:

=over

=item C<mountdir>

This required property indicates where tests should run.

=item C<compatible>

Specify a Test::Virtual::Filesystem version number that is known to
work.  If the actual Test::Virtual::Filesystem version number is
greater, then any test cases added after the specified compatible
version are considered C<TODO> tests.  See L<Test::More> for details
about C<TODO> tests.

=back

=item $self->init()

Invoked just before then end of C<new()>.  This exists solely for
subclassing convenience.  This implementation does nothing.

=back

=head1 PROPERTIES

The following accessor/mutator methods exist to turn on/off various
features.  They all behave in usual Perl fashion: with no argument,
they return the current value.  With one argument, they set the
current value and return the newly set value.

=over

=item $self->enable_test_all()

As a getter, checks whether all of the other tests are enabled.

As a setter, turns on/off all the tests.

=item $self->enable_test_xattr()

Default false.

=item $self->enable_test_time()

Default true.  If set false, it also sets C<atime>, C<mtime> and C<ctime> false.

=item $self->enable_test_atime()

Default false.

=item $self->enable_test_mtime()

Default true.

=item $self->enable_test_ctime()

Default true.

=item $self->enable_test_permissions()

Default false.

=item $self->enable_test_special()

Default true.  If set false, it also sets C<fifo> false.

=item $self->enable_test_fifo()

Default false.  AKA named pipes.

=item $self->enable_test_symlink()

Default true, except for platforms that do not support symlinks (for example
MSWin32 and cygwin) as determined by C<$Config::Config{d_symlink}>.

=item $self->enable_test_hardlink()

AKA the C<link()> function.  Default true.  If set false, this also sets C<nlink> false.

=item $self->enable_test_nlink()

Count hard links.  Default true.

=item $self->enable_test_chown()

Default false.

=back

=head1 TEST CASES

=over

=cut

sub new {
   my ($pkg, $opts) = @_;
   my $self = $pkg->SUPER::new();
   $opts ||= {};
   for my $key (qw(mountdir compatible)) {
      $self->{$key} = $opts->{$key};
   }
   $self->{fs_opts} = {
      # one-level deep copy
      map {$_ => ref $feature_defaults{$_} ? { %{$feature_defaults{$_}} } : $feature_defaults{$_}}
      keys %feature_defaults,
   };
   $self->init;
   $self->{ntestdir} = 0;
   return $self;
}

sub init {
   # no-op, subclasses may override
   return;
}

{
   # Create a read-write accessor for each enabling feature
   no strict 'refs';  ## no critic(NoStrict)
   for my $field (keys %feature_defaults) {
      *{'enable_test_'.$field} = sub {
         return $_[0]->{fs_opts}->{$field} if @_ == 1;
         return $_[0]->{fs_opts}->{$field} = $_[1] if @_ == 2;
         croak 'wrong number of arguments to ' . $field;
      };
      my $val = $feature_defaults{$field};
      if (ref $val) {
         for my $subfield (keys %{$val}) {
            *{'enable_test_'.$subfield} = sub {
               return $_[0]->{fs_opts}->{$field} && $_[0]->{fs_opts}->{$field}->{$subfield} if @_ == 1;
               return ($_[0]->{fs_opts}->{$field} ||= {})->{$subfield} = $_[1] if @_ == 2;
               croak 'wrong number of arguments to ' . $subfield;
            };
         }
      }
   }
}

sub enable_test_all {
   my ($self, @arg) = @_;
   return $self->_enable_test_all($self->{fs_opts}, @arg);
}
sub _enable_test_all {
   my ($self, $hash, @arg) = @_;

   my $all_set = 1;
   for my $key (keys %{$hash}) {
      if (ref $hash->{$key}) {
         $all_set = $self->_enable_test_all($hash->{$key}, @arg) && $all_set; #recurse
      } else {
         if (@arg) {
            $hash->{$key} = $arg[0] ? 1 : 0;
         }
         $all_set &&= $hash->{$key};
      }
   }
   return $all_set;
}

=item setup()

Runs before every test to prepare a directory for testing.

=cut

sub setup : Test(setup) {
   my ($self) = @_;
   if (!defined $self->{mountdir}) {
      croak 'Programmer error: you did not specify a mountdir';
   }
   if (!-d $self->{mountdir}) {
      croak "Your mountdir '$self->{mountdir}' is not a valid directory";
   }
   if (!File::Spec->file_name_is_absolute($self->{mountdir})) {
      croak "Your mountdir '$self->{mountdir}' is not an absolute path";
   }
   if (File::Spec->splitdir($self->{mountdir}) <= 2) {
      croak "Your mountdir '$self->{mountdir}' is too close to the root of the filesystem." .
          '  I am too scared of deleting important files to use it';
   }
   $self->{tempdir} = File::Spec->catdir($self->{mountdir}, 'testdir' . ++$self->{ntestdir});
   mkdir $self->{tempdir};
   if (! -d $self->{tempdir}) {
      die 'Failed to create tempdir';
   }
   return;
}

=item teardown()

Runs after every test to clean up the test directory so the next test
will have a clean workspace.

=cut

sub teardown : Test(teardown) {
   my ($self) = @_;
   my $tmpdir = delete $self->{tempdir};
   if (defined $tmpdir && -e $tmpdir) {
      $self->_cleandir($tmpdir);
      if ($tmpdir ne $self->{mountdir}) {
         rmdir $tmpdir or die $OS_ERROR;
      }
   }
   if (defined $tmpdir && -d $tmpdir) {
      die 'Failed to remove tempdir';
   }
   return;
}

sub _cleandir {
   my ($self, $dir) = @_;
   for my $file ($self->_read_dir($dir)) {
      next if q{.} eq $file;
      next if q{..} eq $file;
      my $path = File::Spec->catfile($dir, $file);
      die 'Internal error: escaped the temp space!' if length $path <= length $self->{mountdir};
      die 'nonsense missing file: ' . $path if !-l $path && !-e $path;
      if (-l $path) {
         unlink $path or die $OS_ERROR;
      } elsif (-d $path) {
         $self->_cleandir($path);
         rmdir $path or die $OS_ERROR;
      } else {
         unlink $path or die $OS_ERROR;
      }
   }
   return;
}

=item Introduced($version)

A subroutine attribute used to flag the Test::Virtual::Filesystem
version number when that test was introduced.  It's used like this:

  sub open_nonexistent_file : Tests(1) : Introduced('0.02') {
     ok(!open(my $f, '<', '/tmp/no_such_file'));
  }

=cut

# http://use.perl.org/~ChrisDolan/journal/34906
# http://use.perl.org/~ChrisDolan/journal/34920

sub Introduced : ATTR(CODE) { ## no critic(MixedCase)
   my ($class, $symbol, $code_ref, $attr, $introduced_version) = @_;
   if ($symbol eq 'ANON') {
      warn 'cannot test anonymous subs - you probably loaded ' . __PACKAGE__ . ' too late.' .
          ' (after the CHECK block was run)';
   } else {
      # Wrap the sub in a version test
      no warnings 'redefine';  ## no critic(TestingAndDebugging::ProhibitNoWarnings)
      *{$symbol} = sub {
         no strict 'refs';  ## no critic(TestingAndDebugging::ProhibitNoStrict)
         local ${$class.'::TODO'} = $_[0]->_compatible($introduced_version); ## no critic(Local)
         $code_ref->(@_);
      };

      #my $name = *{$symbol}{NAME};
      #print STDERR "record $class\::$name as $introduced_version\n";
   }
   return;
}
sub _compatible {
   my ($self, $introduced_version) = @_;
   return if !$self->{compatible};
   return if $introduced_version le $self->{compatible};
   return 'compatibility mode ' . $self->{compatible};
}

=item Features($featurelist)

This is a subroutine attribute to specify one or more features used in
the test.  The features should be listed as a comma-separated list:

  sub symlink_create : Tests(1) : Features('symlink') {
     ok(symlink($src, $dest));
  }
  sub symlink_permissions : Tests(2) : Features('symlink, permissions') {
     ok(symlink($src, $dest));
     ok(-w $dest);
  }

Subfeatures must be separated from their parent features by a C</>.  For example:

  sub atime_mtime_set : Tests(1) : Features('time/atime, time/mtime') {
     my $now = time;
     ok(utime($now, $now, $file));
  }

Look at the source code for C<%feature_defaults> to see the supported features and
subfeatures.  The C<enable_test_*> methods above describe the all the
features, but in those methods the subfeature names are flattened.

=cut

sub Features : ATTR(CODE) { ## no critic(MixedCase)
   my ($class, $symbol, $code_ref, $attr, $features) = @_;
   if ($symbol eq 'ANON') {
      warn 'cannot test anonymous subs - you probably loaded ' . $class . ' too late.' .
          ' (after the CHECK block was run)';
   } else {
      my @features = ref $features ? @{$features} : split m/\s*,\s*/xms, $features;
      # Wrap the sub in a feature test
      no warnings 'redefine';  ## no critic(TestingAndDebugging::ProhibitNoWarnings)
      *{$symbol} = sub {
         my $blocking_feature = _blocking_feature(__PACKAGE__, $_[0], @features);
         return $blocking_feature if $blocking_feature;
         return $code_ref->(@_);
      };
   }
   return;
}
sub _blocking_feature {
   my ($pkg, $self, @features) = @_;

   for my $feature (@features) {
      return $feature . ' (no OS support)' if $feature_disabled{$feature};
      my $opts = $self->{fs_opts};
      for my $part (split m{/}xms, $feature) {
         return $feature if !ref $opts;
         return $feature if !$opts->{$part};
         $opts = $opts->{$part};
      }
   }
   return;
}

=item stat_dir(), introduced in v0.01

=cut

sub stat_dir : Test(6) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file(q{/});
   ok(-e $f, 'mount dir exists');
   ok(-d $f, 'mount dir is a dir');
   ok(!-f $f, 'mount dir is not a file');
   ok(!-l $f, 'mount dir is not a symlink');
   ok(-r $f, 'mount dir is readable');
   ok(-x $f, 'mount dir is searchable');
   return;
}

## This turned out to be very platform-sensitive.
#
# =item stat_dir_size(), introduced in v0.02
#
# =cut
#
# sub stat_dir_size : Test(1) : Introduced('0.02') {
#    my ($self) = @_;
#    my $f = $self->_file(q{/});
#    ok(-s $f, 'mount dir has non-zero size');
#    return;
# }

=item read_dir(), introduced in v0.01

=cut

sub read_dir : Test(3) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file(q{/});
   my @files = $self->_read_dir($f);
   cmp_ok(scalar @files, '>=', 2, 'dir contains at least two entries');
   ok((any { $_ eq q{.} }  @files), 'dir contains "."');
   ok((any { $_ eq q{..} } @files), 'dir contains ".."');
   return;
}

=item read_dir_fail(), introduced in v0.01

=cut

sub read_dir_fail : Test(2) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/no_such');
   eval {
      $self->_read_dir_die($f);
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOENT()], 'read non-existent dir');
   ok(!-e $f, 'did not make dir');
   return;
}

=item read_file_fail(), introduced in v0.01

=cut

sub read_file_fail : Test(2) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/read_file_fail');
   my $content = 'content';
   eval {
      $self->_read_file_die($f);
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOENT()], 'read non-existent file');
   ok(!-e $f, 'did not make file');
   return;
}

=item write_empty_file(), introduced in v0.01

=cut

sub write_empty_file : Test(2) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/create_file');
   $self->_write_file($f);
   ok(-f $f, 'created empty file');
   is(-s $f, 0, 'file got right size');
   return;
}

=item write_file(), introduced in v0.01

=cut

sub write_file : Test(2) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/write_file');
   my $content = 'content';
   $self->_write_file($f, $content);
   ok(-f $f, 'wrote file');
   is(-s $f, length $content, 'file got right size');
   return;
}

=item write_file_subdir_fail(), introduced in v0.01

=cut

sub write_file_subdir_fail : Test(2) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/no_such/write_file');
   my $content = 'content';
   eval {
      $self->_write_file($f, $content);
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOENT()], 'write to non-existent folder');
   ok(!-f $f, 'did not make file');
   return;
}

=item write_append_file(), introduced in v0.01

=cut

sub write_append_file : Test(2) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/append_file');
   my $content = 'content';
   $self->_write_file($f, $content);
   $self->_append_file($f, $content);
   ok(-f $f, 'wrote file');
   ok(-s $f == 2 * length $content, 'file got right size');
   return;
}

## Perl's '>>' creates the file if it doesn't exist
#
#=item write_append_file_fail(), introduced in v0.01
#
#=cut
#
# sub write_append_file_fail : Test(2) : Introduced('0.01') {
#    my ($self) = @_;
#    my $f = $self->_file('/append_file_fail');
#    my $content = 'content';
#    eval {
#       $self->_append_file($f, $content);
#    };
#    $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOENT()], 'append to non-existent file');
#    ok(!-f $f, 'did not make file');
#    return;
# }

=item write_read_file(), introduced in v0.01

=cut

sub write_read_file : Test(1) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/read_file');
   my $content = 'content';
   $self->_write_file($f, $content);
   is($self->_read_file($f), $content, 'read file');
   return;
}

=item write_read_file_binary(), introduced in v0.08

=cut

sub write_read_file_binary : Test(1) : Introduced('0.08') {
   my ($self) = @_;
   my $f = $self->_file('/read_file');
   my $content = 'content';
   for my $ord (0 .. 0xff, 0 .. 0xff) { ## no critic(MagicNumber)
      $content .= chr $ord;
   }
   $self->_write_file($f, $content);
   is($self->_read_file($f), $content, 'read file');
   return;
}

=item write_unlink_file(), introduced in v0.01

=cut

sub write_unlink_file : Test(3) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/read_file');
   my $content = 'content';
   $self->_write_file($f, $content);
   ok(-e $f, 'file exists');
   ok(-f $f, 'file is a file');
   unlink $f or die $OS_ERROR;
   ok(!-f $f, 'file is deleted');
   return;
}

=item write_mkdir(), introduced in v0.01

=cut

sub write_mkdir : Test(1) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/mk_dir');
   mkdir $f or die $OS_ERROR;
   ok(-d $f, 'made dir');
   return;
}

=item write_mkdir_fail(), introduced in v0.01

=cut

sub write_mkdir_fail : Test(2) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/no_such/mk_dir');
   eval {
      mkdir $f or die $OS_ERROR;
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOENT()], 'mkdir at non-existent path');
   ok(!-d $f, 'did not make dir');
   return;
}

=item write_rmdir(), introduced in v0.01

=cut

sub write_rmdir : Test(2) : Introduced('0.01') {
   my ($self) = @_;
   my $f = $self->_file('/rm_dir');
   mkdir $f or die $OS_ERROR;
   ok(-d $f, 'made dir');
   rmdir $f or die $OS_ERROR;
   ok(!-d $f, 'made dir');
   return;
}

=item write_subdir(), introduced in v0.01

=cut

sub write_subdir : Test(3) : Introduced('0.01') {
   my ($self) = @_;
   my $d = $self->_file('/mk_dir');
   my $f = $self->_file('/mk_dir/file');
   my $content = 'content';
   mkdir $d or die $OS_ERROR;
   ok(-d $d, 'made dir');
   $self->_write_file($f, $content);
   ok(-f $f, 'wrote file in subdir');
   is($self->_read_file($f), $content, 'right content');
   return;
}

=item symlink_create(), introduced in v0.02

=cut

sub symlink_create : Test(10) : Introduced('0.02') : Features('symlink') {
   my ($self) = @_;
   my $target = 'symlink_target';
   my $src = $self->_file("/$target");
   mkdir $src or die $OS_ERROR;
   ok(-e $src, 'symlink source exists');
   my $s = $self->_file('/symlink_create');
   ok((symlink $target, $s), 'created symlink') or die $OS_ERROR;
   ok(-e $s, 'symlink exists');
   ok(-l $s, 'symlink is a symlink');
   ok(-d $s, 'symlink src is a dir');
   ok(!-f $s, 'symlink src is not a file');
   is(-s $s, -s $src, 'symlink size is size of source');
   is(readlink $s, $target, 'read newly created symlink');
   unlink $s or die $OS_ERROR;
   ok(!-e $s, 'symlink deleted');
   ok(-e $src, 'symlink source not deleted');
   return;
}

=item symlink_follow(), introduced in v0.04

=cut

sub symlink_follow : Test(11) : Introduced('0.04') : Features('symlink') {
   my ($self) = @_;
   my $target = 'symlink_target';
   my $srcdir = $self->_file("/$target");
   my $srcfile = $self->_file("/$target/file.txt");
   my $s = $self->_file('/symlink_follow');
   my $symfile = $s . '/file.txt';
   mkdir $srcdir or die $OS_ERROR;
   my $content = 'content';
   $self->_write_file($srcfile, $content);
   ok(-e $srcfile, 'symlink source exists');
   ok((symlink $target, $s), 'created symlink') or die $OS_ERROR;
   ok(-e $s, 'symlink exists');
   ok(-l $s, 'symlink is a symlink');
   ok(-d $s, 'symlink src is a dir');
   ok(!-f $s, 'symlink src is not a file');
   is(-s $symfile, length $content, 'size of file though symlink size is size of content');
   is($self->_read_file($symfile), $content, 'read file through newly created symlink');
   unlink $symfile or die $OS_ERROR;
   ok(-e $s, 'symlink not deleted');
   ok(-e $srcdir, 'symlink target dir is not deleted');
   ok(!-e $srcfile, 'file through symlink is deleted');
   return;
}

=item symlink_deep(), introduced in v0.06

=cut

sub symlink_deep : Test(17) : Introduced('0.06') : Features('symlink') {
   my ($self) = @_;
   # follow through a chain of non-looping symlinks
   my $target = 'symlink_target';
   my $srcdir = $self->_file("/$target");
   my $srcfile = $self->_file("/$target/file.txt");
   # 5 is the limit for Linux.  Beyond that, we get ELOOP: Too many levels of symbolic links
   # Other platforms seem to tolerate higher numbers...
   my @s = map {$self->_file("/symlink_$_")} 1 .. 5; ## no critic(ValuesAndExpressions::ProhibitMagicNumbers)

   mkdir $srcdir or die $OS_ERROR;
   my $content = 'content';
   $self->_write_file($srcfile, $content);
   ok(-e $srcfile, 'symlink source exists');
   ok(-f $srcfile, 'symlink source is a file');

   ok((symlink $target, $s[0]), 'created symlink') or die $OS_ERROR;
   for my $i (1..$#s) {
      ok((symlink 'symlink_' . $i, $s[$i]), 'created symlink') or die $OS_ERROR;
   }
   my $symfile = $self->_file('/symlink_'.@s.'/file.txt');
   ok(-e $symfile, 'file exists'); # or die 'no symlinked file, cannot continue';
   ok(!-l $symfile, 'file is not a symlink');
   ok(-f $symfile, 'file is a file');
   ok(!-d $symfile, 'file is not a dir');
   is(-s $symfile, length $content, 'size of file though symlink size is size of content');
   is($self->_read_file($symfile), $content, 'read file through newly created symlink');
   unlink $symfile or die $OS_ERROR;
   ok(-e $s[0], 'symlink not deleted');
   ok(-e $s[-1], 'symlink not deleted');
   ok(-e $srcdir, 'symlink target dir is not deleted');
   ok(!-e $srcfile, 'file through symlink is deleted');
   return;
}

=item symlink_loop(), introduced in v0.06

=cut

sub symlink_loop : Test(2) : Introduced('0.06') : Features('symlink') {
   my ($self) = @_;
   my $target = 'symlink_target';
   my $s = $self->_file("/$target");
   ok((symlink $target, $s), 'created symlink') or die $OS_ERROR;
   eval {
      open my $fh, '<', $s or die $OS_ERROR;
      close $fh;  ## no critic(InputOutput::RequireCheckedClose)
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ELOOP()], 'detected symlink loop');
   
   return;
}

=item truncate_file(), introduced in v0.06

=cut

sub truncate_file : Test(7) : Introduced('0.06') {
   my ($self) = @_;
   my $f = $self->_file(q{/truncate.txt});
   my $content = 'content';

   ## no critic(ValuesAndExpressions::ProhibitMagicNumbers)
   $self->_write_file($f, $content);
   is(-s $f, length $content, 'wrote test file');
   ok((truncate $f, 4), 'truncate to 4 bytes') or die $OS_ERROR;
   is(-s $f, 4, 'correct size');
   ok((truncate $f, 0), 'truncate to 0 bytes') or die $OS_ERROR;
   is(-s $f, 0, 'correct size');
   ok((truncate $f, 0), 'truncate to 0 bytes') or die $OS_ERROR;
   is(-s $f, 0, 'correct size');
   return;
}

=item truncate_no_file(), introduced in v0.06

=cut

sub truncate_no_file : Test(1) : Introduced('0.06') {
   my ($self) = @_;
   my $f = $self->_file(q{/truncate.txt});
   eval {
      truncate $f, 0 or die $OS_ERROR;
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOENT()], 'truncate non-existent file');
   return;
}

=item truncate_file_no_dir(), introduced in v0.06

=cut

sub truncate_file_no_dir : Test(1) : Introduced('0.06') {
   my ($self) = @_;
   my $pseudo_dir = $self->_file(q{/dir});
   my $f = $self->_file(q{/dir/truncate.txt});
   $self->_write_file($pseudo_dir, 'foo');
   eval {
      truncate $f, 0 or die $OS_ERROR;
   };
   # man 2 truncate says "[ENOTDIR] A component of the path prefix is not a directory."
   # MSWin32 says ENOENT
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOTDIR(), ENOENT()], 'truncate file in non-existent directory');
   return;
}

=item truncate_dir(), introduced in v0.06

=cut

sub truncate_dir : Test(1) : Introduced('0.06') {
   my ($self) = @_;
   my $d = $self->_file(q{/truncate_dir});
   mkdir $d or die $OS_ERROR;
   eval {
      truncate $d, 0 or die $OS_ERROR;
   };
   # man 2 truncate says "[EISDIR] The named file is a directory."
   # MSWin32 says EACCES
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [EISDIR(), EACCES()], 'truncate dir');
   return;
}

=item time_mtime_create(), introduced in v0.06

=cut

sub time_mtime_create : Test(2) : Introduced('0.06') : Features('time/mtime') {
   my ($self) = @_;
   my $f = $self->_file(q{/file.txt});

   my $before = time;
   $self->_write_file($f);
   my $after = time;

   my ($mtime) = (stat $f)[9];   ## no critic(ValuesAndExpressions::ProhibitMagicNumbers)
   cmp_ok($mtime, q{>=}, $before - $TIME_LENIENCE, 'mtime vs. before time')
       or diag 'Is your clock out of synch?';
   cmp_ok($mtime, q{<=}, $after + $TIME_LENIENCE, 'mtime vs. after time');
   return;
}

=item time_ctime_create(), introduced in v0.06

=cut

sub time_ctime_create : Test(2) : Introduced('0.06') : Features('time/ctime') {
   my ($self) = @_;
   my $f = $self->_file(q{/file.txt});

   # sleep is needed in case of network filesystem time synch errors
   my $before = time;
   $self->_write_file($f);
   my $after = time;

   my ($ctime) = (stat $f)[10];   ## no critic(ValuesAndExpressions::ProhibitMagicNumbers)
   cmp_ok($ctime, q{>=}, $before - $TIME_LENIENCE, 'ctime vs. before time')
       or diag 'Is your clock out of synch?';
   cmp_ok($ctime, q{<=}, $after + $TIME_LENIENCE, 'ctime vs. after time');
   return;
}

=item time_mtime_set(), introduced in v0.06

=cut

sub time_mtime_set : Test(1) : Introduced('0.06') : Features('time/mtime') {
   my ($self) = @_;
   my $f = $self->_file(q{/file.txt});

   $self->_write_file($f);

   ## no critic(ValuesAndExpressions::ProhibitMagicNumbers)
   my ($old_atime, $old_mtime) = (stat $f)[8,9];
   utime $old_atime, $old_mtime - 100, $f or die $OS_ERROR;
   my ($new_atime, $new_mtime) = (stat $f)[8,9];
   is($new_mtime, $old_mtime - 100, 'changed mtime');
   return;
}

=item time_atime_set(), introduced in v0.06

=cut

sub time_atime_set : Test(1) : Introduced('0.06') : Features('time/atime') {
   my ($self) = @_;
   my $f = $self->_file(q{/file.txt});

   $self->_write_file($f);

   ## no critic(ValuesAndExpressions::ProhibitMagicNumbers)
   my ($old_atime, $old_mtime) = (stat $f)[8,9];
   utime $old_atime - 100, $old_mtime, $f or die $OS_ERROR;
   my ($new_atime, $new_mtime) = (stat $f)[8,9];
   is($new_atime, $old_atime - 100, 'changed atime');
   return;
}

=item xattr_list(), introduced in v0.02

=cut

sub xattr_list : Test(1) : Introduced('0.02') : Features('xattr') {
   my ($self) = @_;
   my $f = $self->_file(q{/});
   my @attrs = File::ExtAttr::listfattr($f);
   ok(@attrs == 0 || defined $attrs[0], 'got xattr list');
   return;
}

=item xattr_set(), introduced in v0.02

=cut

sub xattr_set : Test(9) : Introduced('0.02') : Features('xattr') {
   my ($self) = @_;

   my $f = $self->_file('/foo');
   $self->_write_file($f);

   my $xattr_key = 'org.cpan.cdolan';
   my $xattr_value = 'test';
   my $xattr_replace = 'test2';

   # just in case, clean up.  This fails if the value is '0' but that should never happen!
   if (File::ExtAttr::getfattr($f, $xattr_key)) {
      File::ExtAttr::delfattr($f, $xattr_key);
   }
   {
      # File::ExtAttr doesn't look at $^W or 'no warnings'.  Grr...
      local $SIG{__WARN__} = sub {};
      ok(!File::ExtAttr::setfattr($f, $xattr_key, $xattr_value, {replace => 1}), 'cannot replace missing xattr');
   }
   ok(File::ExtAttr::setfattr($f, $xattr_key, $xattr_value, {create => 1}), 'create xattr');
   is(File::ExtAttr::getfattr($f, $xattr_key), $xattr_value, 'get xattr');
   ok((any {$xattr_key eq $_} File::ExtAttr::listfattr($f)), 'list xattr');
   {
      local $SIG{__WARN__} = sub {};
      ok(!File::ExtAttr::setfattr($f, $xattr_key, $xattr_value, {create => 1}), 'cannot create existing xattr');
   }
   ok(File::ExtAttr::setfattr($f, $xattr_key, $xattr_replace, {replace => 1}), 'replace xattr');
   is(File::ExtAttr::getfattr($f, $xattr_key), $xattr_replace, 'get xattr');
   ok(File::ExtAttr::delfattr($f, $xattr_key), 'delete xattr');
   # Some implementations return undef, some return q{}
   my $get = File::ExtAttr::getfattr($f, $xattr_key);
   ok(!defined $get || q{} eq $get, 'xattr deleted');

   unlink $f;
   return;
}

=item rename_file(), introduced in v0.08

=cut

sub rename_file : Test(4) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $dest = $self->_file('/rename_dest');
   my $content = 'content';
   $self->_write_file($src, $content);
   ok((rename $src, $dest), 'rename');
   ok(-e $dest, 'dest exists');
   ok(!-e $src, 'src no longer exists');
   is($self->_read_file($dest), $content, 'read dest');
   return;
}

=item rename_file_exists(), introduced in v0.08

=cut

sub rename_file_exists : Test(4) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $dest = $self->_file('/rename_dest');
   my $content = 'content';
   $self->_write_file($src, $content);
   $self->_write_file($dest);
   ok((rename $src, $dest), 'rename');
   ok(-e $dest, 'dest exists');
   ok(!-e $src, 'src no longer exists');
   is($self->_read_file($dest), $content, 'read dest');
   return;
}

=item rename_file_self(), introduced in v0.08

=cut

sub rename_file_self : Test(4) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $dest = $src;
   my $content = 'content';
   $self->_write_file($src, $content);
   ok((rename $src, $dest), 'rename');
   ok(-e $dest, 'dest exists');
   ok(-e $src, 'src still exists');
   is($self->_read_file($dest), $content, 'read dest');
   return;
}

=item rename_file_subdir(), introduced in v0.08

=cut

sub rename_file_subdir : Test(4) : Introduced('0.08') {
   my ($self) = @_;
   my $srcdir = $self->_file('/rename_srcdir');
   my $src = $self->_file('/rename_srcdir/rename_src');
   my $destdir = $self->_file('/rename_destdir');
   my $dest = $self->_file('/rename_destdir/rename_dest');
   mkdir $srcdir or die $OS_ERROR;
   mkdir $destdir or die $OS_ERROR;
   my $content = 'content';
   $self->_write_file($src, $content);
   ok((rename $src, $dest), 'rename');
   ok(-e $dest, 'dest exists');
   ok(!-e $src, 'src no longer exists');
   is($self->_read_file($dest), $content, 'read dest');
   return;
}

=item rename_file_missing_src(), introduced in v0.08

=cut

sub rename_file_missing_src : Test(1) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $dest = $self->_file('/rename_dest');
   eval {
      rename $src, $dest or die $OS_ERROR;
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOENT()], 'src file is missing');
   return;
}

=item rename_file_missing_srcdir(), introduced in v0.08

=cut

sub rename_file_missing_srcdir : Test(1) : Introduced('0.08') {
   my ($self) = @_;
   my $srcdir = $self->_file('/rename_srcdir');
   my $src = $self->_file('/rename_srcdir/rename_src');
   my $dest = $self->_file('/rename_dest');
   my $content = 'content';
   eval {
      rename $src, $dest or die $OS_ERROR;
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOENT()], 'src dir is missing');
   return;
}

=item rename_file_missing_destdir(), introduced in v0.08

=cut

sub rename_file_missing_destdir : Test(1) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $destdir = $self->_file('/rename_destdir');
   my $dest = $self->_file('/rename_destdir/rename_dest');
   my $content = 'content';
   $self->_write_file($src, $content);
   eval {
      rename $src, $dest or die $OS_ERROR;
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOENT()], 'dest dir is missing');
   return;
}

=item rename_dir(), introduced in v0.08

=cut

sub rename_dir : Test(6) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $srcfile = $self->_file('/rename_src/file.txt');
   my $dest = $self->_file('/rename_dest');
   my $destfile = $self->_file('/rename_dest/file.txt');
   mkdir $src or die $OS_ERROR;
   my $content = 'content';
   $self->_write_file($srcfile, $content);
   ok((rename $src, $dest), 'rename');
   ok(-e $dest, 'dest exists');
   ok(-e $destfile, 'dest file exists');
   ok(!-e $src, 'src no longer exists');
   is_deeply([sort $self->_read_dir($dest)], [qw(. .. file.txt)], 'read dest');
   is($self->_read_file($destfile), $content, 'read dest');
   return;
}

=item rename_dir_exists(), introduced in v0.08

=cut

sub rename_dir_exists : Test(6) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $srcfile = $self->_file('/rename_src/file.txt');
   my $dest = $self->_file('/rename_dest');
   my $destfile = $self->_file('/rename_dest/file.txt');
   my $content = 'content';
   mkdir $src or die $OS_ERROR;
   mkdir $dest or die $OS_ERROR;
   $self->_write_file($srcfile, $content);
   if ($OSNAME eq 'MSWin32') {
      # return the skip message
      return 'Cannot overwrite directories via rename on Windows';
   }
   ok((rename $src, $dest), 'rename');
   ok(-e $dest, 'dest exists');
   ok(-e $destfile, 'dest file exists');
   ok(!-e $src, 'src no longer exists');
   is_deeply([sort $self->_read_dir($dest)], [qw(. .. file.txt)], 'read dest');
   is($self->_read_file($destfile), $content, 'read dest');
   return;
}

=item rename_dir_notempty(), introduced in v0.08

=cut

sub rename_dir_notempty : Test(1) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $dest = $self->_file('/rename_dest');
   my $destfile = $self->_file('/rename_dest/file.txt');
   my $content = 'content';
   mkdir $src or die $OS_ERROR;
   mkdir $dest or die $OS_ERROR;
   $self->_write_file($destfile, $content);
   eval {
      rename $src, $dest or die $OS_ERROR;
   };
   # man 2 rename says "[ENOTEMPTY] To is a directory and is not empty."
   # MSWin32 says EACCES
   # Solaris says EEXIST
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOTEMPTY(), EACCES(), EEXIST()], 'dest dir is not empty');
   return;
}

=item rename_dir_self(), introduced in v0.08

=cut

sub rename_dir_self : Test(5) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $srcfile = $self->_file('/rename_src/file.txt');
   my $dest = $src;
   my $destfile = $srcfile;
   mkdir $src or die $OS_ERROR;
   my $content = 'content';
   $self->_write_file($srcfile, $content);
   ok((rename $src, $dest), 'rename');
   ok(-e $dest, 'dest exists');
   ok(-e $destfile, 'dest file exists');
   is_deeply([sort $self->_read_dir($dest)], [qw(. .. file.txt)], 'read dest');
   is($self->_read_file($destfile), $content, 'read dest');
   return;
}

=item rename_dir_subdir(), introduced in v0.08

=cut

sub rename_dir_subdir : Test(6) : Introduced('0.08') {
   my ($self) = @_;
   my $srcdir = $self->_file('/rename_srcdir');
   my $src = $self->_file('/rename_srcdir/rename_src');
   my $srcfile = $self->_file('/rename_srcdir/rename_src/file.txt');
   my $destdir = $self->_file('/rename_destdir');
   my $dest = $self->_file('/rename_destdir/rename_dest');
   my $destfile = $self->_file('/rename_destdir/rename_dest/file.txt');
   mkdir $srcdir or die $OS_ERROR;
   mkdir $destdir or die $OS_ERROR;
   mkdir $src or die $OS_ERROR;
   my $content = 'content';
   $self->_write_file($srcfile, $content);
   ok((rename $src, $dest), 'rename');
   ok(-e $dest, 'dest exists');
   ok(-e $destfile, 'dest file exists');
   ok(!-e $src, 'src no longer exists');
   is_deeply([sort $self->_read_dir($dest)], [qw(. .. file.txt)], 'read dest');
   is($self->_read_file($destfile), $content, 'read dest');
   return;
}

=item rename_mismatch_dir(), introduced in v0.08

=cut

sub rename_mismatch_dir : Test(1) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_src');
   my $dest = $self->_file('/rename_dest');
   my $content = 'content';
   $self->_write_file($src, $content);
   mkdir $dest or die $OS_ERROR;
   eval {
      rename $src, $dest or die $OS_ERROR;
   };
   # man 2 rename says "[EISDIR] 'to' is a directory, but 'from' is not a directory."
   # MSWin32 says EACCES
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [EISDIR(), EACCES()], 'dest is a directory');
   return;
}

=item rename_mismatch_file(), introduced in v0.08

=cut

sub rename_mismatch_file : Test(1) : Introduced('0.08') {
   my ($self) = @_;
   my $src = $self->_file('/rename_srcdir');
   my $dest = $self->_file('/rename_destfile.txt');
   mkdir $src or die $OS_ERROR;
   my $content = 'content';
   $self->_write_file($dest, $content);
   if ($OSNAME eq 'MSWin32' || $OSNAME eq 'cygwin') {
      # return the skip message
      return 'Windows and Cygwin allow rename(<dir>, <file>) instead of failing with ENOTDIR';
   }
   eval {
      rename $src, $dest or die $OS_ERROR;
   };
   $self->_is_errno($EVAL_ERROR, $OS_ERROR, [ENOTDIR()], 'dest is not a directory');

   return;
}

=item rename_symlink(), introduced in v0.08

=cut

sub rename_symlink : Test(6) : Introduced('0.08') : Features('symlink') {
   my ($self) = @_;
   my $srcfile = $self->_file('/rename_srcfile.txt');
   my $src = $self->_file('/rename_src');
   my $dest = $self->_file('/rename_dest');
   my $content = 'content';
   $self->_write_file($srcfile, $content);
   symlink $srcfile, $src or die $OS_ERROR;
   ok((rename $src, $dest), 'rename');
   ok(-e $dest, 'dest exists');
   ok(-e $srcfile, 'source target file still exists');
   ok(!-e $src, 'src no longer exists');
   ok(-l $dest, 'dest is a symlink');
   is($self->_read_file($dest), $content, 'read dest');
   return;
}

######### helpers ########


sub _is_errno {
   my ($self, $eval_error, $os_errno, $expected_errnos, $msg) = @_;
   my $num_errno = 0 + $os_errno;
   my $str_errno = "$os_errno";
   return pass($msg) if $eval_error && $num_errno && any {$_ == $num_errno} @{$expected_errnos};
   my $expected_str = join q{, }, map {strerror($_)} @{$expected_errnos};
   if (!$eval_error) {
      return fail("$msg; didn't throw expected exception");
   } elsif (1 == @{$expected_errnos}) {
      return is("$num_errno ($str_errno)", "$expected_errnos->[0] ($expected_str)", $msg);
   } else {
      return is("$num_errno ($str_errno)", "[@{$expected_errnos}] ($expected_str)", $msg);
   }
}

sub _file {
   my ($self, $path) = @_;
   $path =~ s{\A /}{}xms or croak 'test paths must be absolute';
   # Change path to proper OS format
   return File::Spec->catfile($self->{tempdir}, split m{/}xms, $path);
}

sub _write_file {
   my ($self, $f, @content) = @_;
   open my $fh, '>', $f or die $OS_ERROR;
   binmode $fh;
   for my $content (@content) {
      print {$fh} $content or die $OS_ERROR;
   }
   close $fh or die $OS_ERROR;
   return;
}

sub _append_file {
   my ($self, $f, @content) = @_;
   open my $fh, '>>', $f or die $OS_ERROR;
   binmode $fh;
   for my $content (@content) {
      print {$fh} $content or die $OS_ERROR;
   }
   close $fh or die $OS_ERROR;
   return;
}

sub _read_file {
   my ($self, $f) = @_;
   open my $fh, '<', $f or return;
   binmode $fh;
   my $content = do { local $INPUT_RECORD_SEPARATOR = undef; <$fh> };
   close $fh or return;
   return $content;
}

sub _read_file_die {
   my ($self, $f) = @_;
   open my $fh, '<', $f or die $OS_ERROR;
   binmode $fh;
   my $content = do { local $INPUT_RECORD_SEPARATOR = undef; <$fh> };
   close $fh or die $OS_ERROR;
   return $content;
}

sub _read_dir {
   my ($self, $f) = @_;
   opendir my $fh, $f or return;
   my @content = readdir $fh;
   closedir $fh or return;
   return @content;
}

sub _read_dir_die {
   my ($self, $f) = @_;
   opendir my $fh, $f or die $OS_ERROR;
   my @content = readdir $fh;
   closedir $fh or die $OS_ERROR;
   return @content;
}

1;

__END__

=pod

=back

=head1 CODE PHILOSOPHY

These are some coding/design rules for the tests:

=over

=item Use only core filesystem functions

Don't use File::Slurp, File::Path, etc. because they abstract filesystem
operations and make it less clear what we're testing.

=item Keep the tests small

Test as little as possible in each method.  Let authors know what's failed by
the pattern of failing tests.  This also helps avoid needing to edit the tests later.

=item Avoid editing methods

Don't break published CPAN code.  If you want to test something new, write a new method.

=item Try to use a few different filesystem functions as practical in one method

For example, if you're testing C<chmod>, don't C<mkdir> or C<chown> unless
you're writing a C<chmod_mkdir_chown> test.

=item Minimize test infrastructure

Use method attributes and Test::Class features to keep the test methods really
simple.

=back

=head1 SEE ALSO

L<Test::Class>

L<Fuse::PDF>

=head1 AUTHOR

Chris Dolan, I<cdolan@cpan.org>

=cut

# Local Variables:
#   mode: perl
#   perl-indent-level: 3
#   cperl-indent-level: 3
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
