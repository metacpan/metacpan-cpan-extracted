package WWW::Shorten::Flickr;
use strict;
use warnings;
use 5.008_001;
use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );

our $VERSION = '0.03';

use Carp;
use Encode::Base58;

sub makeashorterlink {
    my $uri = shift or croak 'No URL passed to makeashorterlink';

    my $photo_id;
    if (   $uri =~ m!^http://www\.flickr\.com/photos/[\w@-]+/(\d+)!i
        || $uri =~ /^(\d+)$/ )
    {
        $photo_id = $1;
    }
    else {
        return;
    }

    return sprintf( "http://flic.kr/p/%s", encode_base58($photo_id) );
}

sub makealongerlink {
    my $uri = shift or croak 'No URL passed to makealongerlink';

    my $ua = __PACKAGE__->ua();
    push @{ $ua->requests_redirectable }, 'GET';

    $uri = "http://flic.kr/p/$uri" unless $uri =~ m!^http://!i;

    my $res = $ua->get($uri);
    return if $res->redirects() == 0;
    return $res->request->uri;
}

1;
__END__

=head1 NAME

WWW::Shorten::Flickr -  Perl interface to flic.kr

=head1 SYNOPSIS

  use WWW::Shorten::Flickr;
  use WWW::Shorten 'Flickr';

  $short_url = makeashorterlink($long_url);
  $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

WWW::Shorten::Flickr is Perl interface to the flic.kr.

=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will return the shorter Flickr URL Shortener version. C<makeashorterlink> 
will accept as an argument either the full Flickr URL or just the Flickr identifier of the photo.

If anything goes wrong, then either function will return C<undef>.

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full Flickr URL Shortener URL or just the Flickr URL Shortener identifier.

If anything goes wrong, then either function will return C<undef>.

=head1 AUTHOR

Shinsuke Matsui <smatsui@karashi.org>

=head1 SEE ALSO

L<WWW::Shorten>, L<http://flic.kr/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
