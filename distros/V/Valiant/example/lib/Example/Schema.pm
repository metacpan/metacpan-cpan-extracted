package Example::Schema;

use base 'DBIx::Class::Schema';

use strict;
use warnings;

our $VERSION = 1;

__PACKAGE__->load_components(qw/
  Helper::Schema::QuoteNames
  Helper::Schema::DidYouMean
  Helper::Schema::DateTime/);

__PACKAGE__->load_namespaces(
  default_resultset_class => "DefaultRS");

#use DBIx::Class::Storage::Debug::PrettyPrint;
#my $pp = DBIx::Class::Storage::Debug::PrettyPrint->new({ profile => 'console' });

sub debug {
  my ($self) = @_;
  #<D-d>  $self->storage->debugobj($pp);
  $self->storage->debug(1);
  return $self;
}

sub debug_off {
  my ($self) = @_;
  $self->storage->debugobj(undef);
  $self->storage->debug(0);
  return $self;
}


1;
