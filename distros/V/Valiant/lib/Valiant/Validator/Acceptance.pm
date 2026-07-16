package Valiant::Validator::Acceptance;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has accept => (is=>'ro', required=>1, default=>sub { ['1', 1, 'true', 'yes'] });
has accepted => (is=>'ro', required=>1, default=>sub {_t 'accepted'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{} if $arg eq '1';
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;
  my %accept = map { $_ => 1 } @{ $self->accept };
  $record->errors->add($attribute, $self->accepted, $opts)
    unless defined($value) && $accept{$value};
}

1;

=head1 NAME

Valiant::Validator::Acceptance - Verify that a value was accepted

=head1 SYNOPSIS

    package Local::Test::Acceptance;

    use Moo;
    use Valiant::Validations;

    has terms_of_service => (is=>'ro');

    validates terms_of_service => ( acceptance => 1 );

    my $object = Local::Test::Acceptance->new(terms_of_service=>0);
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'terms_of_service' => [
         'Terms Of Service must be accepted',
      ]
    };

=head1 DESCRIPTION

Validates that a value is one of a set of accepted values, typically used for
a "terms of service" checkbox or similar agreement field. The value must be
defined and appear in the C<accept> list; an undefined value fails (use the
shared C<allow_undef> parameter if you need C<undef> to pass).

The attribute is usually a virtual one that exists only to hold the submitted
form value and is not persisted.

=head1 CONSTRAINTS

This validator supports the following constraints.

=over

=item accept

An arrayref of the values considered acceptance. Defaults to
C<< ['1', 1, 'true', 'yes'] >>.

    validates terms_of_service => (
      acceptance => { accept => ['on'] },
    );

=item accepted

The error message used when the value is not accepted.  Default is translation
tag 'accepted'.

=back

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( acceptance => 1, ... );

Which is the same as:

    validates attribute => (
      acceptance => +{},
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
