package Text::ProgressBar::Timer;
use Moose; 
our $VERSION = '0.2';
use Text::ProgressBar;

with 'Text::ProgressBar::Widget';

has 'format_string' => (is => 'rw', isa => 'Str', default  => 'Elapsed Time: %s');

sub BUILD {
    my $self = shift;
    $self->TIME_SENSITIVE(1);
}

sub format_time {
    # Formats time as the string 'HH:MM:SS'
    my $self = shift;
    my $sec  = shift;
    my $h    = int($sec/3600);
    my $m    = int(($sec - ($h * 3600)) / 60);
    my $s    = int($sec - ($h*3600) - ($m*60));

    return sprintf("%d:%d:%d", $h, $m, $s);
}

sub update{
    my $self  = shift;
    my $pbar  = shift;
    return sprintf($self->format_string, $self->format_time($pbar->seconds_elapsed)); 
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar:::Timer - displays elapsed time
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS
 
    use Text::ProgressBar::Timer;

    my $bar = Text::ProgressBar->new(widgets => [Text::ProgressBar::Timer->new()]);
    $bar->start();
    for my $i (1..150) {
        sleep 0.1;
        $bar->update($i+1);
    }
    $bar->finish;
    
=head1 DESCRIPTION
 
Widget which displays the elapsed seconds. It is super class of 'ETA'
and 'FormatLabel'. An example of default settings:

    Elapsed Time: 0:0:8                                                                                                    

=head1 ATTRIBUTES
 
=head2 format_string

defines the output string

=head1 METHODS

=head2 update

handler for redrawing current regions within the area. (Inherited from Widget.)

=head2 BUILD

add additional works after object creation

=head2 format_time

format time properly HH:MM:SS

=head1 AUTHOR

Farhad Fouladi, C<< <farhad at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Farhad Fouladi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
