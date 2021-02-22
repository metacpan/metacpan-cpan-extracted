package Text::BibTeX::Validate::Warning;

use strict;
use warnings;

# ABSTRACT: validaton warning class
our $VERSION = '0.3.0'; # VERSION

use Text::sprintfn;

=head1 NAME

Text::BibTeX::Validate::Warning - validaton warning class

=head1 SYNOPSIS

    use Text::BibTeX::Validate::Warning;

    my $warning = Text::BibTeX::Validate::Warning->new(
        'value \'%(value)s\' is better written as \'%(suggestion)s\'',
        {
            field => 'month',
            value => '1',
            suggestion => 'Jan',
        }
    );
    print STDERR "$warning\n";

=head1 DESCRIPTION

Text::BibTeX::Validate::Warning is used to store the content of
validation warning (as emitted by
L<Text::BibTeX::Validate|Text::BibTeX::Validate>) in a structured way.
Overloads are defined to stringify and to compare instances of the
class.

=head1 METHODS

=cut

use overload
    '""'  => \&to_string,
    'cmp' => \&_cmp;

=head2 new( $message, $fields )

Takes L<Text::sprintfn|Text::sprintfn>-compatible template and a hash
with the values for replacement in the template. Three field names are
reserved and used as prefixes for messages if defined: C<file> for the
name of a file, C<key> for BibTeX key and C<field> for BibTeX field
name. Field C<suggestion> is also somewhat special, as
L<Text::BibTeX::Validate|Text::BibTeX::Validate> may use its value to
replace the original in an attempt to clean up the BibTeX entry.

=cut

sub new
{
    my( $class, $message, $fields ) = @_;
    my $self = { %$fields, message => $message };
    return bless $self, $class;
}

=head2 fields()

Returns an array of fields defined in the instance in any order.

=cut

sub fields
{
    return keys %{$_[0]};
}

=head2 get( $field )

Returns value of a field.

=cut

sub get
{
    my( $self, $field ) = @_;
    return $self->{$field};
}

=head2 set( $field, $value )

Sets a new value for a field. Returns the old value.

=cut

sub set
{
    my( $self, $field, $value ) = @_;
    ( my $old_value, $self->{$field} ) = ( $self->{$field}, $value );
    return $old_value;
}

=head2 delete( $field )

Unsets value for a field. Returns the old value.

=cut

sub delete
{
    my( $self, $field ) = @_;

    my $old_value = $self->{$field};
    delete $self->{$field};

    return $old_value;
}

=head2 to_string()

Return a string representing the warning.

=cut

sub to_string
{
    my( $self ) = @_;

    my $message = $self->{message};
    $message = '%(field)s: ' . $message if exists $self->{field};
    $message = '%(key)s: '   . $message if exists $self->{key};
    $message = '%(file)s: '  . $message if exists $self->{file};

    return sprintfn $message, { %$self };
}

sub _cmp
{
    my( $a, $b, $are_swapped ) = @_;
    return "$a" cmp "$b" * ($are_swapped ? -1 : 1);
}

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut

1;
