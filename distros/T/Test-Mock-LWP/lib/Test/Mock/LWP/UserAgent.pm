package Test::Mock::LWP::UserAgent;
use strict;
use warnings;
use Test::MockObject;
use Test::Mock::HTTP::Response;
use Test::Mock::HTTP::Request;
use base 'Exporter';
our @EXPORT = qw($Mock_ua);

our $Mock_ua;

=head1 NAME

Test::Mock::LWP::UserAgent - Mocks LWP::UserAgent

=cut

=head1 SYNOPSIS

Make LWP::UserAgent to make testing easier.

See Test::Mock::LWP manpage for more details.

This class uses Test::MockObject, so refer to it's documentation as well.

=cut

our $VERSION = '0.01';

BEGIN {
    $Mock_ua = Test::MockObject->new;
    $Mock_ua->fake_module('LWP::UserAgent');                       
    $Mock_ua->fake_new('LWP::UserAgent');
}                                                                          

$Mock_ua->set_always('simple_request', HTTP::Response->new);
$Mock_ua->set_always('request', HTTP::Response->new);

package # hide from PAUSE
    LWP::UserAgent;
use strict;
use warnings;

our $VERSION = 'Mocked';

=head1 AUTHOR

Luke Closs, C<< <test-mock-lwp at 5thplane.com> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mock-LWP>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Mock::LWP

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Mock-LWP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Mock-LWP>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Mock-LWP>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Mock-LWP>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
