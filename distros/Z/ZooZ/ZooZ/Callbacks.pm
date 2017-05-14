
package ZooZ::Callbacks;

# this package takes care of registering and keeping
# track of callbacks. Ideally, only one callback object
# needs to be created per project which contains all
# the information of all registered callbacks.
# By callbacks, I really mean subroutines.

use strict;
use base qw/ZooZ::Base/;

my %CODE2NAME;    # hash to associate CODE(0xFFFF) with its sub name.

1;

sub new {
  my ($class) = @_;

  my $self    = bless {
		       CB => {},
		       I  => 0, # just an index
		      } => $class;

  return $self;
}

sub add {
  my ($self, $name, $code) = @_;

  $self->{CB}{$name} = $code;
}

sub remove  {
  my ($self, $name) = @_;

  delete $self->{CB}{$name};
  $self->removeWidget($name);
}

sub rename  {
  my ($self, $old, $new) = @_;

  $self->{CB}{$new} = delete $self->{CB}{$old};
}

sub code {
  my ($self, $name, $code) = @_;

  $self->{CB}{$name} = $code if $code;
  return $self->{CB}{$name};
}

sub index   { $_[0]->{I}++        }
sub listAll { keys %{$_[0]->{CB}} }

sub newName {
  my $self = shift;

  my $i = $self->index;
  return "_Subroutine_$i";
}

sub CallbackExists { exists $_[0]{CB}{$_[1]} }

########################

sub name2code {
  my ($class, $name, $code) = @_;

  $CODE2NAME{$code} = $name;
}

sub code2name { $CODE2NAME{$_[1]} }
