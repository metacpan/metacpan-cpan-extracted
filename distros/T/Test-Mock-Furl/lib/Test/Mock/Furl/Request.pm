package Test::Mock::Furl::Request;
use strict;
use warnings;
use Test::MockObject;
use parent 'Exporter';
our @EXPORT = qw/$Mock_furl_req $Mock_furl_request/;

our $Mock_furl_req;
our $Mock_furl_request;

BEGIN {
    $Mock_furl_request = $Mock_furl_req = Test::MockObject->new;
    $Mock_furl_req->fake_module(
        'Furl::Request', 
        new => sub {
            $Mock_furl_req->{new_args} = [@_];
            $Mock_furl_req;
        }
    );
}

$Mock_furl_req->set_always('authorization_basic' => '');
$Mock_furl_req->set_always('header' => '');
$Mock_furl_req->set_always('content' => '');

sub new {
    $Mock_furl_req;
};

$Mock_furl_req->mock(
    '-new_args' => sub {
        delete $Mock_furl_req->{new_args};
    },
);

package # hide from PAUSE
    Furl::Request;

our $VERSION = 'Mocked';

1;

__END__

=head1 NAME

Test::Mock::Furl::Request - Mock Furl::Request


=head1 SYNOPSIS

    use Test::Mock::Furl::Request;


=head1 DESCRIPTION

See L<Test::Mock::Furl> page for more details.


=head1 METHODS

=head2 new


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Test::Mock::Furl>

The code of this module was almost copied from L<Test::Mock::LWP>.


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
