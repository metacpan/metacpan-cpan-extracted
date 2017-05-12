package Text::ProgressBar::AnimatedMarker;
use Moose; 
our $VERSION = '0.2';
use Text::ProgressBar;

with 'Text::ProgressBar::Widget';

has 'markers' => (is => 'rw', isa => 'Str', default  => '|/-\\');
has 'curmark' => (is => 'rw', isa => 'Num', default  => -1);

sub update{
    my $self  = shift;
    my $pbar  = shift;

    return substr($self->markers, 0, 1) if ($pbar->finished);
    $self->curmark(($self->curmark +1) % length($self->markers));
    return substr($self->markers, $self->curmark, 1);
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar:::AnimatedMarker - a rotating wheel on screen
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS
 
    use Text::ProgressBar::AnimatedMarker;

    my $bar = Text::ProgressBar->new(widgets => [Text::ProgressBar::AnimatedMarker->new()]);
    $bar->start();
    for my $i (1..50) {
        sleep 0.08;
        $bar->update($i+1);
    }
    $bar->finish;
    
=head1 DESCRIPTION
 
An animated marker for the progress bar which defaults to appear as if
it were rotating, indicating that the program is busy but not indicating
how much progress has been made.

=head1 ATTRIBUTES
 
=head2 markers

defines characters for animating rotating

=head2 curmark 

current position of marker

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
