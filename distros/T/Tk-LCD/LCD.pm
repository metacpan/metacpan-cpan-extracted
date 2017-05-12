$Tk::LCD::VERSION = '1.3';

package Tk::LCD;

use base qw/Tk::Derived Tk::Canvas/;
use vars qw/$ELW %SHAPE %shape %LLCD %ULCD/;
use subs qw/ldifference/;
use strict;

Construct Tk::Widget 'LCD';

# LCD class data.

$ELW = 22;			# element pixel width

# %SHAPE stolen with appreciation from Donal K. Fellows' Tcl game
# of Maze. An LCD element can display a digit, space or minus sign.
# It's made up of 7 segments labelled 'a' through 'g'.  Each segment
# is defined by a series of Canvas widget polygon coordinates.
#
#    b
#    -
#  a| |c
#    -   <--- g
#  f| |d
#    -
#    e

%SHAPE = (
    'a' => [qw/ 3.0  5  5.2  3  7.0  5  6.0 15  3.8 17  2.0 15/],
    'b' => [qw/ 6.3  2  8.5  0 18.5  0 20.3  2 18.1  4  8.1  4/],
    'c' => [qw/19.0  5 21.2  3 23.0  5 22.0 15 19.8 17 18.0 15/],
    'd' => [qw/17.4 21 19.6 19 21.4 21 20.4 31 18.2 33 16.4 31/],
    'e' => [qw/ 3.1 34  5.3 32 15.3 32 17.1 34 14.9 36  4.9 36/],
    'f' => [qw/ 1.4 21  3.6 19  5.4 21  4.4 31  2.2 33  0.4 31/],
    'g' => [qw/ 4.7 18  6.9 16 16.9 16 18.7 18 16.5 20  6.5 20/],
);

# %shape is 1/2 the size of %SHAPE.

foreach my $c (keys %SHAPE) {
    $shape{$c} = [ map {$_ / 2.0} @{$SHAPE{$c}} ];
}

# To display an LCD element we must turn on and off certain segments.
# %LLCD defines a list of segments to turn on for any particular
# symbol.

%LLCD = (
    '0' => [qw/a b c d e f/],
    '1' => [qw/c d/],
    '2' => [qw/b c e f g/],
    '3' => [qw/b c d e g/],
    '4' => [qw/a c d g/],
    '5' => [qw/a b d e g/],
    '6' => [qw/a b d e f g/],
    '7' => [qw/b c d/],
    '8' => [qw/a b c d e f g/],
    '9' => [qw/a b c d e g/],
    '-' => [qw/g/],
    ' ' => [''],
);

# Similarly, %ULCD defines a list of LCD element segments to turn off
# for any particular symbol. In Maze, %ULCD was manually generated,
# but in the Perl/Tk rendition unlit LCD segments are dynamically
# computed as the set difference of qw/a b c d e f g/ and the lit
# segments.

$ULCD{$_} = [ ldifference [keys %SHAPE], $LLCD{$_} ] foreach (keys %LLCD);

sub Populate {

    my($self, $args) = @_;
    $self->SUPER::Populate($args);

    $self->ConfigSpecs(
        -commify    => [qw/PASSIVE commify    Commify    1/    ],
        -elements   => [qw/METHOD  elements   Elements   5/    ],
        -height     => [$self, qw/ height     Height     36/   ],
        -onoutline  => [qw/PASSIVE onoutline  Onoutline  cyan/ ],
        -onfill     => [qw/PASSIVE onfill     Onfill     black/],
        -offoutline => [qw/PASSIVE offoutline Offoutline white/],
        -offfill    => [qw/PASSIVE offfill    Offfill    gray/ ],
        -size       => [qw/METHOD  size       Size       large/ ],
        -variable   => [qw/METHOD  variable   Variable/, undef ],
    );

} # end Populate

# Public methods.

sub set {			# show an LCD number

    my ($self, $number) = @_;

    $self->delete('lcd');
    return unless $number;

    my $onoutl    = $self->cget(-onoutline);
    my $onfill    = $self->cget(-onfill);
    my $offoutl   = $self->cget(-offoutline);
    my $offfill   = $self->cget(-offfill);
    my $shape;
    my $size      = $self->cget(-size);
    my $x_offset  = 0;
    my $y_offset;
    if ($size eq 'large') {
	$shape    = \%SHAPE;
	$y_offset = 0;
    } else {
	$shape    = \%shape;
	$y_offset = $ELW / 2 - 4;
	$_ = $number;
	if ($self->cget(-commify)) {
	    s/^\s+//;
	    s/\s+$//;
	    s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
	}
	$number = $_;
    }

    foreach my $c (split '', sprintf '%' . $self->{elements} . 's', $number) {
	if ($c =~ /[\.\,]/) {
	    if ($size eq 'small') {
	        $self->move(
                    $self->createPolygon(
                          ($c eq '.') ?
                          (0, 0, 0, 2, 2, 2, 2, 0) :
                          (0, 4, 1, 4, 2, 3, 2, 0, 0, 0, 0, 2, 2, 2),
                        -tags    => 'lcd',
                        -outline => $onoutl,
                        -fill    => $onfill,
                    ),
                $x_offset - 5, 22);
	    }
	    next;
	}
        foreach my $symbol (@{$LLCD{$c}}) {

            $self->move(
			$self->createPolygon(
                            $shape->{$symbol},
                            -tags    => 'lcd',
                            -outline => $onoutl,
                            -fill    => $onfill,
                        ),
            $x_offset, $y_offset);

        }
        foreach my $symbol (@{$ULCD{$c}}) {

            $self->move(
			$self->createPolygon(
                            $shape->{$symbol},
                            -tags    => 'lcd',
                            -outline => $offoutl,
                            -fill    => $offfill,
                        ),
            $x_offset, $y_offset);

	}
        $x_offset += $ELW;
    } # forend all characters

} # end set

# Private methods and subroutines.

sub elements {

    my ($self, $elements) = @_;
    if (defined $elements) {
	$self->{elements} = $elements;
	$self->configure(-width => $elements * $ELW);
    } else {
	$self->{elements};
    }

} # end elements

sub ldifference {               # @d = ldifference \@l1, \@l2;

    my($l1, $l2) = @_;
    my %d;
    @d{@$l2} = (1) x @$l2;
    return grep(! $d{$_}, @$l1);

} # end ldifference

sub size {

    my ($self, $size) = @_;
    if (defined $size) {
	die "-size must be 'large' or 'small'." unless $size =~ /^large|small$/;
	$self->{size} = $size;
    } else {
	$self->{size};
    }

} # end size
 
sub variable {

    use Tk::Trace;

    my ($lcd, $vref) = @_;

    my $st = [sub {
        my ($index, $new_val, $op, $lcd) = @_;
        return unless $op eq 'w';
        $lcd->set($new_val);
        $new_val;
    }, $lcd];

    $lcd->traceVariable($vref, 'w' => $st);
    $lcd->{watch} = $vref;

    $lcd->OnDestroy( [sub {$_[0]->traceVdelete($_[0]->{watch})}, $lcd] );

} # end variable

1;
__END__

=head1 NAME

Tk::LCD - display Liquid Crystal Display symbols.

=head1 SYNOPSIS

 use Tk::LCD;

 $lcd = $parent->LCD(-opt => val, ... );

=head1 DESCRIPTION

Tk::LCD is a Canvas derived widget, based on a code snippet from
Donal K. Fellows' Maze game. LCD symbols are displayed in elements
composed of 8 segments, labeled "a" though "g", some on and some
off.  For instance, the number 8 requires one LCD element that has
all 8 segments lit:

     b

     -
 a  | | c
     -      <------  g
 f  | | d
     _  

     e

A Tk::LCD widget can consist of any number of elements, specified
during widget creation.  To actually display an LCD number, either
invoke the set() method, or use the -variable option.

LCD elements can display a space, minus sign or a numerical diget, 
meaning that any positive or negative I<integer number> can be displayed.

LCD elements can also be either I<large> or I<small> in size.  If an LCD
widget's size is I<small>, then there is room enough between elements
to display dots and commas. As a result, any positive or negative I<decimal
number> can be displayed. Additionally, numbers can be
"commified", that is, commas are inserted every third digit to the
left of the decimal point.

=head1 OPTIONS

The following option/value pairs are supported:

=over 4

=item B<-commify>

Pertinent only if the LCD size is small, a boolean indicating
whether a number is commified; that is, commas inserted every
third digit.  Default is 1.

=item B<-elements>

The number of LCD elements (digits).  Default is 5.

=item B<-onoutline>

Outline color for ON segments.

=item B<-onfill>

Fill color for ON segments.

=item B<-offoutline>

Outline color for OFF segments.

=item B<-offfill>

Fill color for OFF segments.

=item B<-size>

Size of LCD elements, either I<large> or I<small> (default is I<large>).

=item B<-variable>

A scalar reference that contains the LCD number to display.  The
widget is updated when this variable changes value.

=back

=head1 METHODS

=head2 $lcd->set($number);

Display $number in the LCD widget.

=head1 ADVERTISED WIDGETS

Component subwidgets can be accessed via the B<Subwidget> method.
This mega widget has no advertised subwidgets.

=head1 EXAMPLE

 $lcd = $mw->LCD(-variable => \$frog)->pack;
 $lcd->set(4000);
 $frog = 2001;

=head1 AUTHOR

sol0@Lehigh.EDU

Copyright (C) 2001 - 2003, Steve Lidie. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 KEYWORDS

LCD, Canvas

=cut
