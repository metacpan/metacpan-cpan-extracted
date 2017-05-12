package Text::ProgressBar::FileTransferSpeed;
use Moose;
our $VERSION = '0.2';
use Text::ProgressBar;

with 'Text::ProgressBar::Widget';

our $FORMAT   = "%6.2f %s%s/s";
our $PREFIXES = " kMGTPEZY";
has 'unit'    => (is => 'rw', isa => 'Str', default => 'B');

sub update{
    my $self  = shift;
    my $pbar  = shift;

    my ($scaled, $power) = (0,0);
    if ($pbar->seconds_elapsed > 0 and $pbar->currval > 0 ) {
        my $speed = $pbar->currval / $pbar->seconds_elapsed;
        $power    = int(log($speed) / log(1000));
        $scaled   = $speed / 1000.**$power;
    }
    return sprintf($FORMAT, $scaled, substr($PREFIXES, $power, 1), $self->unit); 
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::FileTransferSpeed - showing the transfer speed as a
simple string
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS

    use Text::ProgressBar::FileTransferSpeed;

    my $bar = Text::ProgressBar->new(maxval=>10000000, widgets => [Text::ProgressBar::FileTransferSpeed->new()]);
    $bar->start();
    for my $i (1..10000) {
        $bar->update($i+1);
    }
    $bar->finish;

=head1 DESCRIPTION
 
Widget for showing the transfer speed (useful for file transfers).
Example of default output:

      5.00 MB/s 

=head1 ATTRIBUTES
 
=head2 unit

transfer speed unit is given, default 'B' - for Baud

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
