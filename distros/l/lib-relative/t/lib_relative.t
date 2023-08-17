use strict;
use warnings;
use Test::More;
use Cwd ();
use File::Basename ();
use File::Spec ();
use File::Temp ();
use lib::relative ();
use Config;

sub has_symlinks {
  return $Config{d_symlink}
    unless $^O eq 'msys' || $^O eq 'MSWin32';

  if ($^O eq 'msys') {
    # msys needs both `d_symlink` and a special environment variable
    return unless $Config{d_symlink};
    return $ENV{MSYS} =~ /winsymlinks:nativestrict/;
  } elsif ($^O eq 'MSWin32') {
    # Perl 5.33.5 adds symlink support for MSWin32 but needs elevated
    # privileges so verify if we can use it for testing.
    my $error;
    my $can_symlink;
    { # catch block
      local $@;
      $error = $@ || 'Error' unless eval { # try block
        # temp dirs with newdir() get cleaned up when they go out of scope
        my $wd = File::Temp->newdir();
        my $foo = File::Spec->catfile($wd, 'foo');
        my $bar = File::Spec->catfile($wd, 'bar');
        open my $fh, '>', $foo;
        $can_symlink = symlink $foo, $bar;
        1;
      };
    }
    return 1 if $can_symlink && !$error;
    return;
  }
}

# Relative path absolutized
{
  local @INC = @INC;
  lib::relative->import('testlib');
  
  ok((grep { m!\btestlib\b! and File::Spec->file_name_is_absolute($_) } @INC),
    'absolute path to testlib in @INC');
  
  ok((eval { require MyTestModule; 1 }), 'loaded MyTestModule from testlib')
    or diag $@;
  
  is MyTestModule::foo(), 'bar', 'correct function results';
}

# Absolute path passed through
{
  local @INC = @INC;
  my $path = File::Spec->catdir(File::Basename::dirname(Cwd::abs_path __FILE__), 'testlib');
  lib::relative->import($path);
  
  ok((grep { $_ eq $path } @INC), 'absolute path to testlib in @INC');
  
  ok((eval { require MyTestModule2; 1 }), 'loaded MyTestModule2 from testlib')
    or diag $@;
  
  is MyTestModule2::foo(), 'baz', 'correct function results';
}

# Symlinked __FILE__
SKIP: {
  skip 'symlinks not supported in this build', 4 unless has_symlinks();
  local @INC = @INC;
  my $dir = File::Temp->newdir;
  skip 4, 'tempdir in @INC' if grep { m!^\Q$dir\E! } @INC;
  my $path = File::Spec->catfile(File::Basename::dirname(Cwd::abs_path __FILE__), 'testlib', 'load_relative.pl');
  my $link = File::Spec->catfile($dir, 'load_relative.pl');
  my $rc;
  eval { $rc = symlink $path, $link; 1 } or skip 'symlinks not supported', 4;
  die "symlink failed: $!" unless $rc;
  do $link or die "failed to run $path: $!";

  ok((grep { m!\btestlib\b! and File::Spec->file_name_is_absolute($_) } @INC),
    'absolute path to testlib in @INC');
  ok(!(grep { m!^\Q$dir\E! } @INC), 'tempdir not in @INC');

  ok((eval { require MyTestModule3; 1 }), 'loaded MyTestModule3 from testlib')
    or diag $@;

  is MyTestModule3::foo(), 'buzz', 'correct function results';
}

done_testing;
