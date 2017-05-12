package Test::WWW::Mechanize::CGI;

use strict;
use warnings;
use base qw[WWW::Mechanize::CGI Test::WWW::Mechanize];

our $VERSION = 0.1;

1;

__END__

=head1 NAME

Test::WWW::Mechanize::CGI - Test CGI applications with Test::WWW::Mechanize

=head1 SYNOPSIS

    use Test::More tests => 3;

    use CGI;
    use Test::WWW::Mechanize::CGI;

    my $mech = Test::WWW::Mechanize::CGI->new;
    $mech->cgi( sub {

        my $q = CGI->new;

        print $q->header,
              $q->start_html('Hello World'),
              $q->h1('Hello World'),
              $q->end_html;
    });

    $mech->get_ok('http://localhost/');
    $mech->title_is('Hello World');
    $mech->content_contains('Hello World');

=head1 DESCRIPTION

Provides a convenient way of testing CGI applications without a external daemon.

=head1 SEE ALSO

=over 4

=item L<WWW::Mechanize::CGI>

=item L<WWW::Mechanize>

=item L<LWP::UserAgent>

=item L<HTTP::Request::AsCGI>

=back

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut
