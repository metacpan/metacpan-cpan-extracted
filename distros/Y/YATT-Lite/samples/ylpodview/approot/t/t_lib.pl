use strict;
use warnings;

my $dir = do {
  my $d = $_[0] || $FindBin::Bin or die "bindir is empty!";
  $d //= $FindBin::Bin; # To suppress warning.
  untaint_any($d);
};

sub MY () {__PACKAGE__}
use File::Basename;
sub untaint_any {$_[0] =~ m{(.*)} and $1}
use base qw/File::Spec/;

my (@libdir);
if (-d (my $d = "$dir/../_build/lib")."/YATT") {
  push @libdir, $d;
}
if (grep {$_ eq 'YATT'} MY->splitdir($dir)) {
  push @libdir, dirname(dirname($dir));
}
if (-d (my $d = "$dir/../blib/lib")."/YATT") {
  push @libdir, $d;
}
if (-d (my $d = "$dir/../lib")."/YATT") {
  push @libdir, $d;
}

unless (@libdir) {
  die "Can't find YATT in runtime path: $dir";
}

require lib;
import lib @libdir;

print STDERR join("\n", @libdir), "\n" if $ENV{DEBUG_INC};

return wantarray ? @libdir : $libdir[0];
