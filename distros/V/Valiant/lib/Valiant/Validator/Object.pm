package Valiant::Validator::Object;

use Moo;
use Valiant::I18N;
use Scalar::Util 'blessed';

require Role::Tiny;

with 'Valiant::Validator::Each';

has type_constraint => (is=>'ro', required=>0, predicate=>'has_type_constraint');
has isa => (is=>'ro', required=>0, predicate=>'has_isa');
has role => (is=>'ro', required=>0, predicate=>'has_role');
has nested => (is=>'ro', required=>0, predicate=>'has_nested');

has not_blessed_msg => (is=>'ro', required=>1, default=>sub {_t 'not_blessed'});
has type_constraint_violation_msg => (is=>'ro', required=>1, default=>sub {_t 'type_constraint_violation'}); 
has wrong_inheritance_msg => (is=>'ro', required=>1, default=>sub {_t 'wrong_inheritance'}); 
has not_role_msg => (is=>'ro', required=>1, default=>sub {_t 'not_role'}); 
has invalid_msg => (is=>'ro', required=>1, default=>sub {_t 'invalid'});


sub normalize_shortcut {
  my ($class, $arg) = @_;
  if(($arg eq '1') || ($arg eq 'nested')) {
    return {  nested => 1 };
  } elsif( blessed $arg) {
    return { type_constraint => $arg };
  } 
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;

  unless(blessed $value) {
    $record->errors->add($attribute, $self->not_blessed_msg, $opts);
    return; 
  }

  if($self->has_type_constraint) {
    my $possible_error = $self->type_constraint->validate($value);
    if($possible_error) {
      $record->errors->add(
        $attribute,
        $self->type_constraint_violation_msg,
        +{
          %$opts,
          display_name => $self->type_constraint->display_name,
          error_message => $possible_error,
        });

    }
  }

  if($self->has_isa) {
    unless($value->isa($self->isa)) {
      $record->errors->add($attribute, $self->wrong_inheritance_msg, +{%$opts, parent=>$self->isa});
    }
  }

  if($self->has_role) {
    unless(Role::Tiny::does_role($value, $self->role)) {
      $record->errors->add($attribute, $self->not_role_msg, +{%$opts, role=>$self->role});
    }
  }

  if($self->has_nested && $self->nested) {
    $value->validate(%$opts) unless $value->validated; # Don't validate again
    $record->errors->add($attribute, $self->invalid_msg, $opts) if $value->errors->size;

    $value->errors->each(sub {
      my ($attr, $message) = @_;
      $record->errors->add("${attribute}.${attr}", $message);
    });
  }
}

1;

=head1 NAME

Valiant::Validator::Object - Verify a related object

=head1 SYNOPSIS

    package Local::Test::Address;

    use Moo;
    use Valiant::Validations;

    has street => (is=>'ro');
    has city => (is=>'ro');
    has country => (is=>'ro');

    validates ['street', 'city'],
      presence => 1,
      length => [3, 40];

    validates 'country',
      presence => 1,
      inclusion => [qw/usa uk canada japan/];

    package Local::Test::Person;

    use Moo;
    use Valiant::Validations;

    has name => (is=>'ro');
    has address => (is=>'ro');
    has car => (is=>'ro');

    validates name => (
      length => [2,30],
      format => qr/[A-Za-z]+/, #yes no unicode names for this test...
    );

    validates address => (
      presence => 1,
      object => {
        nested => 1,
        isa => 'Local::Test::Address',
      }
    );

=head1 DESCRIPTION

Runs validations on an object which is assigned as an attribute and
aggregates those errors (if any) onto the parent object.

Useful when you need to validate an object graph or nested forms.

If your nested object has a nested object it will follow all the way
down the rabbit hole  Just don't make self referential nested objects;
that's not tested and likely to end poorly.  Patches welcomed.

=head1 ATTRIBUTES

This validator supports the following attributes:

=head2 nested

A boolean that specifies if we should run 'validates' on the object.  Default is false.

=head2 type_constraint

Reference to a L<Type::Tiny> style type constraint.  If specified then the object must
pass the constraint.

=head2 type_constraint_violation_msg

The message we return when 'type_constraint' fails.  We pass 'display_name' and 'error_message'
as options to the tag.

=head2 isa

The name of a class that the object should inherit from

=head2 wrong_inheritance_msg

The message we return when 'isa' fails.  We pass 'parent' (the name of the class we require
inheritance from) as options to the tag.

=head2 role

A role that the object is expected to consume

=head2 not_role_msg

The message we return when 'role' fails.  We pass 'rolw' (the name of the role we require
to consume from) as options to the tag.

=head2 invalid_msg

The error message returned when the object has nested validation errors.

=head2 not_blessed_msg

The error returned when the value is not an object

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( object => 1, ... );

Which is the same as:

    validates attribute => (
      object => {
        nested => 1,
      }
    );

<B<Note>: you can use the 'nested' alias for '1' here if you want.

You can also specify a type constraint:

    use use Types::Standard 'Str';

    validates attribute => ( object => Str, ... );

Which is the same as:

    use use Types::Standard 'Str';

    validates attribute => (
      object => {
        type_constraint => Str,
      }
    );

=head1 AGGREGATED ERROR MESSAGES

When you nest a object with validations as in the following example any error messages 
in the nested object are imported into the parent object:

    package Local::Test::Address;

    use Moo;
    use Valiant::Validations;

    has street => (is=>'ro');
    has city => (is=>'ro');
    has country => (is=>'ro');

    validates ['street', 'city'],
      presence => 1,
      length => [3, 40];

    validates 'country',
      presence => 1,
      inclusion => [qw/usa uk canada japan/];

    package Local::Test::Person;

    use Moo;
    use Valiant::Validations;

    has name => (is=>'ro');
    has address => (is=>'ro');

    validates name => (
      length => [2,30],
      format => qr/[A-Za-z]+/, #yes no unicode names for this test...
    );

    validates address => (
      presence => 1,
      object => {
        nested => 1,
      }
    );

    my $address = Local::Test::Address->new(
      city => 'NY',
      country => 'Russia'
    );

    my $person = Local::Test::Person->new(
      name => '12234',
      address => $address,
    );

    my $address_errors = +{ $person->address->errors->to_hash(full_messages=>1) };

    # $address_errors = +{
    #    'country' => [
    #         'Country is not in the list'
    #    ],
    #    'city' => [
    #         'City is too short (minimum is 3 characters)'
    #    ],
    #    'street' => [
    #         'Street can\'t be blank',
    #         'Street is too short (minimum is 3 characters)'
    #    ],
    # };

    my $person_errors = +{ $person->errors->to_hash(full_messages=>1) };

    # $address_errors = +{
    #   name => [
    #       "Name does not match the required pattern",
    #     ],
    #   address => [
    #       "Address Is Invalid",
    #     ],
    #   "address.city" => [
    #       "Address City is too short (minimum is 3 characters)",
    #     ],
    #   "address.country" => [
    #       "Address Country is not in the list",
    #     ],
    #   "address.street" => [
    #       "Address Street can't be blank",
    #       "Address Street is too short (minimum is 3 characters)",
    #     ],
    };

When accessing errors for display you'll have to choose which access approach is
best for your application.

Please note that you can have objects nested inside of objects so this can lead to
very complex error messaging.

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
