package Text::ProgressBar::Widget;
use Moose::Role; 
our $VERSION = '0.1';

has 'TIME_SENSITIVE' => (is => 'rw', isa => 'Bool', default => 0);

sub update{
    my $self = shift;
    my $pbar = shift; # pbar - a reference to the calling ProgressBar
}

no Moose;
1;
__END__

=pod
 
=head1 NAME
 
Text::ProgressBar::Widget - A role that defines anything that is a widget
 
=head1 VERSION
 
version 0.1
 
=head1 SYNOPSIS
 
    with 'Text::ProgressBar::Widget';
    
=head1 DESCRIPTION
 
This is the role or the abstract base class for all widgets.

=head1 ATTRIBUTES
 
=head2 TIME_SENSITIVE 

informs the ProgressBar that it should be updated

=head1 METHODS

=head2 update

main method, it will be overwrite from concrete classes

=head1 AUTHOR

Farhad Fouladi, C<< <farhad at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Farhad Fouladi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
