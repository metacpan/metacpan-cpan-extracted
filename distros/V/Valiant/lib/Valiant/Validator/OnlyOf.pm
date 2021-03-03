package Valiant::Validator::OnlyOf;

use Moo;
use Valiant::I18N;

with 'Valiant::Validator::Each';

has members => (is=>'ro', required=>1);
has max_allowed => (is=>'ro', required=>1, default=>1);
has only_of => (is=>'ro', required=>1, default=>sub {_t 'only_of'});

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return {members => $arg};
}

sub validate_each {
  my ($self, $record, $attribute, $value, $options) = @_;

  my @members = $self->_cb_value($record, $self->members);
  @members = @{$members[0]} if (ref($members[0])||'') eq 'ARRAY'; # lets the callback be an array or arrayref
  
  my @group_values = map {
    $record->read_attribute_for_validation($_);
  } grep {
    $_ ne $attribute; # probably a common error
  } @members;

  push @group_values, $value;

  my $count_not_blank = grep {
    defined $_ && ( $_ ne '' || $value !~m/^\s+$/)
  } @group_values;

  my $max_allowed = $self->_cb_value($record, $self->max_allowed);
  unless( $count_not_blank <= $max_allowed) {
    my %opts = (
      %$options,
      count => $max_allowed,
      count_not_blank => $count_not_blank,
    );
    $record->errors->add($attribute, $self->only_of, \%opts);
  }
}

1;

=head1 NAME

Valiant::Validator::OnlyOf - Limit the number of fields not blank in a group

=head1 SYNOPSIS

    package Local::Test::OnlyOf;

    use Moo;
    use Valiant::Validations;

    has opt1 => (is=>'ro');
    has opt2 => (is=>'ro');
    has opt3 => (is=>'ro');

    validates opt1 => ( only_of => {
      members => ['opt2','opt3'],
      max_allowed => 1, # This is the default value
    );

    my $object = Local::Test::OnlyOf->new();
    $object->validate;

    warn $object->errors->_dump;

    $VAR1 = {
      'opt1' => [
            'Opt1 please choose only 1 field'
          ]
    };

=head1 DESCRIPTION

Limits the number of fields in a group that can be not blank.  Useful when
you have a group of optional fields that you want the user to fill in only
one (or a subset of).  Default is to allow only one member of the defined group
to be not blank, and you can override that with the C<max_allowed> paramters.

Both C<members> and C<max_allowed> can be a subref that gets the first argument
as the object and is expected to return something valid.  Useful if for example
you have different rules for the group members or size based on the data.

<Uses C<only_of> as the translation tag and you can set 
that to override the message.

=head1 SHORTCUT FORM

This validator supports the follow shortcut forms:

    validates attribute => ( only_of => ['opt2','opt3'], ... );

Which is the same as:

    validates attribute => (
      only_of => {
        members => ['opt2','opt3'],
      },
      ... );

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
