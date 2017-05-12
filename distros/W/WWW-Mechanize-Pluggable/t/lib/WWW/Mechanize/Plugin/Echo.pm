package WWW::Mechanize::Plugin::Echo;
use strict;

sub init {
  my ($class, $pluggable, %args)  = @_;
  local $_;
  {
    no strict 'refs';
    *{'WWW::Mechanize::Pluggable::preserved'} = \&preserved;
  }
  if ($args{Echo}) {
    $pluggable->preserved( "Echo => $args{Echo}");
  }
  return;
}

sub preserved {
  my ($self, @fmtargs) = @_;
  $self->{Preserved} = "@fmtargs" if @fmtargs;
  return $self->{Preserved};
}

1;
