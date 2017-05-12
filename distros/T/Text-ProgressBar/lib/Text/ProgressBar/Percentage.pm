package Text::ProgressBar::Percentage;
use Moose; 
our $VERSION = '0.2';
use Text::ProgressBar;

with 'Text::ProgressBar::Widget';

sub update{
    my $self  = shift;
    my $pbar  = shift;
    return sprintf '%3d%%', $pbar->percentage();
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::Percentage - displays percentage as a number with a
percent sign
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS

    use Text::ProgressBar::Percentage;

    my $prevbar = Text::ProgressBar->new(maxval => 300, widgets  => [Text::ProgressBar::Percentage->new()]);
    $prevbar->start();
    for my $i (1..300) {
        sleep 0.01;
        $prevbar->update($i+1);
    }
    $prevbar->finish;
    
=head1 DESCRIPTION
 
Displays the current percentage as a number with a percent sign

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
