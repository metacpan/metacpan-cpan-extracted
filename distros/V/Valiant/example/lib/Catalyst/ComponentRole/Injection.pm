package Catalyst::ComponentRole::Injection;

use Moo::Role;
 
our $VERSION = '0.001';
 
around 'has', sub {
  my ($orig, $self, @args) = @_;
  use Devel::Dwarn;
  Dwarn '.......... ' x10;
  Dwarn \@_;
  return $self->$orig(@args);
};
 
1
