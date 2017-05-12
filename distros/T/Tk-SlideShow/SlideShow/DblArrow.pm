package Tk::SlideShow::DblArrow;

@Tk::SlideShow::DblArrow::ISA = qw(Tk::SlideShow::Arrow);

sub New {
  my $class = shift;
  my $s = $class->SUPER::New(@_);
  $s->{'-arrowoptions'}[1] = 'both';
  bless $s;
  $s->trace_link(-100,-100,-10,-10);
  return $s;
}
1;
