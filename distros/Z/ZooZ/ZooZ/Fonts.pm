
package ZooZ::Fonts;

use strict;

sub new {
  my $class = shift;

  my $self  = bless {
		     FONTS => {},
		     I     => 0,
		     } => $class;

  return $self;
}

sub add {
  my ($self, $name, $obj) = @_;

  $self->{FONTS}{$name} = $obj;
}

sub remove     { delete $_[0]{FONTS}{$_[1]} }
sub listAll    { keys %{$_[0]{FONTS}}       }
sub obj        { $_[0]{FONTS}{$_[1]}        }
sub FontExists { exists $_[0]{FONTS}{$_[1]} }
sub index      { $_[0]->{I}++ }

sub newName {
  my $self = shift;

  my $i = $self->index;
  return "_Font_$i";
}

1;

