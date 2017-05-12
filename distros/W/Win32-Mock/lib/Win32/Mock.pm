package Win32::Mock;
use strict;
use warnings;
use File::Basename;
use Devel::FakeOSName "Win32/\u$^O";

{
    no strict "vars";
    $VERSION = '0.05';
    unshift @INC, dirname($INC{"Win32/Mock.pm"}) . "/Mock";
}

1

__END__

=head1 NAME

Win32::Mock - Mock Win32 modules

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Win32::Mock;
    use Win32;      # this now always works, using the mocked module


=head1 DESCRIPTION

C<Win32::Mock> provides mocked version of Win32 modules and functions so 
programs and modules with Win32 specific code can be tested on any operating 
system. 


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-win32-mock at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Win32-Mock>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::Mock

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-Mock>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-Mock>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-Mock>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-Mock>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

