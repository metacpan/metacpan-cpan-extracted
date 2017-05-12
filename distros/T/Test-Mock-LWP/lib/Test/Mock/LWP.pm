package Test::Mock::LWP;
use strict;
use warnings;
use base 'Exporter';
use Test::MockObject;
our @EXPORT = qw($Mock_ua $Mock_req $Mock_request $Mock_resp $Mock_response);

=head1 NAME

Test::Mock::LWP - Easy mocking of LWP packages

=cut

=head1 SYNOPSIS

Make LWP packages to make testing easier.

    use Test::Mock::LWP;

    # Setup fake response content and code
    $Mock_response->mock( content => sub { 'foo' } );
    $Mock_resp->mock( code => sub { 201 } );

    # Validate args passed to request constructor
    is_deeply $Mock_request->new_args, \@expected_args;
    
    # Validate request headers
    is_deeply [ $Mock_req->next_call ],
              [ 'header', [ 'Accept', 'text/plain' ] ];

    # Special User Agent Behaviour
    $Mock_ua->mock( request => sub { die 'foo' } );

=head1 DESCRIPTION

This package arises from duplicating the same code to mock LWP et al in
several different modules I've written.  This version is very minimalist, but
works for my needs so far.  I'm very open to new suggestions and improvements.

=head1 EXPORTS

The following variables are exported by default:

=over 4

=item $Mock_ua

The mock LWP::UserAgent object - a Test::MockObject object

=item $Mock_req, $Mock_request

The mock HTTP::Request object - a Test::MockObject object

=item $Mock_resp, $Mock_response

The mock HTTP::Response object - a Test::MockObject object

=back

=cut

our $VERSION = '0.08';

BEGIN {
    # Don't load the mock classes if the real ones are already loaded
    my $mo = Test::MockObject->new;
    my @mock_classes = (
        [ 'HTTP::Response' => '$Mock_response $Mock_resp' ],
        [ 'HTTP::Request'  => '$Mock_request $Mock_req' ],
        [ 'LWP::UserAgent' => '$Mock_ua' ],
    );
    for my $c (@mock_classes) {
        my ($real, $imports) = @$c;
        if (!$mo->check_class_loaded($real)) {
            my $mock_class = "Test::Mock::$real";
            eval "require $mock_class"; 
            if ($@) {
                warn "error during require $mock_class: $@" if $@;
                next;
            }
            my $import = "$mock_class qw($imports)";
            eval "import $import";
            warn "error during import $import: $@" if $@;
        }
    }
}

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
