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

if (not -e "$FindBin::Bin/t_lib.pl" and not defined $_[0]) {
  print STDERR "# Subdirectory tests should set \@_ to t_lib.pl\n";
  exit 1;
}

use File::Basename;
sub untaint_any {$_[0] =~ m{(.*)} and $1}
use base qw/File::Spec/;

my (@libdir);

if ((my $p = List::MoreUtils::last_index
     (sub {$_ eq 'YATT'}
      , my @d = MY->splitdir($dir))) >= 0) {
  my @outer_dir = @d[0 .. ($p-1)];
  push @libdir, MY->catdir(@outer_dir);
  if ($outer_dir[-1] eq 'lib'
      and -d (my $local_lib = MY->catdir(@outer_dir[0..$#outer_dir-1], qw(local lib perl5)))) {
    push @libdir, $local_lib;
  }
}

if (-d (my $d = "$dir/../blib/lib")."/YATT") {
  push @libdir, $d;
}

my $hook = sub {
  my ($this, $orig_modfn) = @_;
  return unless (my $modfn = $orig_modfn) =~ s!^YATT/!!;
  Carp::cluck("orig_modfn=$orig_modfn, dir=$dir, modfn=$modfn\n") if $ENV{DEBUG_INC};
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
