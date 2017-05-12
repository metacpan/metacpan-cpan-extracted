package My::CommonTestRoutines;

use Cwd qw(cwd);
use File::Spec ();
use File::Path qw(rmtree);

use Test::More;

my $base = $ENV{DOCUMENT_ROOT} ? cwd : File::Spec->catfile(cwd, 't');

my $tmpdir = File::Spec->catfile($base, 'tmp');

sub tmpdir {
  return $tmpdir;
}

END {
  # cleanup

  ok (-e $tmpdir, "$tmpdir exists");

  chdir $base;
  rmtree 'tmp';

  ok (! -e $tmpdir, "$tmpdir removed");
}
