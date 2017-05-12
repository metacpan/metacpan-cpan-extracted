package Test::Mock::Furl::Response;
use strict;
use warnings;
use Test::MockObject;
use parent 'Exporter';
our @EXPORT = qw/$Mock_furl_res $Mock_furl_resp $Mock_furl_response/;

our $Mock_furl_res;
our $Mock_furl_resp;
our $Mock_furl_response;

BEGIN {
    $Mock_furl_response = $Mock_furl_resp = $Mock_furl_res = Test::MockObject->new;
    $Mock_furl_res->fake_module('Furl::Response');
    $Mock_furl_res->fake_new('Furl::Response');
}

our %Headers;

$Mock_furl_res->mock(
    'header' => sub {
        return $Headers{$_[1]};
    },
);
$Mock_furl_res->set_always('code' => 200);
$Mock_furl_res->set_always('content' => '');
$Mock_furl_res->set_always('is_success' => 1);

package # hide from PAUSE
    Furl::Response;

our $VERSION = 'Mocked';

1;

__END__

=head1 NAME

Test::Mock::Furl::Response - Mock Furl::Response


=head1 SYNOPSIS

    use Test::Mock::Furl::Response;


=head1 DESCRIPTION

See L<Test::Mock::Furl> page for more details.


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Test::Mock::Furl>

The code of this module was almost copied from L<Test::Mock::LWP>.


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
