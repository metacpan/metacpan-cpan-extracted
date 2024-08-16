use strict;
use warnings;
use File::Basename ();
use File::Spec;
use Cwd ();

use constant DEBUG_FIND_YATT_LIB => $ENV{DEBUG_FIND_YATT_LIB};

my $thisdir = do {
  if (-r __FILE__) {
    # detect where app.psgi is placed.
    File::Basename::dirname(File::Spec->rel2abs(__FILE__));
  } else {
    # older uwsgi do not set __FILE__ correctly, so use cwd instead.
    Cwd::cwd();
  }
};
print STDERR "# thisdir=$thisdir\n" if DEBUG_FIND_YATT_LIB;

my ($found) = $thisdir =~ m{^(.*?/)YATT/}
  or return;
print STDERR "# found=$found\n" if DEBUG_FIND_YATT_LIB;

my @libdir = $found;

foreach my $d (qw(extlib local/lib/perl5)) {
  -d (my $dn = File::Basename::dirname($found) . "/$d")
    or next;
  push @libdir, $dn;
}
print STDERR "# libdir=@libdir\n" if DEBUG_FIND_YATT_LIB;

return @libdir;
