package Valiant::Validator;

use Moo::Role;

requires 'validate';

1;

=head1 NAME

Valiant::Validator - A role to define the validator interface.

=head1 SYNOPSIS

    package MySpecialValidator;

    use Moo;
    with 'Valiant::Validator';

    sub validate {
      my ($self, $object, $options) = @_;
      # DO your custom validation here.  Remember if you want to support
      # strict and message you should pass $options to any errors:
      # $object->errors->add('_base', 'Invalid', $options);
      # This method doesn't have to return anything in particular.
    }

=head1 DESCRIPTION

This is a base role for defining a validator.  This should be a class that
defines a C<validate> method. Here's a more detailed example that shows
using a custom validator with a validatable object:

    package Local::Test::Validator::Box;

    use Moo;
    with 'Valiant::Validator';

    has max_size => (is=>'ro', required=>1);

    sub validate {
      my ($self, $record, $opts) = @_;
      my $size = $record->height + $record->width + $record->length;
      if($size > $self->max_size) {
        $record->errors->add(_base=>"Total of all size cannot exceed ${\$self->max_size}", $opts),
      }
    }

    package Local::Test::Box;

    use Moo;
    use Valiant::Validations;

    has [qw(height width length)] => (is=>'ro', required=>1);

    validates [qw(height width length)] => (numericality=>+{});

    validates_with 'Box', max_size=>25;
    validates_with 'Box', max_size=>50, on=>'big', message=>'Big for Big!!';
    validates_with 'Box', max_size=>30, on=>'big', if=>'is_very_tall';

    sub is_very_tall {
      my ($self) = @_;
      return $self->height > 30 ? 1:0;
    }

When used with C<validates_with> we filter any extra arguments outside the globals
(C<on>, C<if/unless>, C<message>, C<strict>) and pass them as init args when creating
the validator.

A Validator is created once when the class uses it and exists for the full life cycle
of the validatable object.

Generally you would write a validator class like this when the validation is very complex
and cannot be tied to a specific attribute.  If it can be tied to an attribute then you
might prefer to use   L<Valiant::Validator::Each>.

=head1 PREPACKAGED VALIDATOR CLASSES

The following attribute validator classes are shipped with L<Valiant>.  Please see the package POD for
usage details (this is only a sparse summary)

=head2 Absence

Checks that a value is absent (undefinef or empty).

See L<Valiant::Validator::Absence> for details.

=head2 Array

Validations on an array value.  Has options for nested errors when the array contains objects that
themselves are validatible.

See L<Valiant::Validator::Array> for details.

=head2 Boolean

Returns errors messages based on the boolean state of an attribute.

See L<Valiant::Validator::Boolean> for details.

=head2 Check

Use your existing L<Type::Tiny> constraints with L<Valiant>

See L<Valiant::Validator::Check> for details.

=head2 Confirmation

Add a confirmation error check.  Used for when you want to verify that a given field is correct
(such as when a user submits a new password or an email address).

See L<Valiant::Validator::Confirmation> for details.

=head2 Date

Value must conform to standard date format (default is YYYY-MM-DD or eg 2000-01-01) and be a valid date.

See L<Valiant::Validator::Date> for details.

=head2 Exclusion

Value cannot match a fixed list.

See L<Valiant::Validator::Exclusion> for details.


=head2 Format

Value must be a string tht matched a given format or regular expression.

See L<Valiant::Validator::Format> for details.

=head2 Inclusion

Value must be one of a fixed list

See L<Valiant::Validator::Inclusion> for details.

=head2 Length

Value must be a string with given minimum and maximum lengths.

See L<Valiant::Validator::Length> for details.

=head2 Numericality

Validate various types of numbers.

See L<Valiant::Validator::Numericality> for details.

=head2 Object

Value is an object.  Allows one to have nested validations when the object itself can be validated.

See L<Valiant::Validator::Object> for details.

=head2 OnlyOf

Validates that only one or more of a group of attributes is defined.  

See L<Valiant::Validator::OnlyOf> for details.

=head2 Presence

That the value is defined and not empty

See L<Valiant::Validator::Absence> for details.

=head2 Unique

That the value is unique based on some custom logic that your class must provide.

See L<Valiant::Validator::Unique> for details.

=head2 With

Use a subroutine reference or the name of a method on your class to provide validation.

See L<Valiant::Validator::With> for details.

=head2 Special Validators

The following validators are not considered for end users but have documentation you might
find useful in furthering your knowledge of L<Valiant>:  L<Valiant::Validator::Collection>,
L<Valiant::Validator::Each>.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Validator::Each>.
=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
