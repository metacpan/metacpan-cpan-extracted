package # hide from PAUSE
        warnings;
use strict;
use Carp;

{   no strict;
    $VERSION = '0.07';
}

=head1 NAME

warnings - warnings.pm emulation for pre-5.6 Perls

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    # enable warnings
    use warnings;

    # disable warnings
    no warnings;


=head1 DESCRIPTION

This module is a very simple C<warnings.pm> emulation for Perls before 5.6.
Its aim is to allow programs that use this pragma to compile and run under 
old Perls by providing an API emulation, i.e. the functions work the same, 
but will not behave exactly like the real module.  Under the hood, this 
module simply uses C<$^W>. 

Shortcomings: 

=over

=item *

this is a module, not a pragma; therefore it isn't lexical;

=item *

categories are "supported" but won't be used;

=item *

probably other things..

=back

See the documentation of the real C<warnings> module for more information: 
L<http://perldoc.perl.org/warnings.html>

=cut

sub import   { $^W = 1; }

sub unimport { $^W = 0; }


=head1 FUNCTIONS

=over

=item C<warnings::enabled()>

Returns true if the warnings are enabled, false otherwise.

=cut

sub enabled { ! ! $^W }

=item C<warnings::warn()>

Prints the message to C<STDERR>.

=cut

sub warn {
    Carp::croak("Usage: warnings::warn([category,] 'message')")
        unless @_ == 2 || @_ == 1;
    my $message = pop;
    Carp::carp($message);
}

=item C<warnings::warnif()>

Prints the message to C<STDERR> if warnings are enabled.

=cut

sub warnif {
    Carp::croak("Usage: warnings::warnif([category,] 'message')")
        unless @_ == 2 || @_ == 1;
    return unless $^W;
    my $message = pop;
    Carp::carp($message);
}

=back

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-warnings-compat at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=warnings-compat>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc warnings

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/warnings-compat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/warnings-compat>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=warnings-compat>

=item * Search CPAN

L<http://search.cpan.org/dist/warnings-compat>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2006, 2007, 2008 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of warnings
