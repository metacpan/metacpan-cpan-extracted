package Valiant::Validator::Length;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has maximum => (is=>'ro', predicate=>'has_maximum');
has minimum => (is=>'ro', predicate=>'has_minimum');
has in => (is=>'ro', predicate=>'has_in');
has is => (is=>'ro', predicate=>'has_is');

has too_long => (is=>'ro', required=>1, default=>sub {_t 'too_long'});
has too_short => (is=>'ro', required=>1, default=>sub {_t 'too_short'});
has wrong_length => (is=>'ro', required=>1, default=>sub {_t 'wrong_length'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ in => $arg };
}


sub BUILD {
  my ($self, $args) = @_;
  $self->_requires_one_of($args, 'maximum', 'minimum', 'in', 'is');
}

sub validate_each {
  my ($self, $record, $attribute, $value) = @_;
  my $length = length($value||'') || 0; # TODO not sure if this is best behavior
  my %opts = (%{$self->options});
  if($self->has_maximum) {
    my $max = $self->_cb_value($record, $self->maximum);
    $record->errors->add($attribute, $self->too_long, +{%opts, count=>$max})
      if $length > $max ;
  }
  if($self->has_minimum) {
    my $min = $self->_cb_value($record, $self->minimum);
    $record->errors->add($attribute, $self->too_short, +{%opts, count=>$min})
      if $length < $min;
  }
  if($self->has_in) {
    my ($min, $max) = @{$self->in};
    $max = $self->_cb_value($record, $max);
    $min = $self->_cb_value($record, $min);
    $record->errors->add($attribute, $self->too_long, +{%opts, count=>$max})
      if $length > $max;
    $record->errors->add($attribute, $self->too_short, +{%opts, count=>$min})
      if $length < $min;
  }
  if($self->has_is) {
    my $match_value = $self->_cb_value($record, $self->is);
    $record->errors->add($attribute, $self->wrong_length, +{%opts, count=>$match_value})
     unless $length == $match_value;
  }
}

1;

=head1 NAME

Valiant::Validator::Length - Validate the length of an attributes string value

=head1 SYNOPSIS

    package Local::Test::Length;

    use Moo;
    use Valiant::Validations;

    has name => (is=>'ro');
    has equals => (is=>'ro', required=>1, default=>5);

    validates name => (
      length => {
        maximum => 10,
        minimum => 3,
        is => sub { shift->equals }, 
      }
    );

    my $object = Local::Test::Length->new(name=>'Li');
    $object->validate; # Returns false

    warn $object->errors->_dump;

    $VAR1 = {
      'name' => [
        'Name is too short (minimum is 3 characters',
        'Name is the wrong length (should be 5 characters)',
      ]
    };

=head1 DESCRIPTION

Validates the length of a scalar, usually a string.  Supports a number of
constraint parameters that allow you to place various limits on this length
(like many other validators the value of the constraints can be a constant
or a coderef that gets the object instances as an argument).  You also
have parameters to override the default error for each constraint (these
arguments match the tag name).

=head1 CONSTRAINTS

This validator supports the following constraints.

=over

=item maximum

Accepts numeric value or coderef.  Returns error message tag V<too_long> if
the attribute length exceeds the value.

=item minimum

Accepts numeric value or coderef.  Returns error message tag V<too_short> if
the attribute length is smaller than the value.

=item in

Accepts an arrayref where the first item is a minimum length and the second item
is a maximum lenth or coderef that returns such an arrayref.  Returns error message
of either C<too_short> or C<too_long> if the value length is outside the range specified.

=item is 

Accepts numeric value or coderef.  Returns error message tag V<wrong_length> if
the attribute value equal to the check value.

=back

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( length => [1, 10], ... );

Which is the same as:

    validates attribute => (
      length => {
        in => [1, 10],
      },
    );
 
=head1 GLOBAL PARAMETERS

This validator supports all the standard shared parameters: C<if>, C<unless>,
C<message>, C<strict>, C<allow_undef>, C<allow_blank>.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Validator>, L<Valiant::Validator::Each>.
    
=head1 COPYRIGHT & LICENSE
 
Copyright 2020, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
