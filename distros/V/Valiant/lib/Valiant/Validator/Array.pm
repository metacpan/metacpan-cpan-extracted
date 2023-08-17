package Valiant::Validator::Array;

use Moo;
use Valiant::I18N;
use Module::Runtime 'use_module';

with 'Valiant::Validator::Each';

has max_length => (is=>'ro', predicate=>'has_max_length');
has min_length => (is=>'ro', predicate=>'has_min_length');
has validations => (is=>'ro', required=>1);

has validator_class => (is=>'ro', required=>1, default=>'Valiant::Proxy::Array');
has validator_class_args => (is=>'ro', required=>1, default=>sub { +{} });
has invalid_msg => (is=>'ro', required=>1, default=>sub {_t 'invalid'});
has max_length_err => (is=>'ro', required=>1, default=>sub {_t 'max_length_err'});
has min_length_err => (is=>'ro', required=>1, default=>sub {_t 'min_length_err'});
has not_array_err => (is=>'ro', required=>1, default=>sub {_t 'not_array_err'});

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  return $args;
};

sub normalize_shortcut {
  my ($class, $arg) = @_;
  if( (ref($arg)||'') eq 'ARRAY') {
    return { validations => $arg };
  }
}

sub validate_each {
  my ($self, $record, $attribute, $value, $options) = @_;

  unless(ref($value) and (ref($value) eq 'ARRAY')) {
    $record->errors->add($attribute, $self->not_array_err, $options);
    return;
  }

  my $size = scalar(@$value);
  $record->errors->add($attribute, $self->min_length_err, +{%$options, size=>$size, min=>$self->min_length})
    if $self->has_min_length and ($size < $self->min_length);

  $record->errors->add($attribute, $self->max_length_err, +{%$options, size=>$size, max=>$self->max_length})
    if $self->has_max_length and ($size > $self->max_length);

  my @validations = @{$self->validations};
  my $validator = use_module($self->validator_class)
      ->new(
        validations => [[ [ map { "${attribute}[${_}]" } 0..$#$value ], @validations ]],
        %{ $self->validator_class_args },
      );

  my $result = $validator->validate($value, %$options);  

  if($result->invalid) {
    my $errors = $result->errors;
    $errors->{__result} = $result; # hack to keep this in scope
    $record->errors->add($attribute, $self->invalid_msg, $options);

    $errors->each(sub {
      my ($index, $message) = @_;
      $record->errors->add("${index}", $message);
    });
  }
}

1;

=head1 NAME

Valiant::Validator::Array - Verify items in an arrayref.

=head1 SYNOPSIS

    package Local::Test::Car;

    use Moo;
    use Valiant::Validations;

    has ['make', 'model', 'year'] => (is=>'ro');

    validates make => ( inclusion => [qw/Toyota Tesla Ford/] );
    validates model => ( length => [2, 20] );
    validates year => ( numericality => { greater_than_or_equal_to => 1960 });

    package Local::Test::Array;

    use Moo;
    use Valiant::Validations;

    has status => (is=>'ro');
    has name => (is=>'ro');
    has car => (is=>'ro');

    validates name => (length=>[2,5]);
    validates car => ( array => { validations => [object=>1] } );
    validates status => (
      array => {
        max_length => 3,
        min_length => 1,
        validations => [
          inclusion => +{
            in => [qw/active retired/],
          },
        ]
      },
    );

    my $car = Local::Test::Car->new(
        make => 'Chevy',
        model => '1',
        year => 1900
    );

    my $object = Local::Test::Array->new(
      name => 'napiorkowski',
      status => [qw/active running retired retired aaa bbb ccc active/],
      car => [$car],
    );

    $object->validate->invalid; # TRUE
    $object->car->[0]->invalid; # TRUE

    # Error Messages

    my $all_errors = +{ $object->errors->to_hash(full_messages=>1) };

    # $all_errors = {
    #   car => [
    #     "Car Is Invalid",
    #   ],
    #   "car.0" => [
    #     "Car Is Invalid",
    #   ],
    #   "car.0.make" => [
    #     "Car Make is not in the list",
    #   ],
    #   "car.0.model" => [
    #     "Car Model is too short (minimum is 2 characters)",
    #   ],
    #   "car.0.year" => [
    #     "Car Year must be greater than or equal to 1960",
    #   ],
    #   name => [
    #     "Name is too long (maximum is 5 characters)",
    #   ],
    #   status => [
    #     "Status Is Invalid",
    #   ],
    #   "status.1" => [
    #     "Status is not in the list",
    #   ],
    #   "status.4" => [
    #     "Status is not in the list",
    #   ],
    #   "status.5" => [
    #     "Status is not in the list",
    #   ],
    #   "status.6" => [
    #     "Status is not in the list",
    #   ],
    #  };
    
    # Errors just on the car array item

    my $car_errors = +{ $object->car->[0]->errors->to_hash(full_messages=>1) };

    # $car_errors = {
    #   make => [
    #     "Make is not in the list",
    #   ],
    #   model => [
    #     "Model is too short (minimum is 2 characters)",
    #   ],
    #   year => [
    #     "Year must be greater than or equal to 1960",
    #   ],
    # };

=head1 DESCRIPTION

Validations for arrays (really arrayrefs since that's how L<Moo> attrivbutes work).
Allows you to define validations on the array as a whole (such as set a maximum or
minimum array length) as well as define validations on the array individual items.
Can be used with the L<Valiant::Validator::Object> validator to deeply nest arrays of
objects.

=head1 ATTRIBUTES

This validator defines the following attributes

=head2 max_length

The maximum size of the array.  For example "@a = (1,2,3)" has size of 3.

=head2 min_length

The minimum size of the array.

=head2 max_length_err

=head2 min_length_err

The errors associated with the minimum or maximum array size errors.  Defaults are translatio
tag 'max_length_err' and 'min_length_err'.

=head2 invalid_msg

The message returned when an array is generically invalid.  An array becomes invalid should
any validations you define on array items fail to validate.  Default is translation tag 'invalid'.

=head2 validations

An arrayref of validations that are run on each item in the list.  Keep in mind the performance
inplications of this should the list be very long.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( array => [ presence=>1, length=>[2,10] ], ... );

Which is the same as:

    validates attribute => (
      validations => [
        presence => 1,
        length => [2,10],
      ],
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
