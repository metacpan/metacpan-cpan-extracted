package Test::Mock::Furl;
use strict;
use warnings;
use Test::MockObject;
use parent 'Exporter';
our @EXPORT = qw/
    $Mock_furl
    $Mock_furl_http
    $Mock_furl_req $Mock_furl_request
    $Mock_furl_res $Mock_furl_resp $Mock_furl_response
/;

our $VERSION = '0.05';

BEGIN {
    # Don't load the mock classes if the real ones are already loaded
    my $mo = Test::MockObject->new;
    my @mock_classes = (
        [ 'Furl'     => '$Mock_furl' ],
        [ 'HTTP'     => '$Mock_furl_http' ],
        [ 'Request'  => '$Mock_furl_request $Mock_furl_req' ],
        [ 'Response' => '$Mock_furl_response $Mock_furl_resp $Mock_furl_res' ],
    );
    for my $c (@mock_classes) {
        my ($real, $imports) = @$c;
        if (!$mo->check_class_loaded($real)) {
            my $mock_class = "Test::Mock::Furl::$real";
            eval "require $mock_class"; ## no critic
            if ($@) {
                warn "error during require $mock_class: $@" if $@;
                next;
            }
            my $import = "$mock_class qw($imports)";
            eval "import $import"; ## no critic
            warn "error during import $import: $@" if $@;
        }
    }
}

1;

__END__

=head1 NAME

Test::Mock::Furl - Mocks Furl for testing


=head1 SYNOPSIS

The test of mocked Furl.

    use Test::More;
    use Test::Mock::Furl;
    use Furl;
    use Furl::Request;

    $Mock_furl->mock(request => sub { Furl::Response->new } );
    $Mock_furl_res->mock(message => sub { 'ok ok ok' } );

    my $req  = Furl::Request->new('GET' => 'http://example.com/');
    my $furl = Furl->new;
    my $res  = $furl->request($req);

    ok $res->is_success;
    is $res->code, 200;
    is $res->content, '';
    is $res->message, 'ok ok ok';

    done_testing;

And mock test of Furl::HTTP is like below.

    use Test::More;
    use Test::Mock::Furl;

    use Furl::HTTP;

    $Mock_furl_http->mock(
        request => sub {
            ( 1, 200, 'OK', ['content-type' => 'text/plain'], 'mock me baby!' );
        },
    );

    my $furl = Furl::HTTP->new;
    my @res  = $furl->request(
        method => 'GET', host => 'example.com', port => 80, path => '/',
    );

    is $res[4], 'mock me baby!';

    done_testing;


=head1 DESCRIPTION

C<Test::Mock::Furl> is the mock module for teting L<Furl>

=head2 EXPORTS

The following variables are exported by default:

=over 4

=item $Mock_furl

The mock L<Furl> object - a Test::MockObject object

=item $Mock_furl_http

The mock L<Furl::HTTP> object - a Test::MockObject object

=item $Mock_furl_req, $Mock_furl_request

The mock L<Furl::Request> object - a Test::MockObject object

=item $Mock_furl_res, $Mock_furl_response

The mock L<Furl::Response> object - a Test::MockObject object

=back

=cut


=head1 REPOSITORY

Test::Mock::Furl is hosted on github
<http://github.com/bayashi/Test-Mock-Furl>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Test::MockObject>

L<Furl>

The code of this module was almost copied from L<Test::Mock::LWP>.


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
