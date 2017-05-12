package WWW::BookBot::FakeCookies;

use 5.008;
use strict;
use warnings;
use base qw(HTTP::Cookies);
use vars qw($VERSION);
$VERSION = '1.02';

sub add_cookie_header {
	my $self = shift;
    my $request = shift || return;
    my $url = $request->url;
    eval {$url->port;};
    return if $@;
    $self->SUPER::add_cookie_header($request);
}

sub extract_cookies
{
    my $self = shift;
    my $response = shift || return;
    my $request = $response->request;
    my $url = $request->url;
    eval {$url->port;};
    return if $@;
    $self->SUPER::extract_cookies($response);
}

1;
__END__

=head1 NAME

WWW::BookBot::FakeCookies - Fake HTTP::Cookies to skip local file access.

=head1 SYNOPSIS

  use WWW::BookBot::FakeCookies;

=head1 ABSTRACT

  Fake HTTP::Cookies to skip local file access.

=head1 DESCRIPTION

HTTP::Cookies will die when fetching local files with LWP. The reason is
that HTTP::Cookies want to access $url->port which does not exist.

WWW::BookBot::FakeCookies check $url->port before call HTTP::Cookies. If
$url->port is unavailable, WWW::BookBot::FakeCookies will return without
calling HTTP::Cookies.

=head2 EXPORT

None by default.

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-BookBot

=head1 AUTHOR

Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

=head1 SEE ALSO

L<WWW::BookBot>

=cut
