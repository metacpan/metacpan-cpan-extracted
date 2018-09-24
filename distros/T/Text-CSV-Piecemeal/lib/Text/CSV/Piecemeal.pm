package Text::CSV::Piecemeal;

use strict;
use warnings;
use Text::CSV;

# ABSTRACT: Piecemeal wrapper around Text::CSV for constructing csv files

our $VERSION = 'v0.0001';

 
=head1 NAME

Text::CSV::Piecemeal

=head1 WARNING

This module is in early development and may change.

=head1 SYNOPSIS

	$csv = Text::CSV::Piecemeal->new( { sep_char => ',' } );

=cut

=head1 DESCRIPTION

This module provides a simple wrapper around Text::CSV to allow creation of a csv bit by bit.

This is a work in progress and contains incomplete test code, methods are likely to be refactored, you have been warned.


=head1 METHODS

=cut

=head2 new( \%args ) 

	Create new Piecemeal object takes a hashref of args to pass to Text::CSV ( currently only sep_char )

	If no args provided defaults are applied:
	sep_char => ","
=cut
sub new
{
	my ( $object, $args ) = @_;
	my $self = $args;
	bless $self;
	$self->{sep_char} //= ',';
	return $self;
}


=head2 push_value( $value )

	Pushes the provided value to the next cell, will close the previous cell if it has data but has not been closed
	
	Closes itself the next operation will be on the next cell, if you need to append to this use push_partial_value instead.

=cut
sub push_value
{
	my ( $self, $value ) = @_;
	$self->end_partial_value if $self->{partial_value};
	push @{ $self->{tmp_values} }, $value;
}


=head2 push_partial_value( $value )

	Concatinates the provided value to the current cell

=cut
sub push_partial_value
{
	my ( $self, $value ) = @_;
	$self->{partial_value} .= $value;
}


=head2 end_partial_value

	Close the current partial value so next operation is on next cell

=cut 
sub end_partial_value
{
	my $self = shift;
	if ( $self->{partial_value} )
	{
		my $value = $self->{partial_value};
		$self->{partial_value} = '';
		$self->push_value( $value );
	}
}


=head2 push_row( @values )

	Takes an array of values, starts a new row containing these values and closes the row

=cut
sub push_row
{
	my $self = shift;
	my @values = @_;
	$self->end_row if defined $self->{tmp_values}->[0];
	push @{ $self->{rows} }, \@values;
}


=head2 end_row

	Close the current row, next operation will start a new row.

=cut
sub end_row
{
	my $self = shift;
	$self->end_partial_value if $self->{partial_value};
	if ( defined $self->{tmp_values}->[0] )
	{
		my @values = @{ $self->{tmp_values} };
		$self->{tmp_values} = [];
		$self->push_row( @values );
	}
}

=head2 output

	Converts stored data into csv as a single string and returns it.	
=cut
sub output
{
	my $self = shift;
	my $csv = Text::CSV->new( { sep_char => $self->{sep_char} } );
	my $result;
	$self->end_row;
	for ( @{ $self->{rows} } )
	{
		$csv->combine(@$_);
		$result .= $csv->string() . "\n";
	}
	return $result;
}

=head1 SOURCE CODE

The source code for this module is held in a public git repository on Gitlab https://gitlab.com/rnewsham/text-csv-piecemeal

=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2018 Richard Newsham
 
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
 
=head1 BUGS AND LIMITATIONS
 
See rt.cpan.org for current bugs, if any.
 
=head1 INCOMPATIBILITIES
 
None known. 
 
=head1 DEPENDENCIES

	Text::CSV

=cut

1;
