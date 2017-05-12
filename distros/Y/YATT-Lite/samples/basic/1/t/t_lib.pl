use strict;
use warnings;
require Carp;
sub MY () {__PACKAGE__}
require List::MoreUtils;

# $_[0] should be $dist_root/t, which is normally $FindBin::Bin.

my $dir = do {
  my $d = $_[0] || $FindBin::Bin or die "bindir is empty!";
  $d //= $FindBin::Bin; # To suppress warning.
  MY->rel2abs(untaint_any($d));
};

use File::Basename;
sub untaint_any {$_[0] =~ m{(.*)} and $1}
use base qw/File::Spec/;

my (@libdir);

if ((my $p = List::MoreUtils::last_index
     (sub {$_ eq 'YATT'}
      , my @d = MY->splitdir($dir))) >= 0) {
  push @libdir, MY->catdir(@d[0 .. ($p-1)]);
}

if (-d (my $d = "$dir/../blib/lib")."/YATT") {
  push @libdir, $d;
}

my $hook = sub {
  my ($this, $orig_modfn) = @_;
  return unless (my $modfn = $orig_modfn) =~ s!^YATT/!!;
  Carp::cluck("orig_modfn=$orig_modfn\n") if $ENV{DEBUG_INC};
  return unless -r (my $realfn = "$dir/../$modfn");
  warn "=> found $realfn" if $ENV{DEBUG_INC};
  open my $fh, '<', $realfn or die "Can't open $realfn:$!";
  $fh;
};

unshift @INC, $hook;

my $ins = $INC[$#INC] eq "." ? $#INC : @INC;
splice @INC, $ins, 0, $hook, $hook;
# XXX: Why I need to put this into @INC-hook 3times?!

require lib;

if (@libdir) {
  import lib @libdir;

  print STDERR join("\n", @libdir), "\n" if $ENV{DEBUG_INC};
}

# Should returns $dist_root

return "$dir/..";
