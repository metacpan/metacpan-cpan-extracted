package Valiant::Validator::Numericality;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

# TODO add postive, negative /postive_or_zero, negative_or_zero

# ($value_to_test, ?$constraint_value)
our %CHECKS = (
  greater_than              => sub { $_[0] > $_[1] ? 1:0 },
  greater_than_or_equal_to  => sub { $_[0] >= $_[1] ? 1:0 },
  equal_to                  => sub { $_[0] == $_[1] ? 1:0 },
  less_than                 => sub { $_[0] < $_[1] ? 1:0 },
  less_than_or_equal_to     => sub { $_[0] <= $_[1] ? 1:0 },
  other_than                => sub { $_[0] != $_[1] ? 1:0 },
  even                      => sub { $_[0] % 2 ? 0:1 },
  odd                       => sub { $_[0] % 2 ? 1:0 },
  divisible_by              => sub { $_[0] % $_[1] ? 0:1 },
  decimals                  => sub { length(($_[0] =~ /\.(\d*)/)[0]) == $_[1] ? 1:0  },
  is_integer                => sub { $_[0]=~/\A-?[0-9]+\z/ }, # Taken from Types::Standard
  is_number                 => sub {
                              my $val = shift;
                              ($val =~ /\A[+-]?[0-9]+\z/) ||  # Taken from Types::Standard
                              ( $val =~ /\A(?:[+-]?)          # matches optional +- in the beginning
                              (?=[0-9]|\.[0-9])               # matches previous +- only if there is something like 3 or .3
                              [0-9]*                          # matches 0-9 zero or more times
                              (?:\.[0-9]+)?                   # matches optional .89 or nothing
                              (?:[Ee](?:[+-]?[0-9]+))?        # matches E1 or e1 or e-1 or e+1 etc
                              \z/x );
                            },
);

# Run these first and fail early if the choosen one fails.
my @INIT = (qw(is_integer is_number));
my %INIT; @INIT{@INIT} = delete @CHECKS{@INIT};

# Add the init_args to set the various check constraints and to allow
# someone to override individual error messages.
foreach my $attr (keys %CHECKS) {
  has $attr => (is=>'ro', predicate=>"has_${attr}");
  has "${attr}_err" => (is=>'ro', required=>1, default=>sub { _t "${attr}_err" });
}

foreach my $attr (keys %INIT) {
  has "${attr}_err" => (is=>'ro', required=>1, default=>sub { _t "${attr}_err" });
}

has only_integer => (is=>'ro', required=>1, default=>0);

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);

  # TODO Am thinking we shoud allow 'gt' for greater_than', 'gte' for 'greater_than_or_equal_to'
  # and so on.

  if(my $integer = $args->{only_integer}) {

    if($integer eq 'positive_integer') {
      $args->{greater_than_or_equal_to} = 0;
      $args->{message} = _t("positive_integer_err") unless defined $args->{message};
    }
    if($integer eq 'negative_integer') {
      $args->{less_than} = 0;
      $args->{message} = _t("negative_integer_err") unless defined $args->{message};
    }

    if($integer eq 'pg_serial') {
      $args->{greater_than_or_equal_to} = 0;
      $args->{less_than_or_equal_to} = 0;
      $args->{message} = _t("pg_serial_err") unless defined $args->{message};
    }
    if($integer eq 'pg_bigserial') {
      $args->{greater_than_or_equal_to} = 2147483647;
      $args->{less_than_or_equal_to} = 9223372036854775807;
      $args->{message} = _t("pg_bigserial_err") unless defined $args->{message};
    }
  }

  if(my $between = delete $args->{between}) {
    $args->{greater_than_or_equal_to} = $between->[0];
    $args->{less_than_or_equal_to} = $between->[1];
  }

  if($args->{positive}) {
    delete $args->{positive};
    $args->{greater_than_or_equal_to} = 0;
    $args->{message} = _t("positive_err") unless defined $args->{message};
  }

  if($args->{negative}) {
    delete $args->{negative};
    $args->{less_than} = 0;
    $args->{message} = _t("negative_err") unless defined $args->{message};
  }

  return $args;
};

sub normalize_shortcut {
  my ($class, $arg) = @_;

  # TODO document this and add a few more (int16, int32, etc)
  if((ref($arg)||'') eq 'ARRAY') {
    return +{
      greater_than_or_equal_to => $arg->[0],
      less_than_or_equal_to => $arg->[1],
    };
  } else {
    if( ($arg eq 'only_integer') || ($arg eq 'integer') ) {
      return +{
        only_integer => 1,
      }
    } elsif(
        ($arg eq 'positive_integer')
        || ($arg eq 'negative_integer')
        || ($arg eq 'pg_serial')
        || ($arg eq 'pg_bigserial')
      ) {
      return +{
        only_integer => $arg,
      }
    } elsif( $arg eq 'positive') {
      return + { positive => 1};
    } elsif( $arg eq 'negative') {
      return + { negative => 1};
    } elsif( $arg eq 'even') {
      return + { even => 1};
    } elsif( $arg eq 'odd') {
      return + { odd => 1};
    }
  }
}

sub validate_each {
  my ($self, $record, $attr, $value, $options) = @_;
  if($self->only_integer) {
    unless($INIT{is_integer}->($value)) {
      $record->errors->add($attr, $self->is_integer_err, $options); 
      return;
    }
  } else {
    unless($INIT{is_number}->($value)) {
      $record->errors->add($attr, $self->is_number_err, $options); 
      return;
    }
  }

  foreach my $key (sort keys %CHECKS) {
    next unless $self->${\"has_${key}"};
    my $constraint_value = $self->$key;
    $constraint_value = $constraint_value->($record)
      if((ref($constraint_value)||'') eq 'CODE');
    $record->errors->add($attr, $self->${\"${key}_err"}, +{%$options, count=>$constraint_value})
      unless $CHECKS{$key}->($value, $constraint_value);
  }
}

1;

=head1 NAME

Valiant::Validator::Numericality - Validate numeric attributes

=head1 SYNOPSIS

    package Local::Test::Numericality;

    use Moo;
    use Valiant::Validations;

    has age => (is => 'ro');
    has equals => (is => 'ro', default => 33);

    validates age => (
      numericality => {
        only_integer => 1,
        less_than => 200,
        less_than_or_equal_to => 199,
        greater_than => 10,
        greater_than_or_equal_to => 9,
        equal_to => \&equals,
      },
    );

    validates equals => (numericality => [5, 100]);

    my $object = Local::Test::Numericality->new(age=>8, equal=>40);
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      age => [
        "Age must be equal to 40",
        "Age must be greater than 10",
        "Age must be greater than or equal to 9",
      ],
    };

=head1 DESCRIPTION

Validates that your attributes have only numeric values. By default, it will
match an optional sign followed by an integral or floating point number. To
specify that only integral numbers are allowed set C<only_integer> to true.

There's several parameters you can set to place different type of numeric
limits on the value.  There's no checks on creating non sense rules (you can
set a C<greater_than> of 10 and a C<less_than> of 5, for example) so pay
attention.

All parameter values can be either a constant or a coderef (which will get
C<$self> as as argument).  The coderef option
exists to make it easier to write dynamic checks without resorting to writing
your own custom validators.  Each value also defines a translation tag which
folows the pattern "${rule}_err" (for example the C<greater_than> rules has a
translation tag C<greater_than_err>).  You can use the C<message> parameter to
set a custom message (either a string value or a translation tag).

=head1 CONSTRAINTS

Besides an overall test for either floating point or integer numericality this
validator supports the following constraints:

=over

=item only_integer

When set to a true value will require the value to be some sort of integer.  If
you set this to 1 then the value must be generally an integer.  However you can 
also set it to the following to get more limited integer types:

    validates attribute => ( numericality => { only_integer => 'positive_integer' }, ... );
    validates attribute => ( numericality => { only_integer => 'negative_integer' }, ... );

    # Lets you require the integer to conform to Postgresql Serial or Bigserial types
    validates attribute => ( numericality => { only_integer => 'pg_serial' }, ... );
    validates attribute => ( numericality => { only_integer => 'pg_bigserial' }, ... );

=item greater_than

Accepts numeric value or coderef.  Returns error message tag V<greater_than> if
the attribute value isn't greater.

=item greater_than_or_equal_to

Accepts numeric value or coderef.  Returns error message tag V<greater_than_or_equal_to_err> if
the attribute value isn't equal or greater.

=item equal_to

Accepts numeric value or coderef.  Returns error message tag V<equal_to_err> if
the attribute value isn't equal.

=item other_than

Accepts numeric value or coderef.  Returns error message tag V<other_than_err> if
the attribute value isn't different.

=item less_than

Accepts numeric value or coderef.  Returns error message tag V<less_than_err> if
the attribute value isn't less than.

=item less_than_or_equal_to

Accepts numeric value or coderef.  Returns error message tag V<less_than_or_equal_to_err> if
the attribute value isn't less than or equal.

=item between

Accepts a two item arrayref, where the first is an inclusive lower number bound and the
second is an inclusive upper number bound.

=item even

Accepts numeric value or coderef.  Returns error message tag V<even_err> if
the attribute value isn't an even number.

=item odd

Accepts numeric value or coderef.  Returns error message tag V<odd_err> if
the attribute value isn't an odd number.

=item divisible_by

Accepts numeric value or coderef. Returns error message C<divisible_by_err> if the
attribute value is not evenly divisible by the value.  For example if the attribute
value is 15 and the divisible value is 5 that is true (its divisible) but of the 
divisible value was 4 that woule be false and generate an error message.

=item decimals

Accepts numeric value or coderef.  Returns error message tag V<decimals_err> if
the attribute value doesn't contain exactly the requird number of places after
the decimal point.

=item positive

A number greater or equal to zero

=item negative

A number less than zero

=back

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( numericality => [1,10], ... );

Which is the same as:

    validates attribute => (
      numericality => {
        greater_than_or_equal_to => 1,
        less_than_or_equal_to => 10,
      },
    );

If you merely wish to test for overall numericality you can use:

    validates attribute => ( numericality => +{}, ... );

You can require various integer types as well:

    validates attribute => ( numericality => 'integer', ... );
    validates attribute => ( numericality => 'positive_integer', ... );
    validates attribute => ( numericality => 'negative_integer' ... );
    validates attribute => ( numericality => 'pg_serial' ... ); # Postgresql Serial
    validates attribute => ( numericality => 'pg_bigserial' ... ); # Postgresql Bigserial

Misc shortcuts:

    validates attribute => ( numericality => 'positive' ... ); # a positive number
    validates attribute => ( numericality => 'negative' ... ); # a negative number
    validates attribute => ( numericality => 'even' ... ); # an even number
    validates attribute => ( numericality => 'odd' ... ); # an odd number

 
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
