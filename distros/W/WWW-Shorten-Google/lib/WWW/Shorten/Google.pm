package WWW::Shorten::Google;
use strict;
use warnings;
use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );

our $VERSION = '0.01';

use Carp;

sub makeashorterlink {
    my $uri = shift or croak 'No URL passed to makeashorterlink';
    my $ua  = __PACKAGE__->ua();
    my $res = $ua->post(
        'http://goo.gl/action/shorten',
        {
            url    => $uri,
            authed => 1,
        }
    );

    return unless $res->is_redirect;
    my($tiny_url) = $res->header('location') =~ /url=(.+)/;
    return $tiny_url;
}

sub makealongerlink {
    my $uri = shift or croak 'No URL passed to makealongerlink';

    my $ua = __PACKAGE__->ua();

    $uri = "http://goo.gl/$uri" unless $uri =~ m!^http://!i;

    my $res = $ua->get($uri);
    return unless $res->is_redirect;
    return $res->header('Location');
}

1;
__END__

=head1 NAME

WWW::Shorten::Google -  Perl interface to goo.gl

=head1 SYNOPSIS

  use WWW::Shorten::Google;
  use WWW::Shorten 'Google';

  $short_url = makeashorterlink($long_url);
  $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

WWW::Shorten::Google is Perl interface to the web api goo.gl.

=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will call the Google URL Shortener web site passing
it your long URL and will return the shorter Google URL Shortener version.

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full Google URL Shortener URL or just the Google URL Shortener identifier.

If anything goes wrong, then either function will return C<undef>.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

sunnavy

=head1 SEE ALSO

L<WWW::Shorten>, L<http://goo.gl/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
