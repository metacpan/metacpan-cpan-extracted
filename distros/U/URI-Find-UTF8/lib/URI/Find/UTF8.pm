package URI::Find::UTF8;

use strict;
use 5.8.1;
our $VERSION = '0.05';

use base qw( URI::Find );
use URI::Escape;

sub uri_re {
    @_ == 1 || __PACKAGE__->badinvo;
    my $self = shift;
    my $x = sprintf '%s:/{0,2}[%s]+/[%s]*|%s',
        $URI::scheme_re,
        'A-Za-z0-9\-\.',         # Domain part ... don't care about IDN yet
        $self->uric_set . '\w#', # \w will have all 'word' characters in UTF8 semantics
        $self->SUPER::uri_re;    # Make this less priority
    return $x;
}

sub _is_uri {
    @_ == 2 || __PACKAGE__->badinvo;

    # crufty: URI escape $$r_uri_cand so we get encoded URI.
    my($self, $r_uri_cand) = @_;
    my $uri_cand = $$r_uri_cand;

    my $uric_set = $self->uric_set;
    $uri_cand =~ s{ ([^$uric_set/<>#]+) }{ URI::Escape::uri_escape_utf8($1) }xeg;

    return $self->SUPER::_is_uri(\$uri_cand);
}

1;
__END__

=encoding utf-8

=for stopwords URI UTF8 UTF-8 UTF IM IRC URL URLs unencoded

=head1 NAME

URI::Find::UTF8 - Finds URI from arbitrary text containing UTF8 raw characters in its path

=head1 SYNOPSIS

  use utf8;
  use URI::Find::UTF8;

  # Since this code has "use utf8", $text is UTF-8 flagged
  my $text = <<TEXT;
  Japanese Wikipedia home page is http://ja.wikipedia.org/wiki/メインページ
  TEXT

  my $finder = URI::Find::UTF8->new(\&callback);
  $finder->find(\$text);

  sub callback {
      my($uri, $orig) = @_;

      # $uri is an URI object that represents
      #   "http://ja.wikipedia.org/wiki/%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8"
      # $orig is a string
      #   "http://ja.wikipedia.org/wiki/メインページ"
  }

=head1 DESCRIPTION

URI::Find::UTF8 is an URI::Find extension to find URIs from arbitrary
chunk of text that has UTF8 raw characters in its path (instead of URI
escaped I<%XX%XX%XX> form).

This often happens when Safari users paste an URL to IM or IRC window,
because Safari displays decoded URL path in its location bar, such as:

  http://ja.wikipedia.org/wiki/メインページ

This module tries to extract URLs like this (in addition to normal
URLs that URI::Find can find) and give you an encoded URL (URI object)
and the raw, unencoded string.

This module passes URI::Find's own test file (besides the old
C<find_uris> call), so this can be used as a drop-in replacement for
the module.

Note that this module doesn't (yet) handle International Domain Names.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

I<URI::Find>

=cut
