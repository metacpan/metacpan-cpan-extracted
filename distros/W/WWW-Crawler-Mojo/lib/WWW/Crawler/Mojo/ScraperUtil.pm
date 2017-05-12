package WWW::Crawler::Mojo::ScraperUtil;
use strict;
use warnings;
use Mojo::Base -base;
use Encode qw(find_encoding);
use Exporter 'import';

our @EXPORT_OK = qw(collect_urls_css html_handler_presets reduce_html_handlers
  guess_encoding encoder decoded_body resolve_href);

my $charset_re = qr{\bcharset\s*=\s*['"]?([a-zA-Z0-9_\-]+)['"]?}i;

sub collect_urls_css {
  map { s/^(['"])// && s/$1$//; $_ } (shift || '') =~ m{url\((.+?)\)}ig;
}

sub decoded_body {
  my $res = shift;
  return encoder(guess_encoding($res))->decode($res->body);
}

sub encoder {
  for (shift || 'utf-8', 'utf-8') {
    if (my $enc = find_encoding($_)) {
      return $enc;
    }
  }
}

sub guess_encoding {
  my $res  = shift;
  my $type = $res->headers->content_type;
  return unless ($type);
  my $charset = ($type =~ $charset_re)[0];
  return $charset                         if ($charset);
  return _guess_encoding_html($res->body) if ($type =~ qr{text/(html|xml)});
  return _guess_encoding_css($res->body)  if ($type =~ qr{text/css});
}

sub html_handler_presets {
  return {
    'script[src]'  => sub { $_[0]->{src} },
    'link[href]'   => sub { $_[0]->{href} },
    'a[href]'      => sub { $_[0]->{href} },
    'img[src]'     => sub { $_[0]->{src} },
    'area'         => sub { $_[0]->{href}, $_[0]->{ping} },
    'embed[src]'   => sub { $_[0]->{src} },
    'frame[src]'   => sub { $_[0]->{src} },
    'iframe[src]'  => sub { $_[0]->{src} },
    'input[src]'   => sub { $_[0]->{src} },
    'object[data]' => sub { $_[0]->{data} },
    'form' => sub {
      my $dom = shift;
      my (%seed, $submit);

      $dom->find("[name],[type='submit'],[type='image']")->each(
        sub {
          my $e = shift;
          $seed{my $name = $e->{name}} ||= [] if $e->{name};

          if ($e->tag eq 'select' && $name) {
            my $found = 0;
            if (exists $e->{multiple}) {
              $e->find('option[selected]')->each(
                sub {
                  push(@{$seed{$name}}, shift->{value});
                  $found++;
                }
              );
            }
            elsif (my $opts = $e->at('option[selected]')) {
              push(@{$seed{$name}}, $opts->{value});
              $found++;
            }
            if (!$found) {
              $e->find('option:nth-child(1)')->each(
                sub {
                  push(@{$seed{$name}}, shift->{value});
                }
              );
            }
          }
          elsif ($e->tag eq 'textarea') {
            push(@{$seed{$name}}, $e->text);
          }

          return unless (my $type = $e->{type});

          if (!$submit && grep { $_ eq $type } qw{submit image}) {
            $submit = 1;
            push(@{$seed{$name}}, $e->{value}) if $name;
          }
          if ($name) {
            if (grep { $_ eq $type } qw{text hidden number}) {
              push(@{$seed{$name}}, $e->{value});
            }
            elsif (grep { $_ eq $type } qw{checkbox}) {
              push(@{$seed{$name}}, $e->{value}) if (exists $e->{checked});
            }
            elsif (grep { $_ eq $type } qw{radio}) {
              push(@{$seed{$name}}, $e->{value}) if (exists $e->{checked});
            }
          }
        }
      );

      return [
        $dom->{action} || '',
        uc($dom->{method} || 'GET'),
        Mojo::Parameters->new(%seed)
      ];
    },
    'meta[content]' => sub {
      return $1
        if ($_[0] =~ qr{http\-equiv="?Refresh"?}i
        && (($_[0]->{content} || '') =~ qr{URL=(.+)}i)[0]);
      return;
    },
    'style' => sub {
      collect_urls_css(shift->content);
    },
    '[style]' => sub {
      collect_urls_css(shift->{style});
    },
    'urlset[xmlns^=http://www.sitemaps.org/schemas/sitemap/]' => sub {
      @{$_->find('url loc')->map(sub { $_->content })->to_array};
    }
  };
}

sub reduce_html_handlers {
  my $handlers = $_[0];
  my $contexts = ref $_[1] ? $_[1] : [$_[1]];
  my $ret;
  for my $sel (keys %$handlers) {
    my $cb = $handlers->{$sel};
    for my $cont (@$contexts) {
      $ret->{($cont ? $cont . ' ' : '') . $sel} = sub {
        return if ($_[0]->xml && _wrong_dom_detection($_[0]));
        return $cb->($_[0]);
        }
    }
  }
  return $ret;
}

sub resolve_href {
  my ($base, $href) = @_;
  $href =~ s{\s}{}g;
  $href = ref $href ? $href : Mojo::URL->new($href);
  $base = ref $base ? $base : Mojo::URL->new($base);
  my $abs        = $href->fragment(undef)->to_abs($base);
  my $path_parts = $abs->path->parts;
  shift @{$path_parts} while (@$path_parts && $path_parts->[0] eq '..');
  return $abs;
}

sub _guess_encoding_css {
  return (shift =~ qr{^\s*\@charset ['"](.+?)['"];}is)[0];
}

sub _guess_encoding_html {
  my $head = (shift =~ qr{<head>(.+)</head>}is)[0] or return;
  my $charset;
  Mojo::DOM->new($head)->find('meta[http\-equiv=Content-Type]')->each(
    sub {
      $charset = (shift->{content} =~ $charset_re)[0];
    }
  );
  return $charset;
}

sub _wrong_dom_detection {
  my $dom = shift;
  while ($dom = $dom->parent) {
    return 1 if ($dom->tag && $dom->tag eq 'script');
  }
  return;
}

use 5.010;

1;

=head1 NAME

WWW::Crawler::Mojo::ScraperUtil - Scraper utitlities

=head1 SYNOPSIS

=head1 DESCRIPTION

This class inherits L<Mojo::UserAgent> and override start method for storing
user info

=head1 ATTRIBUTES

WWW::Crawler::Mojo::ScraperUtil implements following attributes.

=head1 METHODS

WWW::Crawler::Mojo::ScraperUtil implements following methods.

=head2 collect_urls_css

Collects URLs out of CSS.

    @urls = collect_urls_css($dom);

=head2 decoded_body

Returns decoded response body for given L<Mojo::Message::Request> using
guess_encoding and encoder.

=head2 encoder

Generates L<Encode> instance for given name. Defaults to L<Encode::utf8>.

=head2 html_handler_presets

Returns common html handler in hash reference.

    my $handlers = html_handlers();

=head2 reduce_html_handlers

Narrows html handler selectors by prefixing container CSS snippets.

    my $handlers = html_handlers($handlers, ['#header', '#footer li']);
    
    $handlers->{img} = sub {
        my $dom = shift;
        return $dom->{src};
    };
    
    my @urls;
    for my $selector (sort keys %{$handlers}) {
        $dom->find($selector)->each(sub {
            push(@urls, $handlers->{$selector}->(shift));
        })->to_array;
    }

=head2 resolve_href

Resolves URLs with a base URL.

    WWW::Crawler::Mojo::resolve_href($base, $uri);

=head2 guess_encoding

Guesses encoding of HTML or CSS with given L<Mojo::Message::Response> instance.

    $encode = WWW::Crawler::Mojo::guess_encoding($res) || 'utf-8'

=head1 AUTHOR

Keita Sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Keita Sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
