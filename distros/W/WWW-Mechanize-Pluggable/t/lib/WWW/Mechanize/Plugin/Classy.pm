package WWW::Mechanize::Plugin::Classy;
use strict;

sub import {
  my ($class, $pluggable, %args)  = @_;
  local $_;
  {
    no strict 'refs';
    *WWW::Mechanize::Pluggable::classy = sub { "Hey, I got class!" };
  }
  return 1;
}

1;
