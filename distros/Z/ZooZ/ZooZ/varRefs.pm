
package ZooZ::varRefs;

# this package takes care of registering and keeping
# track of variables. Ideally, only one varRef object
# needs to be created per project which contains all
# the information of all registered variables.

use strict;

my %REF2NAME;

sub new {
  my ($class) = @_;

  my $self    = bless {
		       VR => {},
		       I  => 0, # just an index
		      }   => $class;

  return $self;
}

sub add {
  my ($self, $name) = @_;

  $self->{VR}{$name} = 1;
}

sub remove  { delete $_[0]->{VR}{$_[1]} }
sub listAll { keys %{$_[0]->{VR}}       }

sub rename  {
  my ($self, $old, $new) = @_;

  $self->{VR}{$new} = delete $self->{VR}{$old};
}

sub index   { $_[0]->{I}++ }

sub newName {
  my $self = shift;

  my $i = $self->index;
  return "_Variable_$i";
}

sub varRefExists { exists $_[0]{CB}{$_[1]} }

####################

sub name2ref {
  my ($class, $name, $ref) = @_;

  $REF2NAME{$ref} = $name;
}

sub ref2name { $REF2NAME{$_[1]} }

1;
