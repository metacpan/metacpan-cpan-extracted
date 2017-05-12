package Text::Tradition::Store;
use Moose;
use Class::Load ();
extends 'KiokuDB';

has resolver_class =>
  ( is => 'rw', isa => 'Str', default => 'KiokuDB::TypeMap::Resolver' );
has resolver_constructor =>
  ( is => 'rw', isa => 'Str|CodeRef', default => 'new' );

override _build_typemap_resolver => sub {
  my ($self) = @_;
  my $rclass = $self->resolver_class;
  Class::Load::load_class($rclass);
  my $meth = $self->resolver_constructor;
  return $rclass->$meth;
};

1;
