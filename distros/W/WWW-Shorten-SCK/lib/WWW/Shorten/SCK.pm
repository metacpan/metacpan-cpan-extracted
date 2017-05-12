#
# This file is part of WWW-Shorten-SCK
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package WWW::Shorten::SCK;
use strict;
use warnings;
use URI::Escape qw/uri_escape_utf8/;
use JSON;
our $VERSION = '0.5';    # VERSION

# ABSTRACT: Perl interface to sck.pm

use 5.006;

use parent qw( WWW::Shorten::generic Exporter );
use vars qw(@EXPORT_OK %EXPORT_TAGS);
@EXPORT_OK = qw( makeashorterlink makealongerlink );
%EXPORT_TAGS = ( all => [@EXPORT_OK] );

use Carp;

sub makeashorterlink {
    my $url     = shift or croak 'No URL passed to makeashorterlink';
    my $ua      = __PACKAGE__->ua();
    my $sck_url = 'http://api.sck.pm';
    my $resp    = $ua->get( $sck_url . '?url=' . uri_escape_utf8($url), );
    return unless $resp->is_success;
    my $content = decode_json( $resp->content );
    if ( ref $content && $content->{status} eq 'OK' ) {
        return 'http://sck.pm/' . $content->{short};
    }
    return;
}

sub makealongerlink {
    my $sck_url = shift
        or croak 'No SCK key / URL passed to makealongerlink';
    my $ua = __PACKAGE__->ua();

    #call api to get long url from the short
    $sck_url = substr( $sck_url, 14 )
        if substr( $sck_url, 0, 14 ) eq 'http://sck.pm/';

    my $resp = $ua->get("http://api.sck.pm?surl=$sck_url");
    return unless $resp->is_success;
    my $content = decode_json( $resp->content );
    if ( ref $content && $content->{status} eq 'OK' ) {
        return $content->{url};
    }
    return;

}

1;

__END__

=pod

=head1 NAME

WWW::Shorten::SCK - Perl interface to sck.pm

=head1 VERSION

version 0.5

=head1 DESCRIPTION

A Perl interface to the web sck.pm. SCK keep a database of long URLs,
and give you a tiny one.

=head1 SYNOPSIS

    use WWW::Shorten 'SCK';

    my $long_url = "a long url";
    my $short_url = "";
    $short_url = makeashorterlink($long_url);
    $long_url = makealongerlink($short_url);

=head1 METHODS

=head2 makeashorterlink

The function C<makeashorterlink> will call the SCK web site passing
it your long URL and will return the shorter SCK version.

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full SCK URL or just the
SCK identifier.

If anything goes wrong, then either function will return nothing.

=head1 SUPPORT, LICENSE, THANKS and SUCH

See the main L<WWW::Shorten> docs.

=head1 SEE ALSO

L<WWW::Shorten>, L<perl>, L<http://sck.pm/>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/WWW-Shorten-SCK/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
