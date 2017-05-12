use strict;
use warnings;
use utf8;
use Test::Tester;
use Test::More tests => 9;
use File::Temp;
use Test::MinimumVersion::Fast;

my $tmp = File::Temp->new(UNLINK => 1);
$tmp->print("...\n");
$tmp->flush;
 
isnt(-s $tmp, 0);
minimum_version_ok($tmp->filename, '5.012');
 
check_test(
  sub {
    minimum_version_ok($tmp->filename, '5.012');
  },
  {
    ok   => 1,
    name => $tmp->filename,
    diag => '',
  },
  "successful comparison"
);

close $tmp;
