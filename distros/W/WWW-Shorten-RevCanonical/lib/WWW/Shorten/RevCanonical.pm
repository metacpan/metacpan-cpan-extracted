package WWW::Shorten::RevCanonical;

use strict;
use 5.008_001;
our $VERSION = '0.03';

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );

use Carp;
use LWP::UserAgent;

sub _ua {
    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    $ua;
}

sub makeashorterlink {
    my $url = shift or croak "URL is required";

    my $res  = _ua->get($url);
    my @links = grep /^<.*?>;.*\brev="canonical"/, $res->header('Link');
    if (@links) {
        return ($links[0] =~ /^<(.*?)>/)[0];
    }

    return;
}

sub makealongerlink {
    my $tiny_url = shift or croak "URL is required";

    my $res = _ua->get($tiny_url);
    return unless $res->redirects;

    return $res->request->uri;
}

1;
__END__

=encoding utf-8

=for stopwords TinyURL

=for test_synopsis
my $long_url;

=head1 NAME

WWW::Shorten::RevCanonical - Shorten URL using rev="canonical"

=head1 SYNOPSIS

  use WWW::Shorten 'RevCanonical';

  my $short_url = makeashorterlink($long_url); # Note that this could fail and return undef

  # Or, use WWW::Shorten::Simple wrapper
  use WWW::Shorten::Simple;

  my @shorteners = (
      WWW::Shorten::Simple->new('RevCanonical'), # Try this first
      WWW::Shorten::Simple->new('TinyURL'),      # Then fallback to TinyURL
  );

  my $short_url;
  for my $shortener (@shorteners) {
      $short_url = $shortener->shorten($long_url)
          and last;
  }

=head1 DESCRIPTION

WWW::Shorten::RevCanonical is a WWW::Shorten plugin to extract
rev="canonical" link from HTML web pages. Unlike other URL shortening
services, the ability to make a short URL from rev="canonical" depends
on whether the target site implements the tag, so the call to
C<makeashorterlink> could fail, and in that case you'll get I<undef>
result. You might want to fallback to other shorten services like
I<TinyURL>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::Shorten>, L<WWW::Shoten::Simple>, L<http://revcanonical.wordpress.com/>

=cut
