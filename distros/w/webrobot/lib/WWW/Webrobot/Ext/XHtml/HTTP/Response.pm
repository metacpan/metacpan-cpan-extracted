package WWW::Webrobot::Ext::XHtml::HTTP::Response;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


# extend LWPs HTTP::Response without subclassing
package HTTP::Response;
use strict;
use warnings;

use HTML::TreeBuilder;
use WWW::Webrobot::UseXPath;
use WWW::Webrobot::Html2XHtml;
use WWW::Webrobot::MyEncode qw/octet_to_internal_utf8/;


=head1 NAME

WWW::Webrobot::WebrobotLoad - Run testplans with multiple clients

=head1 SYNOPSIS

 use WWW::Webrobot::Ext::XHtml::HTTP::Response;

=head1 DESCRIPTION

This module extends the L<HTTP::Response> module.

=head1 METHODS

=over

=item content_charset

This method extracts the charset which is encoded in the HTTP header
'content-type' field.

        'content-type' => 'text/plain; charset=utf-8'

yields 'utf-8'.
However, the content-type field may be a scalar as in the example above
or an array of scalars.

If a content-type is set within the HTTP header B<and> an HTML document
you will get an array with two scalars:
The first comes from the HTTP header and the second from the document.

This method extract the first content-type which is set.

=cut

sub content_charset {
    my ($r) = @_;
    return undef if ! $r;
    # $r->content_encoding() isn't ok, so do it myself;
    my $coding = undef;
    if ($r and my $ct = $r->headers->{'content-type'}) {
        $ct = [ $ct ] if ref $ct ne "ARRAY";
        CODING:
        foreach (@$ct) {
            if (m/;\s*charset\s*=\s*([^\s;]*)/) {
                $coding = $1;
                last CODING;
            }
        }
    }
    return $coding;
}


=item content_xhtml

Returns an XML file

If called with an argument it is interpreted as a boolean method
that returns 1 if an xhtml content is set.

=cut

sub content_xhtml {
    my ($self, $arg) = @_;
    return $self -> {_content_xhtml} ? 1 : 0 if defined $arg;

    if (! exists $self -> {_content_xhtml}) {
        my $content = $self->content;

        my $xhtml;
        foreach ($self->content_type()) {
            /^text\/html$/ and do {
                my $encoding = $self->content_charset();
                my $parser = WWW::Webrobot::Html2XHtml->new();
                $xhtml = $parser->to_xhtml($content, $encoding);
                last;
            };
            /text\/xml$/ || /^application\/xml$/ || /^application\/xhtml+xml$/ and do {
                $xhtml = $content;
            };
        }
        $self -> {_content_xhtml} = $xhtml;
    }

    return $self -> {_content_xhtml};
}

=item content_encoded

C<HTTP::Response->content> returns a sequence of octets.
This method makes it a perl string according to the specified encoding.

See L<content_charset>.

=cut

sub content_encoded {
    my ($self, $arg) = @_;
    return $self -> {_content_encoded} ? 1 : 0 if $arg;
    if (! exists $self -> {_content_encoded}) {
        my $encoding = $self->content_charset();
        my $content_encoded = octet_to_internal_utf8($encoding, $self->content);
        $self -> {_content_encoded} = $content_encoded;
    }

    return $self -> {_content_encoded};
}

=item xpath

Applies an XPath expression to L<content_xhtml>.
The XPath expression builder will be cached,
as it is a B<very slow> operation.

=cut

sub xpath {
    my ($self, $expr) = @_;
    my $xml = $self->content_xhtml();
    return undef if !$xml;
    $self->{_xpath} = WWW::Webrobot::UseXPath->new($xml) if !exists $self->{_xpath};
    return $self -> {_xpath} -> extract($expr);
}

=pod

=back

=cut

1;
