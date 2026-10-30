# Minimal stand-in for a HiD page/post object, exposing only the
# interface that byterazor::HiD::LLMS uses.

package Test::LLMS::Entry;

use Moose;

use 5.014; # strict, unicode_strings

has url => (
  is       => 'ro' ,
  isa      => 'Str' ,
  required => 1 ,
);

# Post title (present on HiD::Post; absent on HiD::Page).
has title => (
  is  => 'ro' ,
  isa => 'Str' ,
);

# Present on posts (a DateTime); absent on pages.
has date => (
  is  => 'ro' ,
  isa => 'DateTime' ,
);

# YAML front matter.
has metadata => (
  is      => 'ro' ,
  isa     => 'HashRef' ,
  default => sub {{}} ,
);

# Raw content (the part of the file after the YAML front matter).
has content => (
  is  => 'ro' ,
  isa => 'Str' ,
);

sub get_metadata {
  my( $self , $key ) = @_;
  return $self->metadata->{$key};
}

__PACKAGE__->meta->make_immutable;
1;
