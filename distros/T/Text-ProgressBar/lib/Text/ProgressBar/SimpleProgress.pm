package Text::ProgressBar::SimpleProgress;
use Moose; 
our $VERSION = '0.2';
use Text::ProgressBar;

with 'Text::ProgressBar::Widget';

has 'sep' => (is => 'rw', isa => 'Str', default => ' of ');

sub update{
    my $self  = shift;
    my $pbar  = shift;
    return sprintf("%d%s%d", $pbar->currval, $self->sep, $pbar->maxval);
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::SimpleProgress - displays count of the total
done jobs
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS

    use Text::ProgressBar::SimpleProgress;

    my $psimplebar = Text::ProgressBar->new(maxval => 17, widgets  => [Text::ProgressBar::SimpleProgress->new()]);
    $psimplebar->start();
    for my $i (1..17) {
        sleep 0.2;
        $psimplebar->update($i+1);
    }
    $psimplebar->finish;
    
=head1 DESCRIPTION
 
Returns progress as a count of the total (e.g.: "5 of 47")

=head1 ATTRIBUTES
 
=head2 sep

defines the seperation string

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
