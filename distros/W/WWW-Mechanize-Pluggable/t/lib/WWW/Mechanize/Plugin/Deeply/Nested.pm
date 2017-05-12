package WWW::Mechanize::Plugin::Deeply::Nested;
use strict;
use warnings;

sub init {
  no strict 'refs';
  *{caller() . '::nested'} = \&nested;
}

sub nested {
   my ($self) = shift;
   $self->{Mech}->{content} = 'nested';
}

1;
