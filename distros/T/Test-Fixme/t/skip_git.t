use strict;
use warnings;
use Test::More tests => 2;
use File::Temp qw( tempdir );
use Test::Fixme;

my $dir = tempdir( CLEANUP => 1 );

foreach my $subdir (qw( .git .svn CVS ))
{
  mkdir(File::Spec->catdir($dir, $subdir));
  open(my $fh, '>', File::Spec->catfile($dir, $subdir, 'bad.txt'));
  close $fh;
}
mkdir(File::Spec->catdir($dir, 'foo.svn.gitSVNbar'));
open(my $fh, '>', File::Spec->catfile($dir, 'foo.svn.gitSVNbar', 'good.txt'));
close $fh;

my @list = Test::Fixme::list_files($dir);

is(scalar @list, 1, 'list length = 1') || diag join "\n", @list;
like $list[0], qr{good.txt$}, 'filename =~ good.txt';
