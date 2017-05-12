package Text::ProgressBar::FormatLabel;
use Moose; 
our $VERSION = '0.2';
use Text::ProgressBar;

extends 'Text::ProgressBar::Timer';

sub update{
    my $self                   = shift;
    my $pbar                   = shift;

    my %mapping                = ();
    $mapping{seconds_elapsed}  = $pbar->seconds_elapsed;
    $mapping{finished}         = $pbar->finished;
    $mapping{last_update_time} = $pbar->last_update_time;
    $mapping{maxval}           = $pbar->maxval;
    $mapping{currval}          = $pbar->currval;
    my $str = $self->format_string;
    for ( keys %mapping ) {
        $str =~ s/$_/$mapping{$_}/g;
    }
    return $str;
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::FormatLabel - displays a formated label
 
=head1 VERSION
 
version 0.2
 
=head1 SYNOPSIS

    use Text::ProgressBar::FormatLabel;

    my $bar = Text::ProgressBar->new(widgets => [Text::ProgressBar::FormatLabel->new(format_string => 'Processed: currval lines (in: seconds_elapsed seconds)')]);
    $bar->start();
    for my $i (1..100) {
        sleep 0.2;
        $bar->update($i+1);
    }
    $bar->finish;
    
=head1 DESCRIPTION
 
Displays a formatted label. It inherites attribute of 'Timer'. Output of
above example:

    Processed: 19 lines (in: 3 seconds)                                                                                    

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
