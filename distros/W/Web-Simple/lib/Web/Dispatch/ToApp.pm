package Web::Dispatch::ToApp;

use Moo::Role;

requires 'call';

sub to_app {
  my ($self) = @_;
  sub { $self->call(@_) }
}

1;
