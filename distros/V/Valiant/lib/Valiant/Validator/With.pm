package Valiant::Validator::With;

use Moo;
use Valiant::Util 'throw_exception';

with 'Valiant::Validator::Each';

has cb => (is=>'ro', predicate=>'has_cb');
has method => (is=>'ro', predicate=>'has_method');
has message_if_false => (is=>'ro', predicate=>'has_message_if_false');

sub normalize_shortcut {
  my ($class, $arg) = @_;
  if ((ref($arg)||'') eq 'ARRAY') {
    if((ref($arg->[0])||'') eq 'CODE') {
      return +{
        cb => $arg->[0],
        message_if_false => $arg->[1],
      };
    } else {
      return +{
        method => $arg->[0],
        message_if_false => $arg->[1],
      };
    }
  }

  return +{ cb => $arg  } if (ref($arg)||'') eq 'CODE';
  return +{ method => $arg }; # Its a scalar
}


sub BUILD {
  my ($self, $args) = @_;
  $self->_requires_one_of($args, 'cb', 'method');
}

sub validate_each {
  my ($self, $record, $attribute, $value, $options) = @_;  
  if($self->has_cb) {
    my $return = $self->cb->($record, $attribute, $value, $options);
    $record->errors->add($attribute, $self->message_if_false, $options)
      if !$return and $self->has_message_if_false;
  }
  if($self->has_method) {
    if(my $method_cb = $record->can($self->method)) {
      my $return = $method_cb->($record, $attribute, $value, $options);
      $record->errors->add($attribute, $self->message_if_false, $options)
        if !$return and $self->has_message_if_false;
    } else {
      throw_exception MissingMethod => (object=>$record, method=>$self->method); 
    }
  }
}

1;

=head1 NAME

Valiant::Validator::With - Validate using a coderef or method

=head1 SYNOPSIS

    package Local::Test::With;

    use Moo;
    use Valiant::Validations;
    use Valiant::I18N;
    use DateTime;

    has date_of_birth => (is => 'ro');

    validates date_of_birth => (
      with => sub {
        my ($self, $attribute_name, $value, $opts) = @_;
        $self->errors->add($attribute_name, "Can't be born tomorrow") 
          if $value > DateTime->today;
      },
    );

    validates date_of_birth => (
      with => {
        method => 'not_future',
        message_if_false => _t('not_future'),
      },
    );

    sub not_future {
      my ($self, $attribute_name, $value, $opts) = @_;
      return $value < DateTime->today;
    }

    my $dt = DateTime->new(year=>2364, month=>4, day=>30); # ST:TNG Encounter At Farpoint ;)
    my $object = Local::Test::With->new(date_of_birth=>$dt);
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'date_of_birth' => [
        'Date of birth Can\'t be born tomorrow',
        'Date of birth Date 2364-04-30T00:00:00 is future'
      ]
    };

=head1 DESCRIPTION

This validator allows you to set a custom coderef or method name to handle all
special validation needs.  You can use this instead of overriding the C<validate>
method.  This validator doesn't itself set any error messages and relies on you
knowing what you are doing.  Use this when creating your own validator is too
much work or the validation requirement is too special and not generically reusable.

You can also use a validation object and call that with C<validates_with> as an
alternative to using this validator.  You should consider doing so if you validation
is very complex and requires initial arguments for example.

If you set the parameter C<message_if_false> you can just have your validation
coderef or method return a boolean and it will set the error message for you.  Given
message will be used if the method or coderef returns false. You
may find this approach neater if you need to use a validation method in several
places, or for promoting looser coupling in your code.

=head1 Passing parameters to $opts

You can pass parameters to the C<$opts> hashref using the C<opts> argument:

    validates date_of_birth => (
      with => {
        method => 'minimum_year',
        opts => {year => 2000},
      },
    );

    sub not_future_with_opts {
      my ($self, $attribute_name, $value, $opts) = @_;
      $self->errors->add($attribute_name, 'Year too low') unless
        $value->year > $opts->{year};
    }

You might find this useful in creating more parametered callbacks.  However at this point
you might wish to consider just writing a custom validator.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( with => sub { my $self = shift; ... }, ... );
    validates attribute => ( with => 'mymethod', ... );
    validates attribute => ( with => ['mymethod', 'Value is invalid'], ... );
    validates attribute => ( with => [sub { my $self = shift; ... }, 'Value is invalid'], ... );

Which is the same as:

    validates attribute => (
      with => {
        cb => sub { ... },
      },
      ...
    );
    validates attribute => (
      with => {
        method => 'mymethod',
      },
      ...
    );
    validates attribute => (
      with => {
        method => 'mymethod',
        message_if_false => 'Value is invalid',
      },
      ...
    ); 
    validates attribute => (
      with => {
        cb => sub { ... },
        message_if_false => 'Value is invalid',
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
