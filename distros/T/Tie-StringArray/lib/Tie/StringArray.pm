package Tie::StringArray;
use strict;
use vars qw( $VERSION );
use warnings;

use Carp qw(croak);

$VERSION = '1.0001';


=encoding utf8

=head1 NAME

Tie::StringArray - use a tied string as an array of chars

=head1 SYNOPSIS

	use Tie::StringArray;

	tie my @array, 'Tie::StringArray', qw(137 88 54);

=head1 DESCRIPTION

The C<Tie::StringArray> module is a demonstration from I<Mastering
Perl>. It stores integers between 0 and 255 as a single character
in a string that acts like an array through C<tie>. Behind the C<tie>, 
the array is a single string, so there's only one scalar to store.

I don't think this is particularly useful for anything real.

=over 4

=item new

=cut


sub _null { "\x00" }
sub _last () { $_[0]->FETCHSIZE - 1 }

sub _normalize_index { 
	$_[1] == abs $_[1] ? $_[1] : $_[0]->_last + 1 - abs $_[1] 
	}

sub _store  { chr $_[1] }
sub _show   { ord $_[1] }
sub _string { ${ $_[0] } }

sub TIEARRAY {
	my( $class, @values ) = @_;

	my $string = '';
	my $self = bless \$string, $class;

	my $index = 0;

	$self->STORE( $index++, $_ ) foreach ( @values );

	$self;
	}

sub FETCH {
	my $index = $_[0]->_normalize_index( $_[1] );

	$index > $_[0]->_last ? () : $_[0]->_show(
		substr( $_[0]->_string, $index, 1 )
		);
	}

sub FETCHSIZE { length $_[0]->_string }

sub STORESIZE {
	my $self     = shift;
	my $new_size = shift;

	my $size = $self->FETCHSIZE;

	if( $size > $new_size ) { # truncate
		$$self = substr( $$self, 0, $size );
		}
	elsif( $size < $new_size ) { # extend
		$$self .= join '', ($self->_null) x ( $new_size - $size );
		}
	}

sub STORE {
	my $self  = shift;
	my $index = shift;
	my $value = shift;

	croak( "The magnitude of [$value] exceeds the allowed limit [255]" )
		if( int($value) != $value || $value > 255 );

	$self->_extend( $index ) if $index > $self->_last;

	substr( $$self, $index, 1, chr $value );

	$value;
	}

sub _extend {
	my $self  = shift;
	my $index = shift;

	$self->STORE( 0, 1 + $self->_last )
		while( $self->_last >= $index );
	}

sub EXISTS  { $_[0]->_last >= $_[1] ? 1 : 0 }
sub CLEAR   { ${ $_[0] } = '' }

sub SHIFT   { $_[0]->_show( substr ${ $_[0] }, 0, 1, '' ) }
sub POP     { $_[0]->_show( chop   ${ $_[0] }           ) }

sub UNSHIFT {
	my $self = shift;

	foreach ( reverse @_ ) {
		substr ${ $self }, 0, 0, $self->_store( $_ )
		}
	}

sub PUSH {
	my $self = shift;

	$self->STORE( 1 + $self->_last, $_ ) foreach ( @_ )
	}

sub SPLICE {
	my $self      = shift;

	my $arg_count = @_;
	my( $offset, $length, @list ) = @_;

	if(    0 == $arg_count ) {
		( 0, $self->_last )
		}
	elsif( 1 == $arg_count ) {
		( $self->_normalize_index( $offset ), $self->_last )
		}
	elsif( 2 <= $arg_count ) { # offset and length only
		no warnings;
		( $self->_normalize_index( $offset ), do {
			if( $length < 0 ) { $self->_last - $length }
			else              { $offset + $length - 1   }
			}
		)
		}

	my $replacement = join '', map { chr } @list;
	
	my @removed = 
		map { ord }
		split //,
		substr $$self, $offset, $length;

	substr $$self, $offset, $length, $replacement;

	if( wantarray ) {
		@removed;
		}
	else {
		defined $removed[-1] ? $removed[-1] : undef;
		}

	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/tie-stringarray/

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2013, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
