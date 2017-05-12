package WWW::Ruler;

use strict;
use warnings;

use WWW::Ruler::Piece;

our $VERSION = '0.12';

sub new {
    my ( $class, %opts ) = @_;

    bless { %opts }, ref($class) || $class;
}

sub cut_off {
    my ( $self, %opts ) = @_;

    my (
	$page_size,
	$ruler_size,
	$page_number,
	$amount,
	$left_size,
	$right_size,
	$all_pages
    );

    for ( qw( page_size ruler_size page_number amount ) ) {
	eval("\$$_ = " . q{defined( $opts{$_} ) ? $opts{$_} : $self->{$_}});
    }

    # A building of ruler line...
    my $piece	= WWW::Ruler::Piece->new( $amount );

    return $piece->outside(1)
      unless $amount;

    $all_pages		= int( ($amount - 1) / $page_size + 1 );

    $left_size		= int( ( $ruler_size - 1 ) / 2 );
    $right_size		= $ruler_size - 1 - $left_size;

    return $piece->outside(1)
      if ( $page_number > $all_pages || $page_number <= 0 );

    $piece->add_ruler_item( { type => 'prev_pointer', page_number => $page_number - 1} ) if ( $page_number > 1 );
    $piece->add_ruler_item( { type => 'page', page_number => 1, ( $page_number == 1 ? ( current_page => 1 ) : () )} );
    $piece->add_ruler_item( { type => 'ellipsis' } ) if ( $page_number - $left_size > 2 );

    for ( my ($n, $cnt) = ( $page_number - $left_size < 2 ? 2 : $page_number - $left_size, $ruler_size );
      $n < $all_pages && $cnt > 0;
      $cnt--, $n++)
    {
	$piece->add_ruler_item( { type => 'page', page_number => $n, ( $n == $page_number ? ( current_page => 1 ) : () ) } );
    }

    $piece->add_ruler_item( { type => 'ellipsis' } ) if ( $page_number + $right_size < $all_pages - 1 );
    $piece->add_ruler_item( { type => 'page', page_number => $all_pages, ( $page_number == $all_pages ? ( current_page => 1 ) : () )} ) if $all_pages > 1;
    $piece->add_ruler_item( { type => 'next_pointer', page_number => $page_number + 1} ) if ( $page_number < $all_pages );

    # Calculation of bounds
    $piece->{start}	= ( $page_number - 1 ) * $page_size;
    $piece->{end}	= $page_number < $all_pages ? $piece->{start} + $page_size - 1 : $amount - 1;

    return $piece;
}

1;

__END__

=pod

=head1 NAME

WWW::Ruler - a helper for building rulers for visual presentation (in WWW applictions for example)

=head1 SYNOPSIS

Now this module is beta. Not all documentation is finished yet.

    use WWW::Ruler;

    my $ruler = WWW::Ruler->new( page_size => $page_size, ruler_size => 15 );

    # $page_number - a number of current page
    # $array_length - a dimension of array of data
    my $piece = $ruler->cut_off( page_number => $page_number, amount => $array_length );

    # Detail in manual WWW::Ruler::Piece(3)
    $piece->outside;			# true if piece are located outside of array of data. You can test before next methods
    $ruler_array = $piece->ruler;       # An array of ruler items for drawing
    $start_index = $piece->start;       # A start index of array (a base is zero) for cutting
    $end_index   = $piece->end;         # An end index  of array (a base is zero) for cutting
    $size        = $piece->size;        # A size (dimension) of piece of current page.

=head1 DESCRIPTION

This class will help to make a ruler with a following layouts and calculate
start and end indices. Ruler can look like these examples:

[E<nbsp>E<lt>E<lt>E<nbsp>] [E<nbsp>1E<nbsp>] [E<nbsp>...E<nbsp>] [E<nbsp>4E<nbsp>] [E<nbsp>5E<nbsp>] (E<nbsp>6E<nbsp>) [E<nbsp>7E<nbsp>] [E<nbsp>8E<nbsp>] [E<nbsp>...E<nbsp>] [E<nbsp>999E<nbsp>] [E<nbsp>E<gt>E<gt>E<nbsp>]

[E<nbsp>1E<nbsp>] [E<nbsp>4E<nbsp>] [E<nbsp>5E<nbsp>] (E<nbsp>6E<nbsp>) [E<nbsp>7E<nbsp>] [E<nbsp>8E<nbsp>] [E<nbsp>...E<nbsp>] [E<nbsp>999E<nbsp>] [E<nbsp>E<gt>E<gt>E<nbsp>]

[E<nbsp>E<lt>E<lt>E<nbsp>] [E<nbsp>1E<nbsp>] [E<nbsp>...E<nbsp>] [E<nbsp>4E<nbsp>] [E<nbsp>5E<nbsp>] (E<nbsp>6E<nbsp>) [E<nbsp>7E<nbsp>] [E<nbsp>8E<nbsp>] [E<nbsp>E<gt>E<gt>E<nbsp>]

Here (E<nbsp>1E<nbsp>) and (E<nbsp>6E<nbsp>) are "current" pages. A [E<nbsp>E<lt>E<lt>E<nbsp>], [E<nbsp>E<gt>E<gt>E<nbsp>] and [E<nbsp>DIGITE<nbsp>] -
linked buttons for other pages for example. And the [E<nbsp>...E<nbsp>] is an ellipse figure of
span between page numbers (not linked).

=head1 CONSTRUCTOR

    $ruler = WWW::Ruler->new( page_size => $page_size, ruler_size => 15 );
    $ruler = WWW::Ruler->new;

You can construct object with and without options.

=head1 OPTIONS

These options can be passed in L</new> and L</cut_off> methods. Options in
L</cut_off> method redefine constructor's options.

=over

=item page_size

Number. How many do you have items in one page?

=item ruler_size

A desired maximum number of buttons (not included button [<<], [>>] and [...]).
It is only desired amount! Please notice that real items in ruler can be up 3-4
items! It option will be improved in next versions.

=item page_number

A current number of page for which this ruler to be builded. It starts from 1.

=item amount

An amount of items in whole array.

=back

=head1 METHODS

=over

=item new( %opts )

The constructor. The %opts are optional. Any options can be redefined in L</cut_off> method.

=item cut_off ( %opts )

This method makes virtual I<cut off> of array and contructs array of ruler
items. Any options passed into this method redefine options of constructor (to see L</SYNOPSIS>).

Returns an instance of L<WWW::Ruler::Piece> object.
You can test a validation of piece bounds by L<WWW::Ruler::Piece/outside> method.

=back

=head1 AUTHOR

This module has been written by Perlover <perlover@perlover.com>

=head1 LICENSE

This module is free software and is published under the same terms as Perl
itself.
