package Text::Snippet::TabStop::Cursor;
BEGIN {
  $Text::Snippet::TabStop::Cursor::VERSION = '0.04';
}

# ABSTRACT: Provides a bi-directional iterator interface for moving from one tab-stop to it's siblings

use strict;
use warnings;
use Class::XSAccessor getters => {snippet => 'snippet'};
use Scalar::Util qw(blessed refaddr);
use Carp qw(croak);


sub new {
	my $class = shift;
	my %args = (i => -1, @_);
	croak "snippet must be ISA Text::Snippet" unless blessed $args{snippet} eq 'Text::Snippet';
	return bless \%args, $class;
}

sub has_prev {
	my $self  = shift;
	my $stops = $self->snippet->tab_stops;
	return @$stops && $self->{i} > 0;
}

sub prev {
	my $self = shift;
	return $self->has_prev ? $self->snippet->tab_stops->[ --$self->{i} ] : ();
}

sub has_next {
	my $self  = shift;
	my $stops = $self->snippet->tab_stops;
	return @$stops && $self->{i} < $#{$stops};
}

sub next {
	my $self = shift;
	return $self->has_next ? $self->snippet->tab_stops->[ ++$self->{i} ] : ();
}

sub current {
	my $self  = shift;
	return unless($self->{i} >= 0);
	my $stops = $self->snippet->tab_stops;
	if ( exists( $stops->[ $self->{i} ] ) ) {
		return $stops->[ $self->{i} ];
	}
	return;
}

sub _is_current {
	my $self = shift;
	my $current = $self->current;
	my $tab_stop = shift;
	return blessed($tab_stop) && (refaddr($tab_stop) == refaddr($current) || ($tab_stop->has_parent && refaddr($tab_stop->parent) == refaddr($current)));
}

sub current_position {
	my $self = shift;
	my $current = $self->current;
	my ($line, $column) = (0,0);
	return [$line,$column] if ! defined $current;
	
	foreach my $c(@{ $self->snippet->chunks }){
		last if($self->_is_current($c));
		my $text = blessed($c) && $c->can('to_string') ? $c->to_string || '': "$c";
		foreach my $char(split(/(\n)/,$text)){
			if($char eq "\n"){
				$line++;
				$column = 0;
			} else {
				$column += length($char);
			}
		}
	}
	return [$line,$column];
}

sub current_char_position {
	my $self = shift;
	my $pos = 0;
	my $current = $self->current;
	return $pos if ! defined $current;
	foreach my $c( @{ $self->snippet->chunks } ){
		last if($self->_is_current($c));
		my $text = blessed($c) && $c->can('to_string') ? $c->to_string || '': "$c";
		$pos += length($text);
	}
	return $pos;
}

sub is_terminal {
	my $self = shift;
	return if(!defined$self->current);
	return $self->current->index == 0;
}

1;

__END__
=pod

=head1 NAME

Text::Snippet::TabStop::Cursor - Provides a bi-directional iterator interface for moving from one tab-stop to it's siblings

=head1 VERSION

version 0.04

=head1 CLASS METHODS

=head2 new

=head1 INSTANCE METHODS

=over 4

=item * snippet

Maintains a reference to the snippet that this cursor is iterating over.

=item * has_prev

Returns true/false depending on whether the cursor can move to a previous
tab stop.

=item * prev

Moves the cursor to the previous tab stop and returns that tab stop.
You can only iterate one element off the end of the underlying set of
tab stops.

=item * has_next

Returns true/false depending on whether the cursor can move to a
subsequent tab stop.

=item * next

Moves the cursor to the next tab stop and returns that tab stop.  You can
only iterate one element off the end of the underlying set of tab stops.

=item * current

Returns the tab stop the cursor is currently pointing at.  When the cursor
is first created, this method will always return C<undef> until C<next>
has been called at least once.

=item * current_position

Returns an ArrayRef reflecting the line/column position relative to
the beginning of the snippet.  Both numbers are zero-based so a tab
stop starting on the first line, first character would return a value
of C<[0,0]>.

=item * current_char_position

Returns an integer reflecting the current cursor position where 0 is the 
first character of the snippet and each character is counted up until
the current position of the cursor.

=item * is_terminal

Returns true if this tab stop is a "terminal" tab stop (i.e. once the
user iterates to this tab stop, the iterator should be restored and
normal editing should resume).

=back

=head1 AUTHOR

  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

