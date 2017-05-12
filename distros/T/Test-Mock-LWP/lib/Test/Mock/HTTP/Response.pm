package Test::Mock::HTTP::Response;
use strict;
use warnings;
use Test::MockObject;
use base 'Exporter';
our @EXPORT = qw($Mock_resp $Mock_response);

our $Mock_resp;
our $Mock_response;

=head1 NAME

Test::Mock::HTTP::Response - Mocks HTTP::Response

=cut

=head1 SYNOPSIS

Make HTTP::Response to make testing easier.

See Test::Mock::LWP manpage for more details.

This class uses Test::MockObject, so refer to it's documentation as well.

=cut

our $VERSION = '0.01';

BEGIN {
    $Mock_response = $Mock_resp = Test::MockObject->new;
    $Mock_resp->fake_module('HTTP::Response');                       
    $Mock_resp->fake_new('HTTP::Response');
}                                                                          

our %Headers;
$Mock_resp->mock('header', sub { return $Headers{$_[1]} });
$Mock_resp->set_always('code', 200);
$Mock_resp->set_always('content', '');
$Mock_resp->set_always('is_success', 1);

package # hide from PAUSE
    HTTP::Response;

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
