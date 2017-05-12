use strict;
use warnings;

use Test::More tests => 2;

use Try::Tiny::NoDie;

my $Died = 0;
$SIG{__DIE__} = sub { $Died++ };

{
  $Died = 0;
  try { die "foo" };
  is($Died, 1, "exception within try emits SIGDIE");
}

{
  $Died = 0;
  try_no_die { die "foo" };
  is($Died, 0, "exception within try_no_die does not emit SIGDIE");
}
