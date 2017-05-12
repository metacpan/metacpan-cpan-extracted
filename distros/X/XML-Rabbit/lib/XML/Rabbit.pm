use strict;
use warnings;

package XML::Rabbit;
$XML::Rabbit::VERSION = '0.4.1';
use 5.008;

# ABSTRACT: Consume XML with Moose and xpath queries

use XML::Rabbit::Sugar (); # no magic, just load
use namespace::autoclean (); # no cleanup, just load
use Moose::Exporter;

my ($import, $unimport, $init_meta) = Moose::Exporter->build_import_methods(
    also             => 'XML::Rabbit::Sugar',
    base_class_roles => ['XML::Rabbit::Node'],
);


sub import {
    namespace::autoclean->import( -cleanee => scalar caller );
    return unless $import;
    goto &$import;
}


sub unimport {
    return unless $unimport;
    goto &$unimport;
}


#sub init_meta {
#    return unless $init_meta;
#    goto &$init_meta;
#}

# FIXME: https://rt.cpan.org/Ticket/Display.html?id=51561
# Hopefully fixed by 2.06 (doy)
sub init_meta {
    my ($dummy, %opts) = @_;
    Moose->init_meta(%opts);
    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $opts{for_class},
        roles => ['XML::Rabbit::Node']
    );
    return Moose::Util::find_meta($opts{for_class});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Rabbit - Consume XML with Moose and xpath queries

=head1 VERSION

version 0.4.1

=head1 SYNOPSIS

    my $xhtml = W3C::XHTML->new(
        file => 'index.xhtml',

        # or string...
        xml => $xml,

        # or filehandle...
        fh => $fh,

        # or XML::LibXML::Document object
        dom => $dom,
    );

    print "Title: " . $xhtml->title . "\n";
    print "First image source: " . $xhtml->body->images->[0]->src . "\n";

    exit;

    package W3C::XHTML;
    use XML::Rabbit::Root;

    add_xpath_namespace 'xhtml' => 'http://www.w3.org/1999/xhtml';

    has_xpath_value 'title' => '/xhtml:html/xhtml:head/xhtml:title';

    has_xpath_object 'body'  => '/xhtml:html/xhtml:body' => 'W3C::XHTML::Body';

    has_xpath_object_list 'all_anchors_and_images' => '//xhtml:a|//xhtml:img',
        {
            'xhtml:a'   => 'W3C::XHTML::Anchor',
            'xhtml:img' => 'W3C::XHTML::Image',
        },
    ;

    finalize_class();

    package W3C::XHTML::Body;
    use XML::Rabbit;

    has_xpath_object_list 'images' => './/xhtml:img' => 'W3C::XHTML::Image';

    finalize_class();

    package W3C::XHTML::Image;
    use XML::Rabbit;

    has_xpath_value 'src'   => './@src';
    has_xpath_value 'alt'   => './@alt';
    has_xpath_value 'title' => './@title';

    finalize_class();

    package W3C::XHTML::Anchor;
    use XML::Rabbit;

    has_xpath_value 'href'  => './@src';
    has_xpath_value 'title' => './@title';

    finalize_class();

=head1 DESCRIPTION

XML::Rabbit is a Moose-based class construction toolkit you can use to make
XPath-based XML extractors with very little code.  Each attribute in your
class created with the above helper function is linked to an XPath query
that is executed on your XML document when you request the value.  Creating
object hierarchies that mimic the layout of the XML document is almost as
easy as doing a search and replace on the XML DTD (if you have one).

You can return multiple values from the XML either as arrays or hashes,
depending on how you need to work with the data from the XML document.

The example in the synopsis shows how to create a class hierarchy that
enables easy retrival of certain information from an XHTML document.

Also notice that if you specify an xpath query that can return multiple XML
elements, you need to specify a hash map (xml tag => class name) instead of
just specifying the class name returned.

All the array and hash-returning attributes are tagged with the Array and
Hash native traits, so it is quick and easy to specify additional
delegations.  All the C<has_xpath_value*> helpers expect the value to be of
a C<Str> type constraint.  Array and hash-returning attributes automatically
set their isa to C<ArrayRef[Str]> and C<HashRef[Str]> respectively.

All the helper methods and their associated arguments are explained in
L<XML::Rabbit::Sugar> detail.

Be aware that if your XML document contains a default XML namespace (like
XHTML does), you MUST specify it with C<add_xpath_namespace()>, or else your
xpath queries will not match anything.  The XML document is not scanned for
XML namespaces during initialization.

=head1 FUNCTIONS

=head2 import

Automatically loads L<namespace::autoclean> into the caller's package and
dispatches to L<XML::Rabbit::Sugar/"import"> (tail call).

=head2 unimport

Dispatches to L<XML::Rabbit::Sugar/"unimport"> (tail call).

=head2 init_meta

Initializes the metaclass of the calling class and adds the role
L<XML::Rabbit::Node>.

=head1 IMPORTS

When you specify C<use XML::Rabbit::Root> (or C<use XML::Rabbit> in child
nodes) you do the equivalent of the following code:

    use Moose;
    with "XML::Rabbit::RootNode"; # if you use XML::Rabbit::Root
    with "XML::Rabbit::Node";     # if you use XML::Rabbit
    use namespace::autoclean;
    use XML::Rabbit::Sugar;

This ensures that you don't have to specify C<no Moose> at the end of your
code to clean up imported functions you have used in your class.

The C<finalize_class()> call at the end of the file is the same as writing
the following piece of code:

    __PACKAGE__->meta->make_immutable();

    1;

This optimizes the class and ensures it always returns a true value, which
is required to successfully load a Perl script file.

=head1 TECHNICAL DETAILS

The trait applied to the attribute will wrap the type constraint union in an
ArrayRef if the trait name is XPathObjectList and as a HashRef if the trait
name is XPathObjectMap.  As all the traits that end with List return array
references, their C<isa> must be an ArrayRef.  The same is valid for the
*Map traits, just that they return HashRef instead of ArrayRef.

The namespace prefix used in C<isa_map> MUST be specified in the
C<namespace_map>. If a prefix is used in C<isa_map> without a corresponding
entry in C<namespace_map> an exception will be thrown.

=head1 CAVEATS

Be aware of the syntax of XPath when used with namespaces. You should almost
always define C<namespace_map> when dealing with XML that use namespaces.
Namespaces explicitly declared in the XML are usable with the prefix
specified in the XML (except if you use C<isa_map>). Be aware that a prefix
must usually be declared for the default namespace (xmlns=...) to be able to
use it in XPath queries. See the example above (on XHTML) for details. See
L<XML::LibXML::Node/findnodes> for more information.

Because XML::Rabbit uses XML::LibXML's DOM parser it is limited to handling
XML documents that can fit in available memory. Unfortunately there is no
easy way around this, because XPath queries need to work on a tree model,
and I am not aware of any way of doing that without keeping the document in
memory. Luckily XML::LibXML's DOM implementation is written in C, so it
should use much less memory than a pure Perl DOM parser.

=head1 SEMANTIC VERSIONING

This module uses semantic versioning concepts from L<http://semver.org/>.

=head1 ACKNOWLEDGEMENTS

The following people have helped to review or otherwise encourage
me to work on this module.

Chris Prather (perigrin)

Matt S. Trout (mst)

Stevan Little (stevan)

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=item *

L<XML::LibXML>

=item *

L<namespace::autoclean>

=item *

L<XML::Toolkit>

=item *

L<XML::Twig>

=item *

L<Mojo::DOM>

=item *

L<XPath tutorial|http://zvon.org/comp/r/tut-XPath_1.html>

=item *

L<XPath Specification|http://www.w3.org/TR/xpath/>

=item *

L<Implementing WWW::LastFM, a client library to the Last.FM API, with XML::Rabbit|http://blog.robin.smidsrod.no/2011/09/30/implementing-www-lastfm-part-1>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::Rabbit

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/XML-Rabbit>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-Rabbit>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Rabbit>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-Rabbit>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-Rabbit>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/XML-Rabbit>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/XML-Rabbit>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Rabbit>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Rabbit>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Rabbit>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-rabbit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Rabbit>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/robinsmidsrod/XML-Rabbit>

  git clone git://github.com/robinsmidsrod/XML-Rabbit.git

=head1 AUTHOR

Robin Smidsrød <robin@smidsrod.no>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Robin Smidsrød.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
