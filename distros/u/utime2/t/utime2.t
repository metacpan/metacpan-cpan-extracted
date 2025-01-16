# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl utime2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('utime2') };

use FileHandle;
use File::stat;

sub eqv
{
  return (($_[0] && $_[1]) or ((! $_[0]) && (! $_[1])));
}

'FileHandle'->new (">utime2.txt");

my ($da, $dm) = (3600.52, 700.9);

for my $file ('utime2.txt', 'utime3.txt')
  {
    my $st = stat ($file);
 
    my $atime = ($st ? $st->atime : time ()) + $da; 
    my $mtime = ($st ? $st->mtime : time ()) + $dm; 
       
    my $rc = &utime2::utime2 ($atime, $mtime, $file);

    &ok (&eqv ($rc, $st), 'file exists');

    if ($st)
      {
        my $st1 = stat ($file);
        &ok (abs ($st1->atime - $st->atime - $da) <= 1, 'check atime');
        &ok (abs ($st1->mtime - $st->mtime - $dm) <= 1, 'check mtime');
      }

    unlink ($file);
  }

