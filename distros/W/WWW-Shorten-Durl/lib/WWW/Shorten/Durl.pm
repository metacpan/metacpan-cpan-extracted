package WWW::Shorten::Durl;

use 5.006;
use strict;
use warnings;
use Carp;

use base qw(WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );
our $VERSION = '0.05';

sub makeashorterlink ($) {
  my $url = shift or croak 'No URL passed to makeashorterlink';
  my $ua = __PACKAGE__->ua();
  my $durl = "http://durl.me/api/Create.do?longurl=$url";
  my $res = $ua->get($durl);
  return undef unless $res->is_success;
  my ($short_url) = $res->content =~ m!\[(http://durl.me/\w+)\]!;
  return $short_url;  
}

sub makealongerlink ($) {
  my $url = shift or croak 'No URL passed to makealongerlink';
  my ($key) = $url =~ m!http://durl.me/(\w+)!;
  my $durl = "http://durl.me/$key.status";
  my $ua = __PACKAGE__->ua();
  my $res = $ua->get($durl);
  return undef unless $res->is_success;
  my ($long_url) = $res->content =~ m/<url><\!\[CDATA\[([^<]+)\]\]><\/url>/;
  return $long_url;
}

sub get_image ($) {
  my $url = shift or croak 'No URL passed to get_image';

  unless ($url =~ m/http%3A%2F%2Fdurl.me%2F/) {
      $url = makeashorterlink($url);
  }
  
  my ($key) = $url =~ m!http://durl.me/(\w+)!;
  return undef unless $key;
  
  my $ua = __PACKAGE__->ua();
  my $res = $ua->get("http://durl.me/$key.status");
  return undef unless $res->is_success;
  
  my ($image_url) = $res->content =~ m/<image-url-big><\!\[CDATA\[([^<]+)\]\]><\/image-url-big>/;
  return $image_url;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Shorten::Durl - Perl interface to durl.me

=head1 SYNOPSIS

  use WWW::Shorten::Durl;
  use WWW::Shorten 'Durl';
    
  $short_url = makeashorterlink($long_url);
  
  $long_url = makealongerlink($short_url);

  $image_url = WWW::Shorten::Durl::get_image($short_url);
  $image_url = WWW::Shorten::Durl::get_image($long_url);

=head1 DESCRIPTION

WWW::Shorten::Durl is a Perl interface to the web site durl.me, Durl maintains a database of long URLs, each of which has a unique identifier.

=head1 AUTHOR

JEEN Lee E<lt>aiatejin@gmail.comE<gt>

=head1 SEE ALSO

L<WWW::Shorten>, L<http://durl.kr/doc/OpenAPI.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
