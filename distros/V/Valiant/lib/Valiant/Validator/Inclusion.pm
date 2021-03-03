package Valiant::Validator::Inclusion;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has in => (is=>'ro', required=>1);
has inclusion => (is=>'ro', required=>1, default=>sub {_t 'inclusion'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ in=>$arg };
}

sub validate_each {
  my ($self, $record, $attribute, $value, $options) = @_;

  my $in = $self->in;
  my @in = ();
  if(ref($in) eq 'CODE') {
    @in = $in->($record);
  } else {
    @in = @$in;
  }

  my %opts = (%{$self->options}, list=>\@in, %{$options||+{}});

  unless(grep { $_ eq $value } @in) {
    $record->errors->add($attribute, $self->inclusion, \%opts)
  }
}

1;

=head1 NAME

Valiant::Validator::Inclusion - Value must be one of a list

=head1 SYNOPSIS

    package Local::Test::Inclusion;

    use Moo;
    use Valiant::Validations;

    has status => (is=>'ro');
    has type => (is=>'ro');

    validates status => (
      inclusion => +{
        in => [qw/active retired/],
      },
    );

    validates type => (
      inclusion => +{
        in => \&available_types,
      },
    );

    sub available_types {
      my $self = shift;
      return (qw(student instructor));
    }

    my $object = Local::Test::Inclusion->new(
      status => 'running',
      type => 'janitor',
    );

    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'status' => [
                    'Status is not in the list'
                  ],
      'type' => [
                  'Type is not in the list'
                ],
    };

=head1 DESCRIPTION

Value must be one of a list.  This list can be given as an arrayref or
as a reference to a method (for when you need to dynamically build the list).

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( inclusion => [qw/a b c/], ... );

Which is the same as:

    validates attribute => (
      inclusion => +{
        in => [qw/a b c/],
      },
    );

This also works for the coderef form:

    validates attribute => ( inclusion => \&coderef, ... );

    validates attribute => (
      inclusion => +{
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
