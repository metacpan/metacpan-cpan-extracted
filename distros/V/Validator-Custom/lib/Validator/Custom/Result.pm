# Version 0 module
package Validator::Custom::Result;
use Object::Simple -base;

use Carp 'croak';

# Attrbutes
has data => sub { {} };
has raw_data  => sub { {} };
has missing_params => sub { [] };

sub is_valid {
  my ($self, $name) = @_;
 
  if (defined $name) {
    return exists $self->{_error_infos}->{$name} ? 0 : 1;
  }
  else {
    return !(keys %{$self->{_error_infos}}) ? 1 : 0;
  }
}

sub message {
  my ($self, $name) = @_;
  
  # Parameter name not specified
  croak 'Parameter name must be specified'
    unless $name;
  
  return $self->{_error_infos}->{$name}{message}
    || $self->{_default_messages}{$name}
    || 'Error message not specified';
}

sub messages {
  my $self = shift;

  # Error messages
  my @messages;
  my $error_infos = $self->{_error_infos};
  my @keys = sort { $error_infos->{$a}{position} <=>
    $error_infos->{$b}{position} } keys %$error_infos;
  foreach my $name (@keys) {
    my $message = $self->message($name);
    push @messages, $message;
  }
  
  return \@messages;
}

sub messages_to_hash {
  my $self = shift;

  # Error messages
  my $messages = {};
  foreach my $name (keys %{$self->{_error_infos}}) {
    $messages->{$name} = $self->message($name);
  }
  
  return $messages;
}

sub is_ok {
  my $self = shift;
  
  # Is ok?
  return !$self->has_invalid && !$self->has_missing ? 1 : 0;
}

sub to_hash {
  my $self = shift;
  
  # Result
  my $result = {};
  $result->{ok}      = $self->is_ok;
  $result->{invalid} = $self->has_invalid;
  $result->{missing} = $self->has_missing;
  $result->{missing_params} = $self->missing_params;
  $result->{messages} = $self->messages_to_hash;
  
  return $result;
}

sub invalid_rule_keys {
  my $self = shift;
  
  # Invalid rule keys
  my $error_infos = $self->{_error_infos};
  my @invalid_rule_keys = sort { $error_infos->{$a}{position} <=>
    $error_infos->{$b}{position} } keys %$error_infos;
  
  return \@invalid_rule_keys;
}

sub has_missing { @{shift->missing_params} ? 1 : 0 }

sub has_invalid {
  my $self = shift;
  
  # Has invalid parameter?
  return keys %{$self->{_error_infos}} ? 1 : 0;
}

sub loose_data {
  my $self = shift;
  return {%{$self->raw_data}, %{$self->data}};
}

sub invalid_params {
  my $self = shift;
  
  # Invalid parameter names
  my @invalid_params;
  foreach my $name (@{$self->invalid_rule_keys}) {
      my $param = $self->{_error_infos}->{$name}{original_key};
      $param = [$param] unless ref $param eq 'ARRAY';
      push @invalid_params, @$param;
  }
  
  return \@invalid_params;
}


# DEPRECATED!
sub error_reason {

  warn "Validator::Custom::Result error_reason is DEPRECATED!.";

  my ($self, $name) = @_;
  
  # Parameter name not specified
  croak 'Parameter name must be specified'
    unless $name;
  
  # Error reason
  return $self->{_error_infos}->{$name}{reason};
}

# DEPRECATED!
has error_infos => sub { {} };
# DEPRECATED!
sub add_error_info {
  my $self = shift;
  warn "add_error_info method is DEPRECATED!";
  # Merge
  my $error_infos = ref $_[0] eq 'HASH' ? $_[0] : {@_};
  $self->error_infos({%{$self->error_infos}, %$error_infos});
  return $self;
}
# DEPRECATED!
sub error {
  warn "error_info method is DEPRECATED!";
  shift->message(@_)
}
# DEPRECATED!
sub errors { 
  warn "errors method is DEPRECATED!";
  return wantarray
       ? @{shift->messages(@_)}
       : shift->messages(@_);
}
# DEPRECATED!
sub errors_to_hash {
  warn "errors_to_hash method is DEPRECATED!";
  shift->messages_to_hash(@_)
}
# DEPRECATED!
sub invalid_keys {
  warn "invalid_keys method is DEPRECATED!";
  return wantarray
     ? @{shift->invalid_rule_keys(@_)}
     : shift->invalid_rule_keys(@_);
}
# DEPRECATED!
sub remove_error_info {
  my ($self, $key) = @_;
  warn "remove_error_info method is DEPRECATED!";
  # Remove
  delete $self->error_infos->{$key};
  return $self;
}

1;

=head1 NAME

Validator::Custom::Result - Result of validation

=head1 SYNOPSYS
    
  # Result
  my $result = $vc->validate($data, $rule);

  # Safety data
  my $safe_data = $result->data;

  # Chacke if the result is valid.
  # (this means result have neither missing nor invalid parameter)
  my $is_ok = $result->is_ok;

  # Check the existence of missing parameter
  my $has_missing_param = $result->has_missing;
  
  # Check if one parameter is valid
  my $title_is_valid = $result->is_valid('title');

  # Missing parameters(this is original keys)
  my $missing_params = $result->missing_params;
  
  # Invalid parameter names(this is original keys)
  my $invalid_params = $result->invalid_params;
  
  # Invalid rule keys
  my $invalid_rule_keys = $result->invalid_rule_keys;

  # A error message
  my $message = $result->message('title');

  # Error messages
  my $messages = $result->messages;

  # Error messages to hash ref
  my $messages_hash = $result->message_to_hash;
  
  # Result to hash
  my $rhash = $result->to_hash;
  
  # Raw data
  my $raw_data = $result->raw_data;
  

=head1 ATTRIBUTES

=head2 data

  my $data = $result->data;
  $result  = $result->data($data);

Get the data in the end state. L<Validator::Custom> has filtering ability
if you need.
The data passed to C<validate()> is converted to other data by filter.
You can get filtered data using C<data()>.

=head2 missing_params

  my $missing_params = $result->missing_params;
  $result            = $result->missing_params($missing_params);

You can get missing parameter names using C<missing_params()>.
In this example, return value is the following one.

=head2 raw_data

  my $data  = $result->raw_data;
  $result   = $result->raw_data($data);

Raw data soon after data_filter is executed.

=head1 METHODS

L<Validator::Custom::Result> inherits all methods from L<Object::Simple>
and implements the following new ones.

=head2 has_invalid

  my $has_invalid = $result->has_invalid;

If at least one of parameter value is invalid,
C<has_invalid()> return true value.

=head2 has_missing

  my $has_missing_param = $result->has_missing;

If at least one of parameter names specified in the rule
is not found in the data,
C<has_missing()> return true value.

=head2 invalid_params

  my $invalid_params = $result->invalid_params;

Invalid raw data parameter names.

=head2 invalid_rule_keys

  my $invalid_rule_keys = $result->invalid_rule_keys;

Invalid rule keys

=head2 is_ok

  my $is_ok = $result->is_ok;

If you check the data is completely valid, use C<is_ok()>.
C<is_ok()> return true value
if invalid parameter values is not found and all parameter
names specified in the rule is found in the data.

=head2 is_valid

  my $title_is_valid = $result->is_valid('title');

Check if one parameter is valid.

=head2 loose_data

  my $loose_data = $result->loose_data;

Loose data, which is data merged C<raw_data> and C<data>

  # Loose data
  {%{$self->raw_data}, %{$self->data}}

=head2 message

  my $message = $result->message('title');

Get a message corresponding to the parameter name which value is invalid.

=head2 messages

  my $messages = $result->messages;

Get messages corresponding to the parameter names which value is invalid.
Messages keep the order of parameter names of the rule.

=head2 messages_to_hash

  my $messages = $result->messages_to_hash;

You can get the pairs of invalid parameter name and message
using C<messages_to_hash()>.

=head2 to_hash

  my $rhash = $result->to_hash;

Convert result information to hash reference.
The following keys is set.

  {
    ok =>      $result->is_ok,
    missing => $result->has_missing,
    invalid => $result->has_invalid,
    missing_params => $result->missing_params,
    messages => $result->messages_to_hash
  }

=cut
