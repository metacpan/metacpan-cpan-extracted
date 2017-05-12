package # hide from PAUSE
        warnings::register;
use strict;
use warnings;

{   no strict;
    $VERSION = '0.07';
}

"this is the end of the module"

__END__

=head1 NAME

warnings::register - warnings.pm emulation for pre-5.6 Perls

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    use warnings::register;


=head1 DESCRIPTION

Create a warnings category with the same name as the current package.
See L<warnings> for more information.


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

    perldoc warnings::register

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

