package Tk::ListBrowser::Bar;

=head1 NAME

Tk::ListBrowser::Bar - Bar organizer for Tk::ListBrowser.

=head1 SYNOPSIS

 require Tk::ListBrowser;
 my $ib= $window->ListBrowser(@options,
    -arrange => 'bar'
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

sub KeyArrowNavig {
	my ($self, $dcol, $drow) = @_;
	return undef if $self->anchorInitialize;
	my $pool = $self->pool;
	my $i = $self->anchorGet;
	if ($drow eq 0) { #horizontal move
		my $col = $i->column;
		my $row = $i->row;
		if ($dcol > 0) { #to the right
			my $max = $self->lastColumnInRow($row);
			if ($col eq $max) {
				$col = -1;
				$row ++
			}
		} else { #to the left
			if ($col eq 0) {
				$row --;
				$col = $self->lastColumnInRow($row) + 1;
			}
		}
		my $ncol = $col + $dcol;
		my $index = $self->indexColumnRow($ncol, $row);
		return $self->getIndex($index);
	} else { #vertical move
		my $index = $self->index($i->name);
		my $pool = $self->pool;
		$index = $index + $drow;
		return $self->getIndex($index);
	}
}

sub nextPosition {
	my ($self, $x, $y, $column, $row) = @_;
	my $cellwidth = $self->cellWidth;
	$x = $x + $cellwidth + 1;
	$column ++;
	return ($x, $y, $column, $row)
}


sub scroll {
	return 'horizontal'
}

sub type {
	return 'column'
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please report them here: L<https://github.com/haje61/Tk-ListBrowser/issues>.

=head1 SEE ALSO

=over 4

=item L<Tk::ListBrowser>

=item L<Tk::ListBrowser::Column>

=item L<Tk::ListBrowser::Item>

=item L<Tk::ListBrowser::List>

=item L<Tk::ListBrowser::Row>

=back

=cut

1;
