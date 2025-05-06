package Tk::ListBrowser::Column;

=head1 NAME

Tk::ListBrowser - Tk::ListBrowser::Column - Column organizer for Tk::ListBrowser.

=head1 SYNOPSIS

 require Tk::ListBrowser;
 my $ib= $window->ListBrowser(@options,
    -arrange => 'column',
 )->pack;
 $ib->add('item_1', -image => $image1, -text => $text1);
 $ib->add('item_2', -image => $image2, -text => $text2);
 $ib->refresh;

=head1 DESCRIPTION

Contains all the drawing routines for L<Tk::ListBrowser> to
draw and navigate the list in a column organized manner.

No user serviceable parts inside.

=cut

use strict;
use warnings;
use vars qw ($VERSION);
$VERSION =  0.01;

use base qw(Tk::ListBrowser::Row);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return $self
}

sub nextPosition {
	my ($self, $x, $y, $column, $row) = @_;
	my $cellheight = $self->cellHeight;
	my $cellwidth = $self->cellWidth;
	my $newy = $y + ($cellheight * 2);
	my ($cwidth, $cheight) = $self->canvasSize;
	if ($newy >= $cheight) {
		$y = $self->cget('-margintop');
		$x = $x + $cellwidth + 1;
		$row = 0;
		$column ++;
	} else {
		$y = $y + $cellheight + 1;
		$row ++;
	}
	return ($x, $y, $column, $row)
}

sub scroll {
	return 'horizontal'
}

sub type {
	return 'column'
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=back

=cut

1;
