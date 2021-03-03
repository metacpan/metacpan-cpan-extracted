package Valiant::Validator::Check;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has constraint => (is=>'ro', required=>1, isa=>sub {shift->can('check')});
has check => (is=>'ro', required=>1, default=>sub {_t 'check'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return {constraint => $arg};
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_; 
  my $check_constraint_proto = $self->_cb_value($record, $self->constraint);
  my @check_constraints = (ref($check_constraint_proto)||'') eq 'ARRAY' ?
    @$check_constraint_proto : 
      ($check_constraint_proto);

  foreach my $check_constraint (@check_constraints) {
    unless($check_constraint->check($value)) {
      $record->errors->add($attribute, $self->check, $opts)
    }
  }
}

1;

=head1 NAME

Valiant::Validator::Check - Validate using a 'check' method

=head1 SYNOPSIS

    package Local::Test::Check;

    use Moo;
    use Valiant::Validations;
    use Types::Standard 'Int';

    has retiree_age => (is=>'ro');

    validates retiree_age => (
      check => {
        constraint => Int->where('$_ >= 65')
      }
    );
 
    my $object = Local::Test::Check->new(retiree_age=>40);
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'retiree_age' => [
        'Retiree age is invalid'
      ] 
    };

=head1 DESCRIPTION

Let's you use an object that does C<check> as the validation method.  Basically
this exists to let you use or reuse a lot of existing type constraint validation
libraries on CPAN such as L<Type::Tiny>. You might already be making heavy use of
these in your code (or you might just be very familiar with them) so it it might
make sense to you to just reuse them rather than learn a bunch of the custom
validators that are packaged with L<Valiant>.

You might also prefer the 'spellchecking' safety of something like L<Type::Tiny>
which uses imported methods and will result in a compile time error if you 
mistype the constraint name.  Its also possible some of the XS versions of
L<Type::Tiny> are faster then the built in validators that ship with L<Valiant>

Please note this validator is also a available as a shortcut which is built into
the C<validates> method itself:

    validates retiree_age => (
      Int->where('$_ >= 65'), +{
        message => 'A retiree must be at least 65 years old,
      },
      ...
    );

This built in shortcut just wraps this validator under the hood.  I saw no reason
to not expose it publically but its less typing to just use the short method.

=head1 ATTRIBUTES

This validator supports the following attributes

=head2 constraint

Takes an object or arrayref of objects that can provide a C<check> method which given
the value to be checked will return true if the value is valid and false otherwise.

Supports coderef for dynamically providing a constraint.

=head2 check

Either a translation tag or a string message for the error given when the validation fails.
Defaults to "_t('check')".

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( check => Int->where('$_ >= 65'), ... );

Which is the same as:

    validates attribute => (
      check => {
        constraint => Int->where('$_ >= 65'),
      },
      ...
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
