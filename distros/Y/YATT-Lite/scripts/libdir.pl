use strict;
use warnings;
use File::Spec;
use File::Basename;

my $dir = do {
  my $d = $_[0] ||
    do {
      if (-r $0 and -l $0) {
	# Resolve symlink just once.
	dirname(File::Spec->rel2abs(readlink($0), dirname($0)))
      } else {
	$FindBin::Bin
      }
    }
    or die "bindir is empty!";
  $d //= $FindBin::Bin; # To suppress warning.
  untaint_any($d);
};

Carp::cluck("dir=$dir\n") if $ENV{DEBUG_INC};

sub MY () {__PACKAGE__}
sub untaint_any {$_[0] =~ m{(.*)} and $1}
use base qw/File::Spec/;

my (@libdir);

if (grep {$_ eq 'YATT'} MY->splitdir($dir)) {
  push @libdir, dirname(dirname($dir));
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
