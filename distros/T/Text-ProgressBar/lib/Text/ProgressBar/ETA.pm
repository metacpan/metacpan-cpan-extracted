package Text::ProgressBar::ETA;
use Moose; 
our $VERSION = '0.2';
use Text::ProgressBar;

extends 'Text::ProgressBar::Timer';

sub update{
    my $self  = shift;
    my $pbar  = shift;
    
    if ($pbar->currval == 0) {
        return 'ETA:  --:--:--';
    } elsif ($pbar->finished) {
        return sprintf("Time:  %s", $self->format_time($pbar->seconds_elapsed)); 
    } else {
        my $elapsed = $pbar->seconds_elapsed;
        my $eta = int($elapsed * $pbar->maxval / $pbar->currval - $elapsed);
        return sprintf("ETA:  %s", $self->format_time($eta));
    }
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::ETA - Estimated Time for Accomplishment
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS

    use Text::ProgressBar::ETA;

    my $bar = Text::ProgressBar->new(widgets => [Text::ProgressBar::ETA->new()]);
    $bar->start();
    for my $i (1..100) {
        sleep 0.2;
        $bar->update($i+1);
    }
    $bar->finish;

=head1 DESCRIPTION
 
Widget which attempts to estimate the time of accomplishment. It
inherites attribute of 'Timer'. Example of defalut output:

    ETA:  0:0:14  

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
