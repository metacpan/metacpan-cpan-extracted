package Text::ProgressBar::WidgetHFill;
use Moose::Role; 
our $VERSION = '0.1';

with 'Text::ProgressBar::Widget';

sub update{
    my $self  = shift;
    my $pbar  = shift; # pbar - a reference to the calling ProgressBar
    my $width = shift; # width - The total width the widget must fill
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::Widget - A role for all variable width widgets
 
=head1 VERSION
 
version 0.1
 
=head1 SYNOPSIS
 
    with 'Text::ProgressBar::WidgetHFill';
    
=head1 DESCRIPTION
 
This widget is much like the \\hfill command in TeX, it will expand to
fill the line. You can use more than one in the same line, and they
will all have the same width, and together will fill the line.

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
