package Valiant::Validator::Confirmation;

use Moo;
use Valiant::I18N;
use Valiant::Util 'throw_exception', 'debug';

with 'Valiant::Validator::Each';

has confirmation => (is=>'ro', required=>1, default=>sub {_t 'confirmation'});
has suffix => (is=>'ro', required=>1, default=>'_confirmation');

sub BUILD {
  my ($self, $args) = @_;
  my $model_class = $self->model_class;
  foreach my $attribute (@{$self->attributes||[]}) {
    my $confirmation_attribute = "${attribute}${\$self->suffix}";
    next if $model_class->can($confirmation_attribute);
    $model_class->inject_attribute($confirmation_attribute);
  }
}

sub normalize_shortcut {
  my ($class, $arg) = @_;
  if($arg eq '1') {
    return +{};
  } else {
    return +{ suffix=>$arg };
  }
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;
  my $confirmation_attribute = "${attribute}${\$self->suffix}";
  my $confirmation = $record->can($confirmation_attribute) ||
    throw_exception MissingMethod => (object=>$record, method=>$confirmation_attribute);

  my $confirmation_value = $confirmation->($record);

  # If confirmation is not defined then skip this validation.   If the user wants to have
  # this defined they can use the presence validator.

  return unless defined($confirmation_value) || defined($value);

  if( ($value||'') ne ($confirmation_value||'')) {
    my $human_attribute_name = $record->human_attribute_name($attribute);
    $record->errors->add($confirmation_attribute, $self->confirmation, +{%$opts, attribute=>"$human_attribute_name"})
  }
}

1;

=head1 NAME

Valiant::Validator::Confirmation - Checks for a 'confirming' attributes equality.

=head1 SYNOPSIS

    package Local::Test::Confirmation;

    use Moo;
    use Valiant::Validations;

    has email=> (is=>'ro');

    validates email => ( confirmation => 1 );

    my $object = Local::Test::Confirmation->new(
      email => 'AAA@example.com',
      email_confirmation => 'ZZZ@example.com'
    );
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'email_confirmation' => [
        "Email confirmation doesn't match 'Email'",
      ]
    };

=head1 DESCRIPTION

Use this when you have two attributes which should be set to the same value
(for example to confirm someone entered the correct email address or changed
their password to the same value).

The error message (if any) will appear associated with the confirmation attribute.
Error message uses tag C<confirmation> and you can override that with an init arg
of the same name.  You can also change the prefix used to identify the confirming
attribute with the C<prefix> init arg (default value is '_confirmation').

B<NOTE:> You don't need to add the confirmation attribute, we inject it for you during 
validation setup.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( confirmation => 1, ... );

Which is the same as:

    validates attribute => (
      confirmation => +{},
    );

Not a lot of saved typing but it seems to read better.
 
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
