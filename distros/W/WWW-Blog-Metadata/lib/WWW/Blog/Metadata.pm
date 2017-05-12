package WWW::Blog::Metadata;
use strict;
use 5.008_001;

use base qw( Class::ErrorHandler Class::Accessor );

our $VERSION = '0.03';

use Module::Pluggable::Ordered search_path => [ 'WWW::Blog::Metadata' ];
use HTML::Parser;
use Feed::Find;
use URI::Fetch;

__PACKAGE__->mk_accessors(qw(
    base_uri feeds foaf_uri generator lat lon
));

sub extract_from_html {
    my $class = shift;
    my($html, $base_uri) = @_;
    my $meta = $class->new;

    ## Extract feed URIs.
    $meta->feeds([ Feed::Find->find_in_html($html, $base_uri) ]);

    $class->call_plugins('on_got_html', $meta, $html, $base_uri);

    ## Now extract other stuff by parsing the HTML ourselves.
    my $p = HTML::Parser->new(
        api_version => 3,
        start_h => [ \&start_element, 'self,tagname,attr' ]
    );
    $p->{meta} = $meta;
    $p->{base_uri} = $base_uri;
    $p->parse($$html);

    $class->call_plugins('on_finished', $meta);
    $meta;
}

sub extract_from_uri {
    my $class = shift;
    my($uri) = @_;
    my $res = URI::Fetch->fetch($uri)
        or return $class->error(URI::Fetch->errstr);
    $class->extract_from_html(\$res->content, $uri);
}

sub start_element {
    my($p, $tag, $attr) = @_;
    my $meta = $p->{meta};
    if ($tag eq 'link') {
        return unless $attr->{rel};
        my %rel = map { $_ => 1 } split /\s+/, lc($attr->{rel});
        (my $type = lc $attr->{type}) =~ s/^\s*//;
        $type =~ s/\s*$//;
        my $href = URI->new_abs($attr->{href}, $p->{base_uri})->as_string;
        if ($rel{meta} && $type eq 'application/rdf+xml' &&
            $attr->{title} eq 'FOAF') {
            $meta->foaf_uri($href);
        }
    } elsif ($tag eq 'base') {
        $p->{base_uri} = $attr->{href} if $attr->{href};
    } elsif ($tag eq 'meta') {
        my $name = lc $attr->{name};
        if ($name eq 'icbm' || $name eq 'geo.position') {
            my($lat, $lon) = split /\s*[,;]\s*/, $attr->{content} || '';
            $meta->lat($lat);
            $meta->lon($lon);
        } elsif ($name eq 'generator') {
            $meta->generator($attr->{content});
        }
    } elsif ($tag =~ /^(?:isindex|title|script|style|head|html)$/) {
        ## Ignore.
    } else {
        $p->eof;
    }
    (ref $meta)->call_plugins('on_got_tag', $meta, $tag, $attr, $p->{base_uri});
}

1;
__END__

=head1 NAME

WWW::Blog::Metadata - Extract common metadata from weblogs

=head1 SYNOPSIS

    use WWW::Blog::Metadata;
    use Data::Dumper;
    my $uri;
    my $meta = WWW::Blog::Metadata->extract_from_uri($uri)
        or die WWW::Blog::Metadata->errstr;
    print Dumper $meta;

=head1 DESCRIPTION

I<WWW::Blog::Metadata> extracts common metadata from weblogs: syndication
feed URIs, FOAF URIs, locative information, etc. Some benefits of using
I<WWW::Blog::Metadata>:

=over 4

=item *

The extraction makes only one parsing pass over the HTML, rather than one
for each type of metadata. It also attempts to be intelligent about only
parsing as much of the HTML document as is required to give you the
metadata that you need.

=item *

Many of the types of metadata that I<WWW::Blog::Metadata> extracts can be
found in multiple places in an HTML document. This module does the work
for you, and abstracts it all behind an API.

=back

=head1 USAGE

=head2 WWW::Blog::Metadata->extract_from_uri($uri)

Given a URI I<$uri> pointing to a weblog, fetches the page contents, and
attempts to extract common metadata from that weblog.

On error, returns C<undef>, and the error message can be obtained by
calling I<WWW::Blog::Metadata-E<gt>errstr>.

On success, returns a I<WWW::Blog::Metadata> object.

=head2 WWW::Blog::Metadata->extract_from_html($html [, $base_uri ])

Uses the same extraction mechanism as I<extract_from_uri>, but assumes that
you've already fetched the HTML document and will provide it in I<$html>,
which should be a reference to a scalar containing the HTML.

If you know the base URI of the document, you should provide it in
I<$base_uri>. I<WWW::Blog::Metadata> will attempt to find the base URI of
the document if it's specified in the HTML itself, but you can give it a head
start by passing in I<$base_uri>.

This method has the same return value as I<extract_from_uri>.

=head2 $meta->feeds

A reference to a hash of syndication feed URIs.

(Note: these are currently extracted using I<Feed::Find>, which requires a
separate parsing step, and sort of renders the above benefit #1 somewhat of
a lie. This is done for maximum correctness, but it's possible it could
change at some point.)

=head2 $meta->foaf_uri

The URI for a FOAF file, specified in the standard manner used for
FOAF auto-discovery.

=head2 $meta->lat

=head2 $meta->lon

The latitude and longitude specified for the weblog, from either I<icbm>
or I<geo.position> I<E<lt>meta /E<gt>> tags.

=head2 $meta->generator

The tool that generated the weblog, from a I<generator> I<E<lt>meta /E<gt>>
tag.

=head1 PLUGINS

There are endless amounts of metadata that you might want to extract from
a weblog, and the methods above are only what are provided by default. If
you'd like to extract more information, you can use I<WWW::Blog::Metadata>'s
plugin architecture to build access to the metadata that you want, while
while making only one parsing pass over the HTML document.

The plugin architecture uses I<Module::Pluggable::Ordered>, and it provides
2 pluggable events:

=over 4

=item * on_got_html

This event is fired before the HTML document is parsed, so you should use it
for extracting metadata after the page has been fetched (if you're using
I<extract_from_uri>), but before it's been parsed.

Your method will receive 4 parameters: the class name; the
I<WWW::Blog::Metadata> object; a reference to a string containing the HTML
document; and the base URI of the document.

You could use this event to run heuristics on either the HTML or the URI,
or both. The following example uses I<WWW::Blog::Identify> to attempt to
identify the true generator of the weblog:

    package WWW::Blog::Metadata::Flavor;
    use strict;

    use WWW::Blog::Identify qw( identify );
    use WWW::Blog::Metadata;
    WWW::Blog::Metadata->mk_accessors(qw( flavor ));

    sub on_got_html {
        my $class = shift;
        my($meta, $html, $base_uri) = @_;
        $meta->flavor( identify($base_uri, $$html) );
    }
    sub on_got_html_order { 99 }

    1;

This automatically adds a new accessor to the I<$meta> object that is
returned from the I<extract_from_*> methods, so you can call

    my $meta = WWW::Blog::Metadata->extract_from_uri($uri);
    print $meta->flavor;

to retrieve the name of the identified weblogging tool.

=item * on_got_tag

This event is fired for each HTML tag found in the document during the
parsing phase.

Your method will receive 5 parameters: the class name; the
I<WWW::Blog::Metadata> object; the tag name; a reference to a hash
containing the tag attributes; and the base URI.

The following example looks for the specific tag identifying the URI for
the RSD (Really Simple Discoverability) file identifying the editing APIs
that the weblog supports.

    package WWW::Blog::Metadata::RSD;
    use strict;

    use WWW::Blog::Metadata;
    WWW::Blog::Metadata->mk_accessors(qw( rsd_uri ));

    sub on_got_tag {
        my $class = shift;
        my($meta, $tag, $attr, $base_uri) = @_;
        if ($tag eq 'link' && $attr->{rel} =~ /\bEditURI\b/i &&
            $attr->{type} eq 'application/rsd+xml') {
            $meta->rsd_uri(URI->new_abs($attr->{href}, $base_uri)->as_string);
        }
    }
    sub on_got_tag_order { 99 }

    1;

This automatically adds a new accessor to the I<$meta> object that is
returned from the I<extract_from_*> methods, so you can call

    my $meta = WWW::Blog::Metadata->extract_from_uri($uri);
    print $meta->rsd_uri;

to retrieve the URI for the RSD file.

=item * on_finished

This event is fired at the end of the extraction process.

Your method will receive 2 parameters: the class name, and the
I<WWW::Blog::Metadata> object.

=back

=head1 LICENSE

I<WWW::Blog::Metadata> is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<WWW::Blog::Metadata> is Copyright 2005
Benjamin Trott, ben+cpan@stupidfool.org. All rights reserved.

=cut
