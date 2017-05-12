package Text::ProgressBar::Counter;
use Moose; 
our $VERSION = '0.2';
use Text::ProgressBar;

with 'Text::ProgressBar::Widget';

has 'format_string' => (is => 'rw', isa => 'Str', default  => "%d");

sub update{
    my $self  = shift;
    my $pbar  = shift;
    return sprintf($self->format_string, $pbar->currval);
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::Counter - displays the current count
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS

    use Text::ProgressBar::Counter;

    my $bar = Text::ProgressBar->new(maxval => 17, widgets  => [Text::ProgressBar::Counter->new()]);
    $bar->start();
    for my $i (1..17) {
        sleep 0.2;
        $bar->update($i+1);
    }
    $bar->finish;

=head1 DESCRIPTION
 
Displays the current count. It runs from 1 to max number successively.

=head1 ATTRIBUTES
 
=head2 format_string

format of output string

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
