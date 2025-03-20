package Tk::ListBrowser::List;

=head1 NAME

Tk::ListBrowser - Tk::ListBrowser::List - List organizer for Tk::ListBrowser.

=head1 SYNOPSIS

 require Tk::ListBrowser;
 my $ib= $window->ListBrowser(@options,
    -arrange => 'list'
 )->pack;
 $ib->add('item_1', -image => $image1, -text => $text1);
 $ib->add('item_2', -image => $image2, -text => $text2);
 $ib->refresh;

=head1 DESCRIPTION

Contains all the drawing routines for L<Tk::ListBrowser> to
draw and navigate the list in a list organized manner.

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
	$y = $y + $cellheight + 1;
	$row ++;
	return ($x, $y, $column, $row)
}


sub scroll {
	return 'vertical'
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

=item L<Tk::ListBrowser::Bar>

=item L<Tk::ListBrowser::Column>

=item L<Tk::ListBrowser::Item>

=item L<Tk::ListBrowser::Row>

=back

=cut

1;
