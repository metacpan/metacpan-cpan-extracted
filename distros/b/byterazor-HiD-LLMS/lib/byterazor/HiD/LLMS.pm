# ABSTRACT: llms.txt generator


package byterazor::HiD::LLMS;

use Moose;
with 'HiD::Generator';

use 5.014; # strict, unicode_strings
use utf8;
use autodie;
use warnings   qw/ FATAL utf8 /;
use charnames  qw/ :full           /;

use Path::Tiny;

use HiD::VirtualPage;

our $VERSION = '0.1';


sub generate {
  my( $self , $site ) = @_;

  return unless $site->config->{llms}{generate};

  my $cfg              = $site->config->{llms};
  my $destination      = $cfg->{destination} // 'llms.txt';
  my $full             = exists $cfg->{full} ? $cfg->{full} : 1;
  my $full_destination = $cfg->{full_destination} // 'llms-full.txt';
  my $exclude          = $cfg->{exclude};

  my $baseurl = $cfg->{baseurl} // $site->config->{baseurl} // '/';

  $site->WARN(
    "llms: baseurl '$baseurl' is not an absolute URL; "
    . "set 'llms.baseurl' to the full URL of your site"
  ) unless $baseurl =~ m{^https?://};

  $baseurl =~ s{/+$}{};

  my $title = $cfg->{title} // $site->config->{title};
  if ( ! defined $title || ! length $title ) {
    $site->WARN(
      "llms: no site title; set 'llms.title' "
      . "(or the site 'title' config key)"
    );
    $title = 'Untitled';
  }

  my $description = $cfg->{description} // $site->config->{description};

  my %seen;

  my @page_entries;
  for my $object ( sort { $a->url cmp $b->url } @{ $site->pages } ) {
    my $url = $baseurl . $object->url;
    next if $exclude && grep { $url =~ /$_/ } @$exclude;
    next if $seen{$url}++;
    push @page_entries , $self->_entry( $object , $url );
  }

  my @post_entries;
  for my $object ( sort { _date_desc( $a , $b ) } @{ $site->posts } ) {
    my $url = $baseurl . $object->url;
    next if $exclude && grep { $url =~ /$_/ } @$exclude;
    next if $seen{$url}++;
    push @post_entries , $self->_entry( $object , $url );
  }

  my @sections = (
    [ 'Pages' => \@page_entries ] ,
    [ 'Posts' => \@post_entries ] ,
  );

  my $llms_page = HiD::VirtualPage->new({
    output_filename => path( $site->destination , $destination )->stringify ,
    content         => $self->_render(
      title       => $title ,
      description => $description ,
      baseurl     => $baseurl ,
      full_dest   => $full ? $full_destination : undef ,
      sections    => \@sections ,
    ),
  });

  $site->add_input( "LLMS" => 'page' );
  $site->add_object( $llms_page );

  if ( $full ) {
    my $full_page = HiD::VirtualPage->new({
      output_filename => path( $site->destination , $full_destination )->stringify ,
      content         => $self->_render_full(
        title    => $title ,
        sections => \@sections ,
      ),
    });

    $site->add_object( $full_page );
  }

  $site->INFO(
    sprintf( "* Injected llms.txt (%d pages, %d posts)" ,
      scalar @page_entries , scalar @post_entries )
  );

  return $llms_page;
}


sub _entry {
  my( $self , $object , $url ) = @_;

  my $title = $object->title if $object->can( 'title' );

  return {
    url         => $url ,
    title       => defined $title ? $title
                    : ( $object->get_metadata( 'title' )
                        // $self->_derive_title( $url ) ),
    description => $object->get_metadata( 'description' ),
    content     => $object->can( 'content' ) ? $object->content : undef ,
  };
}


sub _derive_title {
  my( $self , $url ) = @_;

  my $path = $url;
  $path =~ s{^https?://[^/]+}{};

  my @segs = grep { length } split m{/} , $path;

  $segs[-1] =~ s{\.[^./]+$}{} if @segs;
  pop @segs while @segs && $segs[-1] eq 'index';

  my $seg = @segs ? $segs[-1] : 'home';
  $seg =~ s{[-_]+}{ }g;

  return ucfirst $seg;
}

sub _date_desc {
  my( $a , $b ) = @_;

  my $da = $a->can( 'date' ) && $a->date ? $a->date->epoch : 0;
  my $db = $b->can( 'date' ) && $b->date ? $b->date->epoch : 0;

  return $db <=> $da;
}


sub _render {
  my( $self , %args ) = @_;

  my $md = "# $args{title}\n";
  $md .= "\n> $args{description}\n" if $args{description};

  for my $section ( @{ $args{sections} } ) {
    my( $name , $entries ) = @$section;
    next unless @$entries;

    $md .= "\n## $name\n\n";
    $md .= _entry_line( $_ ) for @$entries;
  }

  if ( $args{full_dest} ) {
    $md .= "\n## Optional\n\n"
      . "- [llms-full.txt]($args{baseurl}/$args{full_dest})"
      . ": Full site content for LLMs\n";
  }

  return $md;
}


sub _render_full {
  my( $self , %args ) = @_;

  my $md = "# $args{title}\n";

  for my $section ( @{ $args{sections} } ) {
    for my $entry ( @{ $section->[1] } ) {
      my $content = $entry->{content} // '';
      $content =~ s/\A\n+//;
      $content =~ s/\n+\z//;
      next unless length $content;

      $md .= "\n## " . _link_text( $entry->{title} ) . "\n\n" . $content . "\n";
    }
  }

  return $md;
}

sub _entry_line {
  my( $entry ) = @_;

  my $line = "- [" . _link_text( $entry->{title} ) . "](" . $entry->{url} . ")";
  $line .= ": " . _description_text( $entry->{description} )
    if defined $entry->{description};

  return $line . "\n";
}

# link text must not contain unescaped brackets or backslashes
sub _link_text {
  my( $text ) = @_;
  $text =~ s/([\[\]\\])/\\$1/g;
  return $text;
}

# descriptions must stay on a single line
sub _description_text {
  my( $text ) = @_;
  $text =~ s/\s*\n\s*/ /g;
  return $text;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

byterazor::HiD::LLMS - llms.txt generator

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This Generator produces a C<llms.txt> for your site, following the
L<llms.txt specification|https://llmstxt.org> -- a markdown-formatted index
of your site's pages and posts, designed to be read by large language models
instead of raw HTML.

By default a companion C<llms-full.txt> is produced as well, containing the
full markdown content of every page and post, as recommended by the
specification.

Enable it by adding C<+byterazor::HiD::LLMS> to the C<plugins> key in
your config. The C<+> prefix tells HiD to use the full class name rather
than looking in the C<HiD::Generator::> namespace:

    plugins:
      - '+byterazor::HiD::LLMS'
    llms:
      generate: 1

You may set the following additional C<llms.*> config keys:

=over 4

=item C<llms.title>

The site title used as the C<#> heading of the file. Falls back to the
site-wide C<title> config key. A warning is emitted and a placeholder is
used if neither is set.

=item C<llms.description>

A one-line site description, emitted as a blockquote below the title.
Falls back to the site-wide C<description> config key. Omitted if
neither is set.

=item C<llms.destination>

Where to write the C<llms.txt>, relative to the site destination.
Defaults to C<llms.txt>.

=item C<llms.full>

Whether to also generate C<llms-full.txt> with the full markdown content
of every page and post. Defaults to 1. Set to 0 to omit.

=item C<llms.full_destination>

Where to write the full file, relative to the site destination. Defaults
to C<llms-full.txt>.

=item C<llms.baseurl>

Absolute base URL of the site, prefixed to every entry. Falls back to the
site-wide C<baseurl> config key. The file is most useful with absolute
URLs, so you should set this (a warning is emitted otherwise).

=item C<llms.exclude>

Arrayref of regexes; URLs matching any of them are left out of both
files.

=back

Entries in the C<Pages> section are listed in URL order; entries in the
C<Posts> section are listed newest-first by post date.

Each entry's link text is the post title for posts, the C<title>
front-matter for pages (or a title derived from the URL if none is
given). A description, taken from the C<description> front-matter, is
appended after the colon when present.

=head1 METHODS

=head2 generate

=head2 _entry

Builds an entry hashref (url, title, description, content) for one page or
post.

=head2 _derive_title

Derives a human-readable title from a URL: the last path segment without
extension (dropping a trailing 'index'), dashes/underscores turned into
spaces, first letter uppercased. The site root yields 'Home'.

=head2 _render

Renders the sections as a llms.txt document.

=head2 _render_full

Renders the sections as a llms-full.txt document: the full markdown
content of every entry, each under its own C<##> heading.

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
