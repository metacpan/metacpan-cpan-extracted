use strict;
use warnings;

use Test::More 0.88;
use File::Temp qw(tempdir tempfile);
use Test::EOL;

my $tempdir = tempdir(CLEANUP => 1);
foreach my $dir (qw(
  .svn
  .svna
  CVS
  blah
  blib
  blib/libdoc
  blib/libdocs
  blib/man1
  bliba
  bliba
  fooCVS
  inc
  vincent
)) {
  mkdir File::Spec->catfile($tempdir, $dir);
  open(my $fh, '>', File::Spec->catfile($tempdir, $dir, 'file'));
  close $fh;
}

open(my $fh, '>', File::Spec->catfile($tempdir, 'Build'));
close $fh;

my @files = sort(Test::EOL::_all_files($tempdir));

is_deeply(
    \@files,
    [ sort map File::Spec->catfile($tempdir, $_, 'file'), qw(
        .svna
        blah
        blib
        blib/libdocs
        bliba
        fooCVS
        vincent
      ) ],
    'correct files returned',
  )
  or note 'found files: ', join(', ', @files);

done_testing;
