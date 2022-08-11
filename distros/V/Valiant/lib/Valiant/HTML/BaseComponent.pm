package Valiant::HTML::BaseComponent;

use Moo::Role;
use Valiant::HTML::SafeString 'concat';

our $SELF = 0;

requires 'render';

has container => (is=>'ro', predicate=>'has_container');
has parent => (is=>'ro', predicate=>'has_parent');

around render => sub {
  my ($orig, $self) = (shift, shift);
  my @args = $self->prepare_render_args(@_);
  return $self->_do_render($orig, @args);
};

sub _do_render {
  my ($self, $orig, @args ) = @_;

  local $SELF = $self;
  my @rendered = map {
    $_->can('render') ? $_->render : $_;
  } grep {
    defined $_ && ($_ ne '');
  }$self->$orig(@args);

  return concat(@rendered);
}

sub prepare_render_args {
  my ($self, @args) = @_;
  return @args;
}

1;
