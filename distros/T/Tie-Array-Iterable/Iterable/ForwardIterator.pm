#!/usr/bin/perl -w

package Tie::Array::Iterable::ForwardIterator;

#=============================================================================
#
# $Id: ForwardIterator.pm,v 0.03 2001/11/16 02:27:58 mneylon Exp $
# $Revision: 0.03 $
# $Author: mneylon $
# $Date: 2001/11/16 02:27:58 $
# $Log: ForwardIterator.pm,v $
# Revision 0.03  2001/11/16 02:27:58  mneylon
# Fixed packing version variables
#
# Revision 0.01.01.2  2001/11/16 02:12:16  mneylon
# Added code to clean up iterators after use
# clear_iterators() now not needed, simply returns 1;
#
# Revision 0.01.01.1  2001/11/15 01:41:21  mneylon
# Branch from 0.01 for new features
#
# Revision 0.01  2001/11/11 18:36:14  mneylon
# Initial Release
#
#
#=============================================================================

use 5.006;
use strict;

my $FORWARDID;
my %FORWARDITERS;

BEGIN {
	use Exporter   ();
	use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	( $VERSION ) = '$Revision: 0.03 $ ' =~ /\$Revision:\s+([^\s]+)/;
	@ISA         = qw( Exporter );
	@EXPORT      = qw( );
	@EXPORT_OK   = qw( );
	%EXPORT_TAGS = (  );
}

sub new {
	my $class = shift;
	my $iterarray = shift;
	my $pos = shift || 0;
	warn "Must be created from a Tie::Array::Iterable"
		unless ( UNIVERSAL::isa( $iterarray, "Tie::Array::Iterable" ) );
	my %data = (
		array => $iterarray,
		pos => $pos,
		id => ++$FORWARDID );
	$FORWARDITERS{ $data{ id } } = \%data;
	return bless \%data, $class;
}

sub DESTROY {
	my $self = shift;
	$self->{ array }->_remove_forward_iterator( $self->{ id } );
}

sub at_start () {
	my $self = shift;
	if ( $self->{ pos } <= 0 ) {
		return 1;
	} else {
		return 0;
	}
}

sub at_end () {
	my $self = shift;
	if ( $self->{ pos } >= scalar @{ $self->{ array } } ) {
		return 1;
	} else {
		return 0;
	}
}

sub to_start () {
	my $self = shift;
	$self->{ pos } = 0;
}

sub to_end () {
	my $self = shift;
	$self->{ pos } = scalar @{ $self->{ array } };
}

sub value {
	my $self = shift;
	if ( $self->at_end() ) { return undef };
	return $self->{ array }->[ $self->{ pos } ];
}

sub set_value {
	my $self = shift;
	my $value = shift;
	if ( $self->at_end() ) { return undef; };
	return ( $self->{ array }->[ $self->{ pos } ] = $value );
}

sub index {
	my $self = shift;
	return $self->{ pos };
}

sub set_index {
	my $self = shift;
	my $index = shift;
	if ( $index < 0 ) { $index = 1; }
	if ( $index > scalar @{ $self->{ array } } )
		{ $index = scalar @{ $self->{ array } }; }
	$self->{ pos } = $index;
}

sub next () {
	my $self = shift;
	if ( $self->at_end() ) {
		return undef; 
	}
	$self->{ pos }++;
	return $self->value();
}

sub prev () {
	my $self = shift;
	if ( $self->at_start() ) {
		return undef;
	}
	$self->{ pos }--;
	return $self->value();
}

sub forward {
	my $self = shift;
	my $steps = shift;
	die "Number of steps must be non-negative" if $steps < 0;
	$steps = 1 if ( !$steps && $steps ne "0" );
	my $value = $self->value();
	$value = $self->next() for ( 1..$steps );
	return $value;
}

sub backward {
	my $self = shift;
	my $steps = shift;
	die "Number of steps must be non-negative" if $steps < 0;
	$steps = 1 if ( !$steps && $steps ne "0" );
	my $value = $self->value();
	$value = $self->prev() for ( 1..$steps );
	return $value;
}

sub _lookup ($) {
	my $id = shift;
	return $FORWARDITERS{ $id };
}

sub _id {
	my $self = shift;
	return $self->{ id };
}

1;
__END__


=head1 NAME

Tie::Array::Iterable::ForwardIterator - Forward Iterator object

=head1 DESCRIPTION

Please see the L<Tie::Array::Iterable> documentation for full usage.

=head1 AUTHOR

Michael K. Neylon E<lt>mneylon-pm@masemware.comE<gt>

=head1 COPYRIGHT

Copyright 2001 by Michael K. Neylon E<lt>mneylon-pm@masemware.comE<gt>.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut