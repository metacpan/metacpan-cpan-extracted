package pragmatic;
$VERSION = 1.0;

bootstrap xsub;

use xsub _refcount => q($), q{
  SV *sv = argv[0];
  if (SvROK(sv)) {
    SV *rv = SvRV(sv);
    return newSVuv(SvREFCNT(rv));
  } else {
    return &PL_sv_undef;
  }
};

sub DESTROY {
  my $x = shift;
  my ($p, $b, $last) = splice @$x;
  $last or return $p->disable;
  _refcount($last) > 1 or return;
  $$last[1] ? $p->enable : $p->disable
}

sub enable($) {
  1
}

sub disable($) {
  ''
}

sub enabled($) {
  my $p = shift;
  !!($^H{$p} && ${$^H{$p}}[1])
}

sub disabled($) {
  !shift->enabled
}

sub import($;) {
  my $p = shift;
  $^H |= 0x20000;
  local *DESTROY = sub { };
  $^H{$p} = bless [$p, 1, delete $^H{$p}];
  $p->enable
}

sub unimport($;) {
  my $p = shift;
  $^H |= 0x20000;
  local *DESTROY = sub { };
  $^H{$p} = bless [$p, 0, delete $^H{$p}];
  $p->disable
}

1
