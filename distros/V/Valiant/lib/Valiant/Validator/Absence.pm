package Valiant::Validator::Absence;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has is_present => (is=>'ro', required=>1, default=>sub {_t 'is_present'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{} if $arg eq 1;
}

sub validate_each {
  my ($self, $record, $attribute, $value, $options) = @_;
  unless(
      not(defined $value) ||
      $value eq '' || 
      $value =~m/^\s+$/
  ) {
    $record->errors->add($attribute, $self->is_present, $options)
  }
}

1;

=head1 NAME

Valiant::Validator::Absence - Verify that a value is missing

=head1 SYNOPSIS

    package Local::Test::Absence;

    use Moo;
    use Valiant::Validations;

    has name => (is=>'ro');

    validates name => ( absence => 1 );

    my $object = Local::Test::Absence->new();
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'name' => [
        'Name must be blank',
      ]
    };

=head1 DESCRIPTION

Value must be absent (undefined, an empty string or a string composed
only of whitespace). Uses C<is_present> as the translation tag and you can set 
that to override the message.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( absence => 1, ... );

Which is the same as:

    validates attribute => (
      absence => +{},
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
