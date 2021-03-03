package Valiant::Validator::Hash;

use Moo;
use Valiant::I18N;
use Module::Runtime 'use_module';
use Valiant::Util 'throw_exception';

with 'Valiant::Validator::Each';

has validations => (is=>'ro', required=>1);
has validator => (is=>'ro', required=>1);
has invalid_msg => (is=>'ro', required=>1, default=>sub {_t 'invalid'});

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);

  if($args->{namespace}) {
    $args->{for} = $args->{namespace};
  }

  if( (ref($args->{validations})||'') && !exists $args->{validator} ) {

    # convert hashref to arrayref
    my @validations = ();
    if( ((ref($args->{validations})||'') eq 'ARRAY') ) {
      @validations = @{$args->{validations}};
    } elsif( ((ref($args->{validations})||'') eq 'HASH') ) {
      @validations = map {
        [ $_, @{$args->{validations}{$_}} ];
      } keys %{$args->{validations}}; 
    } else {
      throw_exception General => (msg=>'validations argument in unsupported format');
    }

    my $validator = use_module($args->{validator_class}||'Valiant::Proxy::Hash')
      ->new( result_class => 'Valiant::Result::HashRef', %{ $args->{validator_class_args}||+{} },
        for => $args->{for}, 
        validations => \@validations);
    $args->{validator} = $validator;
  }

  return $args;
};

sub normalize_shortcut {
  my ($class, $arg) = @_;
  if( (ref($arg)||'') eq 'ARRAY') {
    return {validations => $arg};
  }
}

sub validate_each {
  my ($self, $record, $attribute, $value, $options) = @_;

  my %opts = (%{$self->options}, %{$options||{}});
  my $validator = $self->validator;
  my $result = $validator->validate($value, %opts);

  if($result->invalid) {
    my $errors = $result->errors;
    $errors->{__result} = $result; # hack to keep this in scope
    $record->errors->add($attribute, $self->invalid_msg, \%opts);

    $result->errors->each(sub {
      my ($attr, $message) = @_;
      $record->errors->add("${attribute}.${attr}", $message);
    });

  }
}

1;

=head1 NAME 

Valiant::Validator::Hash - Verify a related object

=head1 SYNOPSIS

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
      hash => [
        [street => presence => 1, length => [2,24] ],
        [city => presence => 1, length => [2,24] ],
        [zip => presence => 1, numericality => 'positive_integer', format => qr/\d\d\d\d\d/ ],
      ],
    );

    # long form example
    validates address => (
      presence => 1,
      hash => {
        validations => {
          street => [format => qr/[^\=]/, message => 'cannot have silly characters'],
          zip => [length => [5,5]],
        }
      }
    );

    my $person = Local::Test::Person->new(
      name => '12',
      address => +{
        street => '=',
        city => 'Elgin',
        zip => '2aa',
      },
    );

  $person->validate->invalid; # True, the object is invalid.

  warn $person->errors->_dump;

  $VAR1 = {
        address => [
          {
            street => [
              "Street is too short (minimum is 2 characters)",
              "Street cannot have silly characters",
            ],
            zip => [
              "Zip must be an integer",
              "Zip does not match the required pattern",
              "Zip is too short (minimum is 5 characters)",
            ],
          },
        ],
    'name' => [
              'Name does not match the required pattern'
            ]
    };

=head1 DESCRIPTION

Perform validations on values when the value associated with the attribute
is a hashref.  You can use this when inflating an object seems like silly
work.

=head1 ATTRIBUTES

This validator supports the following attributes:

=head2 validations

Either 1 or an arrayref of validation rules.  Each item in the arrayref
is an arrayref that contains anything you may pass to C<validates>.  Typically
this will be a key name for the hashref followed by a list of validation
rules.

=head2 for / namespace

When defining an inline validation ruleset against an associated object that
does not itself have validation rules, you must set this to something that
ISA or DOES the class you are defining inline validations on.  This is not
currently strictly enforced, but this value is used to find any locale files
or custom validator classes.

=head2 validator

This contains an instance of L<Valiant::Class> or subclass. Default value
does the right thing but you can override if you need a special subclass
or you need to pass one in that's already constructed.

=head2 validator_class 

Defaults to L<Valiant::Class>, which value should be a subclass of.  You probably
only need this again if you are doing very custom validations.  You probably only
want do to this if there's no other idea.

=head2 validator_class_args

A hashref of args that get passed to the C<new> method of C<validator_class>.
Defaults to an empty hashref.  You might need this if you build a custom validator
class and have special arguments it needs.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( hash => \@validation_rules, ... );

Which is the same as:

    validates attribute => (
      hash => {
        validations => \@validation_rules,
      }
    );

But less typing and probably makes sense unless you need to set some of the more
rarely used attributes such as C<validator_class> etc.

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
