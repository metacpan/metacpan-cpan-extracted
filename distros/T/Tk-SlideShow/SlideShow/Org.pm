package Tk::SlideShow::Org;
@Tk::SlideShow::Org::ISA = qw(Tk::SlideShow::Link);

sub New {
  my $class = shift;
  my $s = $class->SUPER::New(@_);
  $s->{'fpos'} = 5;
  $s->{'tpos'} = 1;
  bless $s;
}

sub trace_link {
  my ($s,$fx,$fy,$tx,$ty) = @_;
  my $id = $s->id;

  my $midy = int(($fy+$ty)/2);
  my $can = Tk::SlideShow->canvas;
  $s->{'lineid'} = $can->createLine($fx,$fy,$fx,$midy,$tx,$midy,$tx,$ty,-tags,$id);
  return $s;
}

sub redraw {
  my ($s,$fx,$fy,$tx,$ty) = @_;
  my $id = $s->id;

  my $midy = int(($fy+$ty)/2);
  my $c = Tk::SlideShow->canvas;
  $c->coords($s->{'lineid'},$fx,$fy,$fx,$midy,$tx,$midy,$tx,$ty);
  return $s;
}  

1;
