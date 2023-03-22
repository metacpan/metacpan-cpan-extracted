package URL::Search;
use strict;
use warnings;
use v5.10.0;  # recursive regex subgroups

use Exporter 5.57 qw(import);

our $VERSION = '0.06';

our @EXPORT_OK = qw(
    $URL_SEARCH_RE
    extract_urls
    partition_urls
);

our $URL_SEARCH_RE = do {
    my $general_unicode = qr{
        [^\p{ASCII}\p{Control}\p{Space}\p{Punct}]
    |
        [\x{2010}\x{2011}\x{2012}\x{2013}\x{2014}\x{2015}]
        # HYPHEN, NON-BREAKING HYPHEN,
        # FIGURE DASH, EN DASH, EM DASH, HORIZONTAL BAR
    }xms;

    my $protocol = qr{
        [Hh][Tt][Tt][Pp] [Ss]?
    }xms;

    my $unreserved_subdelims_colon = qr{
        [a-zA-Z0-9\-._~!\$&'()*+,;=:]
    }xms;

    my $pct_enc = qr{ % [[:xdigit:]]{2} }xms;

    my $userinfo = qr{
        $unreserved_subdelims_colon*
        (?: $pct_enc $unreserved_subdelims_colon* )*
    }xms;

    my $host = do {
        my $dec_octet = qr{
            25[0-5]
        |
            2[0-4][0-9]
        |
            1[0-9][0-9]
        |
            [1-9][0-9]
        |
            [0-9]
        }xms;

        my $ipv4_addr = qr{
            $dec_octet (?: \. $dec_octet ){3}
        }xms;

        my $h16 = qr{ [[:xdigit:]]{1,4} }xms;
        my $ls32 = qr{ $h16 : $h16 | $ipv4_addr }xms;

        my $ipv6_addr = qr{
                                             (?: $h16 : ){6} $ls32
        |
                                          :: (?: $h16 : ){5} $ls32
        |
            (?: $h16                   )? :: (?: $h16 : ){4} $ls32
        |
            (?: $h16 (?: : $h16 ){0,1} )? :: (?: $h16 : ){3} $ls32
        |
            (?: $h16 (?: : $h16 ){0,2} )? :: (?: $h16 : ){2} $ls32
        |
            (?: $h16 (?: : $h16 ){0,3} )? ::     $h16 :      $ls32
        |
            (?: $h16 (?: : $h16 ){0,4} )? ::                 $ls32
        |
            (?: $h16 (?: : $h16 ){0,5} )? ::                 $h16
        |
            (?: $h16 (?: : $h16 ){0,6} )? ::
        }xms;

        my $ipvfuture = qr{
            v [[:xdigit:]]+ \. $unreserved_subdelims_colon+
        }xms;

        my $ip_literal = qr{
            \[ (?: $ipv6_addr | $ipvfuture ) \]
        }xms;

        my $hostname = do {
            my $alnum = qr{
                [a-zA-Z0-9]
            |
                $general_unicode
            }xms;
            my $label = qr {
                $alnum+ (?: -+ $alnum+ )*
            }xms;
            qr{
                $label (?: \. $label )* \.?
            }xms
        };

        qr{
            $hostname
        |
            $ip_literal
        }xms
    };

    my $path = qr{
        /
        (
            (?:
                [a-zA-Z0-9\-._~!\$&'*+,;=:\@/]
            |
                $pct_enc
            |
                \( (?-1) \)
            |
                $general_unicode
            )*
        )
    }xms;

    my $query = qr{
        (
            (?:
                [a-zA-Z0-9\-._~!\$&'*+,;=:\@/?\\{}]
            |
                $pct_enc
            |
                \( (?-1) \)
            |
                \[ (?-1) \]
            |
                $general_unicode
            )*
        )
    }xms;

    my $fragment = $query;

    qr{
        $protocol ://
        (?: $userinfo \@ )?
        $host (?: : [0-9]+ )?
        $path?
        (?: \? $query )?
        (?: \# $fragment )?

        (?<! [.!?,;:'] )
    }xms
};

sub extract_urls {
    my ($text) = @_;
    my @urls;
    push @urls, $1 while $text =~ /($URL_SEARCH_RE)/g;
    @urls
}

sub partition_urls {
    my ($text) = @_;
    my @parts;
    my $pos_prev = 0;
    while ($text =~ /($URL_SEARCH_RE)/g) {
        push @parts, [TEXT => substr $text, $pos_prev, $-[0] - $pos_prev]
            if $pos_prev < $-[0];
        push @parts, [URL => $1];
        $pos_prev = $+[0];
    }
    push @parts, [TEXT => substr $text, $pos_prev]
        if $pos_prev < length $text;
    @parts
}

'ok'

__END__

=encoding utf8

=for github-markdown [![Coverage Status](https://coveralls.io/repos/github/mauke/URL-Search/badge.svg?branch=main)](https://coveralls.io/github/mauke/URL-Search?branch=main)

=head1 NAME

URL::Search - search for URLs in plain text

=head1 SYNOPSIS

=for highlighter language=perl

  use URL::Search qw( $URL_SEARCH_RE extract_urls partition_urls );

  if ($text =~ /($URL_SEARCH_RE)/) {
      print "the first URL in text was: $1\n";
  }

  my @all_urls = extract_urls $text;

=head1 DESCRIPTION

This module searches plain text for URLs and extracts them. It exports (on
request) the following entities:

=head2 C<$URL_SEARCH_RE>

This variable is the core of this module. It contains a regex that matches a URL.

NOTE: This regex uses capturing groups internally, so if you embed it in a
bigger pattern, the numbering of any following capture groups will be off. If
this is an issue, use named capture groups of the form C<< (?<NAME>...) >>
instead. See L<perlre/Capture groups>.

It only matches URLs with an explicit schema (one of C<http> or C<https>). The
pattern is deliberately not anchored at the beginning, i.e. it will match
C<http://foo> in C<"click herehttp://foo">. If you don't want that, use
C</\b$URL_SEARCH_RE/>.

It tries to exclude artifacts of the surrounding text:

=for highlighter

  Is mayonnaise an instrument? (https://en.wikipedia.org/wiki/Instrument,
  https://en.wikipedia.org/wiki/Mayonnaise_(instrument))

In this example it will match C<https://en.wikipedia.org/wiki/Instrument> and
C<https://en.wikipedia.org/wiki/Mayonnaise_(instrument)>, without the comma
after "Instrument" and the final closing parenthesis.

It understands all common URL elements: username, hostname, port, path, query
string, fragment identifier. The hostname can be an IP address (IPv4 and IPv6
are both supported).

Unicode is supported (e.g. C<http://поддомен.example.com/déjà-vu?utf8=✓> is
matched correctly).

=head2 C<extract_urls>

This function takes a string and returns a list of all contained URLs.

It uses L<C<$URL_SEARCH_RE>|/C<$URL_SEARCH_RE>> to find matches.

Example:

=for highlighter language=perl

  my $text = 'Visit us at http://html5zombo.com. Also, https://archive.org';
  my @urls = extract_urls $text;
  # @urls = ('http://html5zombo.com', 'https://archive.org')

=head2 C<partition_urls>

This function takes a string and splits it up into text and URL segments. It
returns a list of array references, each of which has two elements: The type
(the string C<'TEXT'> or C<'URL'>) and the portion of the input string that was
classified as text or URL, respectively.

Example:

  my $text = 'Visit us at http://html5zombo.com. Also, https://archive.org';
  my @parts = partition_urls $text;
  # @parts = (
  #   [ 'TEXT', 'Visit us at ' ],
  #   [ 'URL', 'http://html5zombo.com' ],
  #   [ 'TEXT', '. Also, ' ],
  #   [ 'URL', 'https://archive.org' ],
  # )

You can reassemble the original string by concatenating the second elements of
the returned arrayrefs, i.e.
C<< join('', map { $_->[1] } partition_urls($text)) eq $text >>.

This function can be useful if you want to render plain text as HTML but
hyperlink all embedded URLs:

  use URL::Search qw(partition_urls);
  use HTML::Entities qw(encode_entities);

  my $text = ...;

  my $html = '';
  for my $part (partition_urls $text) {
      my ($type, $str) = @$part;
      $str = encode_entities $str;
      if ($type eq 'URL') {
          $html .= "<a rel='nofollow' href='$str'>$str</a>";
      } else {
          $html .= $str;
      }
  }
  # result is in $html

=begin :README

=head1 INSTALLATION

To download and install this module, use your favorite CPAN client, e.g.
L<C<cpan>|cpan>:

=for highlighter language=sh

    cpan URL::Search

Or L<C<cpanm>|cpanm>:

    cpanm URL::Search

To do it manually, run the following commands (after downloading and unpacking
the tarball):

    perl Makefile.PL
    make
    make test
    make install

=end :README

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
L<C<perldoc>|perldoc> command.

=for highlighter language=sh

    perldoc URL::Search

You can also look for information at L<https://metacpan.org/pod/URL::Search>.

To see a list of open bugs, visit
L<https://rt.cpan.org/Dist/Display.html?Name=URL-Search>.

To report a new bug, send an email to
C<bug-URL-Search [at] rt.cpan.org>.

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2016, 2017, 2023 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<https://dev.perl.org/licenses/> for more information.
