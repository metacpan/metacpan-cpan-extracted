package Validator::Custom::Validation;
use Object::Simple -base;

use Carp 'croak';

sub new {
  my $self = shift->SUPER::new(@_);
  
  $self->{_failed_infos} = {};
  
  return $self;
}

sub is_valid {
  my ($self, $name) = @_;
 
  if (defined $name) {
    return exists $self->{_failed_infos}->{$name} ? 0 : 1;
  }
  else {
    return !(keys %{$self->{_failed_infos}}) ? 1 : 0;
  }
}

sub add_failed {
  my ($self, $name, $message) = @_;
  
  my $failed_infos = $self->{_failed_infos};
  
  if ($failed_infos->{$name}) {
    croak "\"$name\" is already exists";
  }
  
  my @failed_names = keys %$failed_infos;
  my $pos;
  if (@failed_names) {
    my $max_pos = 0;
    for my $failed_name (@failed_names) {
      my $pos = $failed_infos->{$failed_name}{pos};
      if ($pos > $max_pos) {
        $max_pos = $pos;
      }
    }
    $pos = $max_pos + 1;
  }
  else {
    $pos = 0;
  }
  
  $failed_infos->{$name}{pos} = $pos;
  
  unless (defined $message) {
    $message = "$name is invalid";
  }
  $failed_infos->{$name}{message} = $message;
  $failed_infos->{$name}{pos} = $pos;
  
  return $self;
}

sub failed {
  my $self = shift;
  
  my $failed_infos = $self->{_failed_infos};
  my @failed = sort { $failed_infos->{$a}{pos} <=>
    $failed_infos->{$b}{pos} } keys %$failed_infos;
  
  return \@failed;
}

sub message {
  my ($self, $name) = @_;
  
  # Parameter name not specified
  croak 'Parameter name must be specified'
    unless $name;
  
  return $self->{_failed_infos}{$name}{message};
}

sub messages {
  my $self = shift;

  my $failed_infos = $self->{_failed_infos};

  # Messages
  my $messages = [];
  for my $name (@{$self->failed}) {
    my $message = $failed_infos->{$name}{message};
    push @$messages, $message;
  }
  
  return $messages;
}

sub messages_to_hash {
  my $self = shift;
  
  my $failed_infos = $self->{_failed_infos};
  
  # Name and message hash
  my $messages = {};
  for my $name (keys %$failed_infos) {
    $messages->{$name} = $failed_infos->{$name}{message};
  }
  
  return $messages;
}

1;

=head1 NAME

Validator::Custom::Validation - a result of validation

=head1 SYNOPSYS

  my $validation = $vc->validation;
  
  $validation->add_failed(title => 'title is invalid');
  $validation->add_failed(name => 'name is invalid');
  
  # Is valid
  my $is_valid = $validation->is_valid;
  my $title_is_valid = $validation->is_valid('title');
  
  # Get all failed parameter names
  my $failed = $validation->failed;
  
  # Message
  my $messages = $validation->messages;
  my $title_message = $validation->message('title');
  my $messages_h = $validation->messages_to_hash;

=head1 METHODS

L<Validator::Custom::Validation> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 new

  my $validation = Validator::Custom::Validation->new;
  
Create a L<Validator::Custom::Validation> object.

Generally this method is not used. You should use C<validation> method of L<Validator::Custom>.

  my $validation = $vc->validation;

=head2 is_valid

  my $is_valid = $validation->is_valid;
  my $is_valid = $validation->is_valid('title');

Check if the result of validation is valid.
If name is specified, check if the parameter corresponding to the name is valid.

=head2 add_failed

  $validation->add_failed('title' => 'title is invalid value');
  $validation->add_failed('title');

Add a failed parameter name and message.
If message is omitted, default message is set automatically.

=head2 failed

  my $failed = $validation->failed;

Get all failed parameter names.

=head2 message

  my $message = $validation->message('title');

Get a failed message corresponding to the name.

=head2 messages

  my $messgaes = $validation->messages;

Get all failed messages.

=head2 messages_to_hash

  my $messages_h = $validation->messages_to_hash;

Get all failed parameter names and messages as hash reference.
