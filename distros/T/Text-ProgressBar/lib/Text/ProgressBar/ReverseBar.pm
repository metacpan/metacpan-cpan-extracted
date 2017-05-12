package Text::ProgressBar::ReverseBar;
use Moose; 
our $VERSION = '0.2';
use Text::ProgressBar;

extends 'Text::ProgressBar::Bar';

sub BUILD {
    my $self = shift;
    $self->fill_left(0);
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::ReverseBar - progress bar which stretches to fill the
line in reverse order
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS

    use Text::ProgressBar::ReverseBar;

    my $prevbar = Text::ProgressBar->new(maxval => 300, widgets  => [Text::ProgressBar::Percentage->new(), Text::ProgressBar::ReverseBar->new()]);
    $prevbar->start();
    for my $i (1..300) {
        sleep 0.01;
        $prevbar->update($i+1);
    }
    $prevbar->finish;
    
=head1 DESCRIPTION
 
A progress bar which stretches to fill the line but from right to left.
It inherits all attributes of 'Bar' and can extend them.

The drawing ascii characters can be changed during calling class
constructor or by calling the corresponding methods. Example of
defalut output

    |          #######|

=head1 METHODS

=head2 BUILD

add additional works after object creation

=head1 AUTHOR

Farhad Fouladi, C<< <farhad at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Farhad Fouladi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
