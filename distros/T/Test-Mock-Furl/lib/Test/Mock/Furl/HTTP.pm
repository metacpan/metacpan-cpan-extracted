package Test::Mock::Furl::HTTP;
use strict;
use warnings;
use Test::MockObject;
use parent 'Exporter';
our @EXPORT = qw/$Mock_furl_http/;

our $Mock_furl_http;

BEGIN {
    $Mock_furl_http = Test::MockObject->new;
    $Mock_furl_http->fake_module(
        'Furl::HTTP', 
        new => sub {
            $Mock_furl_http->{new_args} = [@_];
            $Mock_furl_http;
        }
    );
}

#$Mock_furl_http->set_always('request' => '');

sub new {
    $Mock_furl_http;
};

$Mock_furl_http->mock(
    '-new_args' => sub {
        delete $Mock_furl_http->{new_args};
    },
);

package # hide from PAUSE
    Furl::HTTP;

our $VERSION = 'Mocked';

1;

__END__

=head1 NAME

Test::Mock::Furl::HTTP - Mock Furl::HTTP


=head1 SYNOPSIS

    use Test::Mock::Furl::HTTP;


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
