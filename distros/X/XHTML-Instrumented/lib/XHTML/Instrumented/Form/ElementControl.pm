use strict;
use warnings;

package
    XHTML::Instrumented::Form::ElementControl;

use base 'XHTML::Instrumented::Control';

use Data::Dumper;

sub if
{
    my $self = shift;

    my $x = 0;

    $x++ if defined $self->{value};
    $x++ if defined $self->{default};
    $x++ if defined $self->{required};

    $x;
}

sub set_value
{
    my $self = shift;
    my $value = shift;
    die if @_;

    if (my $type = ref($value)) {
        die unless $type eq 'ARRAY';
	if (@{$value} == 1) {
	    $self->{value} = $value->[0];
	} elsif (@{$value} == 0) {
	    $self->{value} = '';
	} else {
	    die 'bad data ' . "@{$value}";
	}
    } else {
	$self->{value} = $value;
    }
}

sub set_label
{
    my $self = shift;

    $self->{label} = shift;
}

sub is_multi
{
    0;
}

sub value
{
    my $self = shift;

    if ($self->is_multi) {
die $self;
	$self->{value} || $self->{default} || [];
    } else {
	$self->{value} || $self->{default};
    }
}

sub required
{
    my $self = shift;

    if (exists $self->{required} and $self->{required}) {
        if (exists $self->{value}) {
	    !length($self->{value});
	} else {
	    0;
	}
    } else {
	0;
    }
}

1;
__END__

=head1 NAME

XHTML::Instrumented::Form::ElementControl - The Form control object

=head1 SYNOPSIS

=head1 API

Used internally

=head2 Constructor

=over

=item new

=back

=head2 Methods

=over

=item if

=item set_value

=item set_label

=item is_multi

=item value

=item required

=back

=head2 Functions

This object has no functions

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
