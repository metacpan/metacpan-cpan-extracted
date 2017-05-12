## ----------------------------------------------------------------------------
# t/0.loadxs.t
# -----------------------------------------------------------------------------
# $Id: 0.loadxs.t 5236 2008-01-16 09:47:26Z hio $
# -----------------------------------------------------------------------------

use strict;
use Test;
BEGIN { plan tests => 3 }

# -----------------------------------------------------------------------------
# load module

require Unicode::Japanese;
ok(1,1,'require');

import Unicode::Japanese;
ok(1,1,'import');

# -----------------------------------------------------------------------------
# check XS was loaded.

# xs is loaded in first invocation of `new'.
Unicode::Japanese->new();
# to avoid used-only-once warning, read twice.
my $err = ($Unicode::Japanese::xs_loaderror,$Unicode::Japanese::xs_loaderror)[0];
if( !-e 't/pureperl.flag' )
{
  print "# load xs\n";
  ok($err,'');
}else
{
  print "# pure perl\n";
  ok($err =~ /Can't locate loadable object/);
}

