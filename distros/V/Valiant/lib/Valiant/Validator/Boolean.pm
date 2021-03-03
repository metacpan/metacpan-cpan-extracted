package Valiant::Validator::Boolean;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has state => (is=>'ro', required=>1);
has is_not_true => (is=>'ro', required=>1, default=>sub {_t 'is_not_true'});
has is_not_false => (is=>'ro', required=>1, default=>sub {_t 'is_not_false'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ state => $arg };
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;
  my $state = $self->_cb_value($record, $self->state);

  if($state) {
    # value must be true
    unless($value) {
      $record->errors->add($attribute, $self->is_not_true, $opts);
    }
  } else {
    # value must be false
    if ($value) {
      $record->errors->add($attribute, $self->is_not_false, $opts);
    }
  }
}

1;

=head1 NAME

Valiant::Validator::Boolean - Verify that a value is either true or false

=head1 SYNOPSIS

    package Local::Test::Boolean;

    use Moo;
    use Valiant::Validations;

    has active => (is=>'ro');

    validates active => (
      boolean => {
        state => 1, # valid values are 1 (must be true) or 0 (must be false)
      }
    );

    my $object = Local::Test::Boolean->new(active=>0);
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'active' => [
         'Active must be true',
      ]
    };

=head1 DESCRIPTION

Checks a value to see if it is true or false based on Perl's notion of
truthiness.  This will not limit the value.  For example values of 1, 'one'
and [1,2,3] are considered true while values of 0, undef are false.

=head1 ATTRIBUTES

This validator supports the following attributes:

=head2 state

The required boolean value of the given value for the validator to pass.
Allowed values are 1 (which requires true) and 0 (which requires false).

Value may also be a coderef.

=head2 is_not_true

The error message / tag used when the value is not true

=head2 is_not_false

The error message / tag used when the value is not false

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( boolean => 1, ... );

Which is the same as:

    validates attribute => (
      boolean => {
        state => 1,
      }
    );

The negation of this also works

    validates attribute => ( boolean => 0, ... );

Which is the same as:

    validates attribute => (
      boolean => {
        state => 0,
      }
    );

=head1 GLOBAL PARAMETERS

This validator supports all the standard shared parameters: C<if>, C<unless>,
C<message>, C<strict>, C<allow_undef>, C<allow_blank>.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Validator>, L<Valiant::Validator::Each>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
