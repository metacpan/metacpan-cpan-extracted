use strict;
use warnings;

package
    XHTML::Instrumented::Form::Hidden;

use base 'XHTML::Instrumented::Form::Element';

use Params::Validate qw (validate);

sub is_multi
{
    1;
}

sub set_value
{
    my $self = shift;
    my $value = shift;
    die if @_;

    if (my $type = ref($value)) {
        die unless $type eq 'ARRAY';
	$self->{value} = $value;
    } else {
	$self->{value} = [ $value ];
    }
}

sub value
{
    shift->SUPER::value(@_);
}

1;
__END__

=head1 NAME

XHTML::Instramented::Form::Hidden - XHTML::Instramented::Form Hidden Object

=head1 SYNOPSIS

=head1 API

This holds information on a hidden form element.

=head2 Constructor

=over

=item new

=back

=head2 Methods

=over

=item is_multi

Returns true, as hidden elements can have multiple values.

=item set_value

=item value

=back

=head2 Functions

This object has no functions

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
