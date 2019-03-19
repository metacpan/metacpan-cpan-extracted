use strict;
use warnings;
use Test::More;
use Cwd ();
use File::Basename ();
use File::Spec ();
use File::Temp ();
use lib::relative ();

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
  local @INC = @INC;
  my $dir = File::Temp->newdir;
  skip 4, 'tempdir in @INC' if grep { m!^\Q$dir\E! } @INC;
  my $path = File::Spec->catfile(File::Basename::dirname(Cwd::abs_path __FILE__), 'testlib', 'load_relative.pl');
  my $link = File::Spec->catfile($dir, 'load_relative.pl');
  my $rc;
  eval { $rc = symlink $path, $link; 1 } or skip 4, 'symlinks not supported';
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
