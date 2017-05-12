package Text::Graph::DataSet;

use strict;
use warnings;
use Moo;
use namespace::clean;

our $VERSION = '0.83';

has values => (
    is     => 'ro',
    reader => 'get_values',
);
has labels => (
    is     => 'ro',
    reader => 'get_labels',
);

#
# This routine is quite complicated to support the bizarre interface that I
# originally supported.
sub BUILDARGS
{
    my ( $class, @args ) = @_;
    return { values => [], labels => [] } if !@args;
    my ( $values, $labels, $hash ) = ( [], undef, undef );

    if( ref $args[0] eq ref [] )
    {
        $values = shift @args;
        if( ref $args[0] eq ref [] )
        {
            $labels = shift @args;
        }
    }
    elsif( ref $args[0] eq ref {} )
    {
        $hash = shift @args;
        if( ref $args[0] eq ref [] )
        {
            $labels = shift @args;
        }
    }
    die "Odd number of parameters to new.\n" if @args % 2 == 1;
    my %real_args = ( sort => sub { sort @_ }, @args );
    my $sortref = delete $real_args{sort};
    $hash ||= delete $real_args{hash};
    if( defined $hash )
    {
        if( $sortref )
        {
            my ( $pkg ) = caller;
            $labels ||= [ $sortref->( keys %{$hash} ) ] if !$labels;
        }
        else
        {
            $labels ||= [ keys %{$hash} ];
        }
        $values = [ @{$hash}{ @{$labels} } ];
        $hash   = undef;
    }
    $labels ||= [];
    push @{$labels}, ( '' ) x ( @{$values} - @{$labels} ) if @{$values} > @{$labels};
    return { values => $values, labels => $labels, %real_args };
}

#
# Support the list or array ref original interface.
sub _list_or_ref
{
    my ( $orig, $self ) = @_;
    my $val = $orig->( $self );
    return wantarray ? @{$val} : $val;
}

around 'get_values' => \&_list_or_ref;
around 'get_labels' => \&_list_or_ref;

1;
__END__

=head1 NAME

Text::Graph::Data - Encapsulate data for Text::Graph

=head1 VERSION

This document describes "Text::Graph::Data" version 0.82.

=head1 SYNOPSIS

  use Text::Graph::Data;

  my $gdat = Text::Graph::Data->new( \@values, \@labels );

=head1 DESCRIPTION

Encapsulate the description of the data used by the C<Text::Graph> object.

The C<Text::Graph> object needs data values and labels for each data
value to generate appropriate graphs. The C<Text::Graph::Data> object allows
several methods of constructing this data and provides a simple interface
for retrieving it.

=head1 METHODS

=head2 new

The C<new> method creates a C<Text::Graph::Data> object. The C<new> method can
create this object from several different kinds of input.

If the first parameter is a single array reference, this becomes the values
for the C<Text::Graph::Data> object. If the first and second parameters are
array references, they become the values and labels for the
C<Text::Graph::Data> object, respectively.

If the first parameter is a hash reference, it is used to construct the value
and labels for the C<Text::Graph::Data> object. If there are no other
parameters, the keys of the hash will be sorted ASCIIbetically to generate the
labels, and the values will be the corresponding values from the hash. If the
second parameter is an array reference, it will be used as the labels for the
the C<Text::Graph::Data> object, and the values will be the corresponding
values from the hash.

After the above parameters are taken care of, or if they did not exist, any
remaining parameters are used to customize the data set. Those parameters are
taken as name/value pairs to set various options on the object. The defined
options are

=over 4

=item values

A reference to an array of values to use for this data set.

=item labels

A reference to an array of labels to use for this data set.

=item hash

A reference to a hash containing the values and labels for this data set.

=item sort

A reference to a subroutine that takes the list of labels and sorts them into
the appropriate order. The default value is an ASCIIbetical sort.

=back

=head2 get_values

In scalar context, C<get_values> returns a reference to the array containing
the values in this data set. In list context, it returns the values as a list.

=head2 get_labels

In scalar context, C<get_labels> returns a reference to the array containing
the labels in this data set. In list context, it returns the labels as a list.

=head1 AUTHOR

G. Wade Johnson, gwadej@cpan.org

=head1 COPYRIGHT

Copyright 2004-2014 G. Wade Johnson

This module is free software; you can distribute it and/or modify it under
the same terms as Perl itself.

perl(1).

=cut
