use strict;
use warnings;
use File::Spec;
use File::Basename;

my @dir = do {
  if ($ENV{DEBUG_INC}) {
    print STDERR "\$0=$0, rel2abs->", File::Spec->rel2abs($0), "\n";
  }
  my @d = (
    $_[0],
    dirname(File::Spec->rel2abs($0)),
    (-r $0 and -l $0) ? (
      dirname(File::Spec->rel2abs(readlink($0), dirname($0))),
    ) : (),
    $FindBin::Bin,
    $FindBin::Bin, # Just to avoid warning.
  );
  Carp::cluck("d=".join(", ", map {$_ // 'undef'} @d)) if $ENV{DEBUG_INC};
  my %dup;
  map {defined $_ && -d $_ && !$dup{$_}++ ? untaint_any($_) : ()} @d;
};

unless (@dir) {
  Carp::croak("Can't find bindir!");
}

Carp::cluck("dir=@dir\n") if $ENV{DEBUG_INC};

sub MY () {__PACKAGE__}
sub untaint_any {$_[0] =~ m{(.*)} and $1}
use base qw/File::Spec/;

my (@libdir);

foreach my $dir (@dir) {
  if (grep {$_ eq 'YATT'} MY->splitdir($dir)) {
    push @libdir, dirname(dirname($dir));
  }

  if (-d (my $d = "$dir/../blib/lib")."/YATT") {
    push @libdir, $d;
  }
}

my $hook = sub {
  my ($this, $orig_modfn) = @_;
  return unless (my $modfn = $orig_modfn) =~ s!^YATT/!!;
  Carp::cluck("orig_modfn=$orig_modfn\n") if $ENV{DEBUG_INC};
  return unless -r (my $realfn = "$dir[0]/../$modfn");
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

return "$dir[0]/..";
