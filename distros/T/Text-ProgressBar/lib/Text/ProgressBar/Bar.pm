package Text::ProgressBar::Bar;
use Moose; 
our $VERSION = '0.2';
use Text::ProgressBar;

with 'Text::ProgressBar::WidgetHFill';

has 'marker'    => (is => 'rw', isa => 'Str', default   => '#');
has 'left'      => (is => 'rw', isa => 'Str', default   => '|');
has 'right'     => (is => 'rw', isa => 'Str', default   => '|');
has 'fill'      => (is => 'rw', isa => 'Str', default   => ' ');
has 'fill_left' => (is => 'rw', isa => 'Bool', default  => 1);

sub update{
    my $self  = shift;
    my $pbar  = shift;
    my $width = shift;
    my ($left, $marked, $right, $fill)  = 
                ($self->left, $self->marker, $self->right, $self->fill);
    $width -= length($left) + length($right); 
    if ($pbar->maxval) {
        $marked x= ($pbar->currval / $pbar->maxval * $width);}
    else { $marked = '';}
    my $res;
    if ($self->fill_left) {
        ($res = sprintf("%s%-${width}s%s", $left, $marked, $right)) =~ s/ /$fill/g;
    } else {
        ($res = sprintf("%s%${width}s%s", $left, $marked, $right))  =~ s/ /$fill/g;
    }
    return $res;
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::Bar - progress bar which stretches to fill the line
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS

    use Text::ProgressBar::Bar;

    my $pbar = Text::ProgressBar->new(maxval => 300);
    $pbar->start();
    for my $i (1..300) {
        sleep 0.01;
        $pbar->update($i+1);
    }
    $pbar->finish;
    
=head1 DESCRIPTION
 
A progress bar which stretches to fill the line. The drawing ascii
characters can be changed during calling class constructor or by calling
the corresponding methods. Example of defalut output

    |#######              |

=head1 ATTRIBUTES
 
=head2 marker

character that moves from left to right default '#'

=head2 left

character that specify left margin default '|'

=head2 right

character that specify right margin default '|'

=head2 fill

fill character default is space ' '

=head2 fill_left

fill with fill character, defalut is True

=head1 METHODS

=head2 update

handler for redrawing current regions within the area. (Inherited from Widget.)

=head1 AUTHOR

Farhad Fouladi, C<< <farhad at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Farhad Fouladi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
