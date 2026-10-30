# ABSTRACT: sitemap.xml generator


package byterazor::HiD::Sitemap;

use Moose;
with 'HiD::Generator';

use 5.014; # strict, unicode_strings
use utf8;
use autodie;
use warnings   qw/ FATAL utf8 /;
use charnames  qw/ :full           /;

use Path::Tiny;
use DateTime;

use HiD::VirtualPage;

our $VERSION = '0.1';


sub generate {
  my( $self , $site ) = @_;

  return unless $site->config->{sitemap}{generate};

  my $cfg         = $site->config->{sitemap};
  my $destination = $cfg->{destination} // 'sitemap.xml';
  my $lastmod     = $cfg->{lastmod} // 1;
  my $exclude     = $cfg->{exclude};

  my $baseurl = $cfg->{baseurl} // $site->config->{baseurl} // '/';

  $site->WARN(
    "sitemap: baseurl '$baseurl' is not an absolute URL; "
    . "set 'sitemap.baseurl' to the full URL of your site"
  ) unless $baseurl =~ m{^https?://};

  $baseurl =~ s{/+$}{};

  my %seen;
  my @entries;

  for my $object ( @{ $site->pages } , @{ $site->posts } ) {
    my $url = $baseurl . $object->url;

    next if $exclude && grep { $url =~ /$_/ } @$exclude;
    next if $seen{$url}++;

    my $entry = { url => $url };
    $entry->{lastmod} = $self->_lastmod( $object ) if $lastmod;
    push @entries , $entry;
  }

  my $sitemap = HiD::VirtualPage->new({
    output_filename => path( $site->destination , $destination )->stringify ,
    content         => $self->_render( \@entries ),
  });

  $site->add_input( "SITEMAP" => 'page' );
  $site->add_object( $sitemap );

  $site->INFO( sprintf( "* Injected sitemap (%d URLs)" , scalar @entries ) );

  return $sitemap;
}


sub _lastmod {
  my( $self , $object ) = @_;

  if ( $object->can( 'date' ) and $object->date ) {
    return $object->date->clone
      ->set_time_zone( 'UTC' )
      ->strftime( '%Y-%m-%dT%H:%M:%SZ' );
  }

  my $file = path( $object->input_filename )
    if $object->can( 'input_filename' ) and $object->input_filename;

  return unless $file && $file->is_file;

  return DateTime->from_epoch( epoch => $file->stat->mtime , time_zone => 'UTC' )
    ->strftime( '%Y-%m-%dT%H:%M:%SZ' );
}


sub _render {
  my( $self , $entries ) = @_;

  my $xml = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
    . qq{<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n};

  for my $entry ( @$entries ) {
    $xml .= "  <url>\n"
      . "    <loc>" . _xml_escape( $entry->{url} ) . "</loc>\n";
    $xml .= "    <lastmod>" . $entry->{lastmod} . "</lastmod>\n"
      if $entry->{lastmod};
    $xml .= "  </url>\n";
  }

  $xml .= "</urlset>\n";

  return $xml;
}

sub _xml_escape {
  my( $text ) = @_;
  $text =~ s/&/&amp;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/>/&gt;/g;
  return $text;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

byterazor::HiD::Sitemap - sitemap.xml generator

=head1 VERSION

version 0.1

=head1 DESCRIPTION

This Generator produces a C<sitemap.xml> for your site, containing all
published pages and posts.

Enable it by adding C<+byterazor::HiD::Sitemap> to the C<plugins> key in
your config. The C<+> prefix tells HiD to use the full class name rather
than looking in the C<HiD::Generator::> namespace:

    plugins:
      - '+byterazor::HiD::Sitemap'
    sitemap:
      generate: 1

You may set the following additional C<sitemap.*> config keys:

=over 4

=item C<sitemap.destination>

Where to write the sitemap, relative to the site destination. Defaults to
C<sitemap.xml>.

=item C<sitemap.baseurl>

Absolute base URL of the site, prefixed to every entry. Falls back to the
site-wide C<baseurl> config key. Sitemaps require absolute URLs, so you
should set this (a warning is emitted otherwise).

=item C<sitemap.lastmod>

Whether to include C<< <lastmod> >> elements. Defaults to 1. For posts the
post date is used; for pages the modification time of the input file. Set
to 0 to omit.

=item C<sitemap.exclude>

Arrayref of regexes; URLs matching any of them are left out of the
sitemap.

=back

=head1 METHODS

=head2 generate

=head2 _lastmod

Returns a W3C-datetime lastmod string for the object: the post date for
posts, the modification time of the input file for pages, or undef if
neither is available.

=head2 _render

Renders the entries as a sitemap.xml document.

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
