package Valiant::Validator::Exclusion;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has in => (is=>'ro', required=>1);
has exclusion => (is=>'ro', required=>1, default=>sub {_t 'exclusion'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  $arg = [$arg] unless ref $arg;
  return +{ in => $arg };
}

sub validate_each {
  my ($self, $record, $attribute, $value, $opts) = @_;

  my $in = $self->in;
  my @in = ();
  if(ref($in) eq 'CODE') {
    @in = $in->($record);
  } else {
    @in = @$in;
  }


  if(grep { $_ eq $value } @in) {
    $record->errors->add($attribute, $self->exclusion, +{%$opts, list=>\@in})
  }
}

1;

=head1 NAME

Valiant::Validator::Exclusion - Value cannot be in a list

=head1 SYNOPSIS

    package Local::Test::Exclusion;

    use Moo;
    use Valiant::Validations;

    has domain => (is=>'ro');
    has country => (is=>'ro');

    validates domain => (
      exclusion => +{
        in => [qw/org co/],
      },
    );

    validates country => (
      inclusion => +{
        in => \&restricted,
      },
    );

    sub restricted {
      my $self = shift;
      return (qw(usa uk));
    }

    my $object = Local::Test::Exclusion->new(
      domain => 'org',
      country => 'usa',
    );

    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'country' => [
        'Country is reserved'
      ],
      'domain' => [
        'Domain is reserved'
      ]
    };

=head1 DESCRIPTION

Value cannot be from a list of reserved values.  Value can be given
as either an arrayref or a coderef (which recieves the validating 
object as the first argument, so you can call methods for example).

If value is invalid uses the C<exclusion> translation tag (which you can
override as an argument).

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( exclusion => [qw/a b c/], ... );

Which is the same as:

    validates attribute => (
      exclusion => +{
        in => [qw/a b c/],
      },
    );

This also works for the coderef form:

    validates attribute => ( exclusion => \&coderef, ... );

    validates attribute => (
      exclusion => +{
        in => \&coderef,
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
