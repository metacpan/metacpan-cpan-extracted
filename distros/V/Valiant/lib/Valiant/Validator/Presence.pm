package Valiant::Validator::Presence;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has required => (is=>'ro', init_arg=>undef, required=>1, default=>1 );
has is_blank => (is=>'ro', required=>1, default=>sub {_t 'is_blank'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{} if $arg eq '1' ;
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;
  if(
      not(defined $value) ||
      $value eq '' || 
      $value =~m/^\s+$/
  ) {
    $record->errors->add($attribute, $self->is_blank, $opts)
  }
}

1;

=head1 NAME

Valiant::Validator::Presence - Verify that a value is present

=head1 SYNOPSIS

    package Local::Test::Presence;

    use Moo;
    use Valiant::Validations;

    has name => (is=>'ro');

    validates name => ( presence => 1 );

    my $object = Local::Test::Presence->new();
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'name' => [
         'Name can\'t be blank',
      ]
    };

=head1 DESCRIPTION

Value must be present (not undefined, not an empty string or a string composed
only of whitespace). Uses C<is_blank> as the translation tag and you can set 
that to override the message.


=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( presence => 1, ... );

Which is the same as:

    validates attribute => (
      presence => +{},
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
