package Valence::Object;

use common::sense;

use Scalar::Util;


our $AUTOLOAD;

use overload fallback => 1,
             '&{}' => \&_valence_invoke_as_sub;


sub _valence_new {
  my ($class, %args) = @_;

  my $self = {
    valence => $args{valence},
  };

  $self->{id} = $self->{valence}->{next_object_id}++;

  $self->{valence}->{object_map}->{$self->{id}} = $self;
  Scalar::Util::weaken $self->{valence}->{object_map}->{$self->{id}};

  bless $self, $class;

  return $self;
}




sub AUTOLOAD {
  my $self = shift;

  die "$self is not an object" if !ref $self;

  my $name = $AUTOLOAD;
  $name =~ s/.*://;

  return $self->{valence}->_call_method({
    method => $name,
    obj => $self->{id},
    args => \@_,
  });
}




sub _valence_invoke_as_sub {
  my $self = shift;

  return sub {
    my $cb = shift;

    my $callback_id = $self->{valence}->{next_callback_id}++;

    $self->{valence}->{callback_map}->{$callback_id} = sub {
      delete $self->{valence}->{callback_map}->{$callback_id};

      $cb->(@_);
    };

    $self->{valence}->_send({
      cmd => 'get',
      cb => $callback_id,
      obj => $self->{id},
    });
  };
}




sub attr {
  my ($self, $key) = @_;

  return $self->{valence}->_get_attr({
    attr => $key,
    obj => $self->{id},
  });
}



sub DESTROY {
  my ($self) = @_;

  $self->{valence}->_send({
    cmd => 'destroy',
    obj => $self->{id},
  });

  delete $self->{valence}->{object_map}->{$self->{id}};
}


1;
