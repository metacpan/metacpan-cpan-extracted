package Valiant::Validator::Date;

use Moo;
use Valiant::I18N;
use DateTime;
use DateTime::Format::Strptime;
use Scalar::Util 'blessed';

our $_pattern = '%Y-%m-%d';

with 'Valiant::Validator::Each';

has min => (is=>'ro', required=>0, predicate=>'has_min');
has max => (is=>'ro', required=>0, predicate=>'has_max');
has cb => (is=>'ro', required=>0, predicate=>'has_cb');

has pattern => (is=>'ro', required=>1, default=>sub { $_pattern });
has _strp => (is=>'ro', required=>1, lazy=>1, default=>sub { DateTime::Format::Strptime->new(pattern => shift->pattern) });


has below_min_msg => (is=>'ro', required=>1, default=>sub {_t 'below_min'});
has above_max_msg => (is=>'ro', required=>1, default=>sub {_t 'above_max'});
has invalid_date_msg => (is=>'ro', required=>1, default=>sub {_t 'invalid_date'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ } if $arg eq '1';
  return +{ cb => $arg } if ((ref($arg)||'') eq 'CODE');
  return +{ min => sub { pop->now } } if $arg eq 'is_future';
  return +{ max => sub { pop->now } } if $arg eq 'is_past';

}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;
  
  unless(defined $value) {
    $record->errors->add($attribute, $self->invalid_date_msg, $opts);
    return;
  }

  my $dt = $self->_strp->parse_datetime($value);

  unless($dt) {
    $record->errors->add($attribute, $self->invalid_date_msg, $opts);
    return;
  }

  if($self->has_min) {
    my $min = $self->_cb_value($record, $self->min);
    my $min_dt_obj = $self->parse_if_needed($min);
    $record->errors->add($attribute, $self->below_min_msg, +{%$opts, min=>$min_dt_obj->strftime($self->pattern)})
      unless $dt > $min_dt_obj;
  }

  if($self->has_max) {
    my $max = $self->_cb_value($record, $self->max);
    my $max_dt_obj = $self->parse_if_needed($max);
    $record->errors->add($attribute, $self->above_max_msg, +{%$opts, max=>$max_dt_obj->strftime($self->pattern)})
      unless $dt < $max_dt_obj;
  }

  if($self->has_cb) {
    $self->cb->($record, $attribute, $dt, $self, $opts);
  }
}

sub to_pattern {
  my ($self, $dt) = @_;
  return $dt->strftime($self->pattern);
}

sub parse_if_needed {
  my ($self, $value_proto) = @_;
  return $value_proto if blessed($value_proto) && $value_proto->isa('DateTime');
  return $self->_strp->parse_datetime($value_proto);
}

sub looks_like_a_date {
  my ($self, $value) = @_;
  my $dt = $self->parse_if_needed($value);
  return $dt;
}

sub is_future {
  my ($self, $value) = @_;
  my $dt = $self->parse_if_needed($value);
  return $dt > DateTime->now;
}

sub is_past {
  my ($self, $value) = @_;
  my $dt = $self->parse_if_needed($value);
  return $dt < DateTime->now;
}

sub now { DateTime->now }

sub datetime {
  my($self, %args) = @_;
  return DateTime->new(%args);
}

sub years_ago {
  my($self, $years) = @_;
  return DateTime->now->subtract(years => $years);
}

sub years_from_now {
  my($self, $years) = @_;
  return DateTime->now->add(years => $years);
}

1;

=head1 NAME

Valiant::Validator::Date - Verify that a value is is a standard Date (YYY-MM-DD)

=head1 SYNOPSIS

    package Local::Test::Date;

    use Moo;
    use Valiant::Validations;

    has birthday => (is=>'ro');

    validates birthday => (
      date => {
        min => sub { pop->years_ago(120) }, # Oldest person I think...
        max => sub { pop->now },
      }
    );

    my $object = Local::Test::Date->new(birthday=>'2100-01-01');
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'birthday' => [
         'chosen date can't be above {{max}}',  # In real life {{max}} would be
                                                # interpolated as DateTime->now
      ]
    };

=head1 DESCRIPTION

Validates a string pattern to make sure its in a standard date (YYYY-MM-DD) format,
which is commonly used in databases as a Date field and its also the canonical 
pattern for the HTML5 input date type.  

Can accept a 'min' and 'max' attribute, which should be either a string in the 
standard form or a M<DateTime> object.

If you are using the Form helpers the max and min attributes can be reflected into
the date input type automatically.

=head1 ATTRIBUTES

This validator supports the following attributes:

=head2 pattern

This is a string pattern that is used by L<DateTime::Format::Strptime> that your
date value must conform to (that is it must parse into a L<DateTime> object or the
validation fails).  The default is '%Y-%m-%d'.  This is a common database format and
is also used by HTML5 input date type fields.

=head2 min

If provided set a bottom limit on the allowed date.  Either a string in YYYY-MM-DD
format or a L<DateTime> object.

Value may also be a coderef so that you can set dynamic dates (such as always today)

=head2 max

If provided set an upper limit on the allowed date.  Either a string in YYYY-MM-DD
format or a L<DateTime> object.

Value may also be a coderef so that you can set dynamic dates (such as always today)

=head2 cb

A code reference that lets you create custom validation logic.  This is basically the
same as the 'With' validator expect its only called IF the value is in valid date
format and you get that date inflated into a L<DateTime> object instead of the raw
string value.  This makes it a little less work for you since you can skip those extra
checks.  Also the coderef will receive the validator type instance as the third argument
so that you can take advantage of the type helpers (see below L<\HELPERS>).

    package MyRecord

    use Moo;
    use Valiant::Validations;

    has attribute => (is=>'ro');

    validates attribute => (
      date => +{ 
        min => sub { pop->years_ago(10) },
        max => sub { pop->now },
        cb => \&my_special_method,
      },
    );

    sub my_special_method {
      my ($self, $dt, $type) = @_;
      # In this case $dt is a DateTime object inflated from the value
      # of 'attribute'.  This method won't get called if we previously 
      # determine that the value isn't in proper YYY-MM-DD format.

      # Custom validation stuff...
    }

=head2 below_min_msg

=head2 above_max_msg

=head2 invalid_date_msg

The error message / tag associated with the given validation failures.  Default messages
are provided.

=head1 HELPERS

This validator provides the following helpers. These basically just wrap L<DateTime>
and L<DateTime::Format::Strptime> so you can avoid having to create your own in your
record / object classes.

=head2 datetime

Returns a raw blessed L<DateTime> object.  If you pass a hash of arguments, those will
be passed to C<new>.

=head2 now

returns L<DateTime> now

=head2 years_ago

=head2 years_from_now

Return a L<DateTime> object that is now plus or minus a given number of years.

=head2 is_future

=head2 is_past

Given a L<DateTime> object (such as the value you are trying to validate), return true
or false if it is either in the future or in the past.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( date => 1, ... );

Which is the same as:

    validates attribute => (
      date => +{ },
    );

Not many saved characters but makes usage syntactically regular across validators.

You can also invoke a custom callback with a shortcut

    validates attribute => ( date => \&my_special_method, ... );

    sub my_special_method {
      my ($self, $dt, $type) = @_;
      # Custom validation stuff
    }

Which is the same as:

    validates attribute => (
      date => +{
        cb => \&my_special_method,
      },
    );

Lastly you can specify that the date must be either future or past with a shortcut:

    validates attribute => ( date => 'is_future', ... );
    validates attribute => ( date => 'is_past', ... );

Which is the same as:

    validates attribute => (
      date => +{
        min => sub { pop->is_future },
        max => sub { pop->is_past }
      },
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
