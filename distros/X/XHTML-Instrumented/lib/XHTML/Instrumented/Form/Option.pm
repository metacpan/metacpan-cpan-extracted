use strict;
use warnings;

package
    XHTML::Instrumented::Form::Option;
use base 'XHTML::Instrumented::Form::ElementControl';

sub as_args
{
    my $self = shift;
    my %hash = %$self;
    delete $hash{text};
    if ($hash{disabled}) {
	$hash{disabled} = 'disabled';
    }
    if ($hash{selected}) {
	$hash{selected} = 'selected';
    }
    %hash;
}

sub selected
{
    my $self = shift;

    $self->{selected};
}

sub disabled
{
    my $self = shift;

    $self->{disabled};
}

sub text
{
    my $self = shift;

    $self->{text};
}

sub value
{
    my $self = shift;

    $self->{value} || $self->{text};
}


1;

__END__

=head1 NAME

XHTML::Instrumented::Form::Option - An Option Form Element

=head1 SYNOPSIS

=head1 API

This normally used by the Form::Select and Form::Checkbox objects
to hold information about the Options available.

=head2 Constructor

=over

=item new

=back

=head2 Methods

=over

=item as_args

=item selected

=item disabled

=item text

=item value

=back

=head2 Functions

This object has no functions

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=cut
