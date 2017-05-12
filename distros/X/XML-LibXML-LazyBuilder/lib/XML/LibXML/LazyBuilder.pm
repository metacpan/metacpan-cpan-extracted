package XML::LibXML::LazyBuilder;

use 5.008000;
use strict;
use warnings FATAL => 'all';

use Carp         ();
use Scalar::Util ();
use XML::LibXML  ();

# consider using Exporter::Lite - djt
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::LibXML::LazyBuilder ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	DOM E P C D F DTD
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.08';

# This is a map of all the DOM level 3 node names for
# non-element/attribute nodes. Note how there is no provision for
# processing instructions.
my %NODES = (
    '#cdata-section'     => 1,
    '#comment'           => 1,
    '#document'          => 1,
    '#document-fragment' => 1,
    '#text'              => 1,
);

# Note this is and will remain a stub until appropriate behaviour can
# be worked out.

# (Perhaps a name of ?foo for processing instructions?)

# nah, special methods for non-element nodes!



# Preloaded methods go here.


# This predicate is an alternative to using UNIVERSAL::isa as a
# function (which is a no-no); it will return true if a blessed
# reference is derived from a built-in reference type.

sub _is_really {
    my ($obj, $type) = @_;
    return unless defined $obj and ref $obj;
    return Scalar::Util::blessed($obj) ? $obj->isa($type) : ref $obj eq $type;
}

sub DOM ($;$$) {
    my ($sub, $ver, $enc) = @_;

    my $dom = XML::LibXML::Document->new ($ver || "1.0", $enc || "utf-8");

    # this whole $dom $sub thing is cracking me up ;) -- djt
    my $node = $sub->($dom);

    if (_is_really($node, 'XML::LibXML::DocumentFragment')) {
        # "Appending a document fragment node to a document node not
        # supported yet!", says XML::LibXML, so we work around it.

        for my $child ($node->childNodes) {
            #warn $child->ownerDocument;
            $child->unbindNode;
            if ($child->nodeType == 1) {
                if (my $root = $dom->documentElement) {
                    unless ($root->isSameNode($child)) {
                        Carp::croak("Trying to insert a second root element");
                    }
                }
                else {
                    $dom->setDocumentElement($child);
                }
            }
            else {
                $dom->appendChild($child);
            }
        }
    }
    elsif (_is_really($node, 'XML::LibXML::Element')) {
        # NO-OP: Elements get attached to the root from inside the E
        # function so it can access the namespace map.
    }
    else {
        $dom->appendChild($node);
    }

    $dom;
}

sub E ($;$@) {
    my ($name, $attr, @contents) = @_;

    return sub {
        my ($dom, $parent) = @_;

        # note, explicit namespace declarations in the attribute set
        # are held separately from actual namespace mappings found
        # from scanning the document.
        my (%ns, %nsdecl, %attr, $elem, $prefix);

        # pull the namespace declarations out of the attribute set
        if (_is_really($attr, 'HASH')) {
            while (my ($n, $v) = each %$attr) {
                if ($n =~ /^xmlns(?::(.*))?$/) {
                    $nsdecl{$1 || ''} = $v;
                }
                else {
                    $attr{$n} = $v;
                }
            }
        }

        if (_is_really($name, 'XML::LibXML::Element')) {
            # throw an exception if the element is not bound to a
            # document, which itself should become our new $dom
            Carp::croak("The supplied element must be bound to a document")
                  unless $dom = $name->ownerDocument;

            # and of course $name is our new $elem
            $elem   = $name;
            $name   = $elem->nodeName;
            $prefix = $elem->prefix || '';

            # then we don't need to scan the document for namespaces,
            # but we probably should set it for attributes
            %ns = map { $elem->lookupNamespacePrefix($_) || '' => $_ }
                $elem->getNamespaces;
        }
        elsif (my $huh = ref $name) {
            Carp::croak("Expected an XML::LibXML::Element; got $huh instead");
        }
        else {
            # $name is a string
            ($prefix) = ($name =~ /^(?:([^:]+):)?(.*)$/);
            $prefix ||= '';

            # XXX what happens if $name isn't a valid QName?

            $elem = $dom->createElement($name);

            # check for a document element so we can find existing namespaces
            if ($parent ||= $dom->documentElement) {
                # XXX this is naive
                for my $node ($parent->findnodes('namespace::*')) {
                    $ns{$node->declaredPrefix || ''} = $node->declaredURI;
                }
            }
            else {
                # do this here to make the tree walkable
                $dom->setDocumentElement($elem);
            }

        }

        # now do namespaces, overriding if necessary

        # first with the implicit mapping
        if ($ns{$prefix}) {
            $elem->setNamespace($ns{$prefix}, $prefix, 1);
        }

        # then with the explicit declarations
        for my $k (keys %nsdecl) {
            # activate if the ns matches the prefix
            $elem->setNamespace($nsdecl{$k}, $k, $k eq $prefix);
        }

        # now smoosh the mappings together for the attributes
        %ns = (%ns, %nsdecl);

        # NOW do the attributes
        while (my ($n, $v) = each %attr) {
            my ($pre, $loc) = ($n =~ /^(?:([^:]+):)?(.*)$/);

            # it'll probably mess up xpath queries if we explicitly
            # add namespaces to non-prefixed attributes
            if ($pre and my $nsuri = $ns{$pre}) {
                $elem->setAttributeNS($nsuri, $n, $v);
            }
            else {
                $elem->setAttribute($n, $v);
            }
        }

        # and finally child nodes
        for my $child (@contents) {
            if (_is_really($child, 'CODE')) {
                $elem->appendChild ($child->($dom, $elem));
            }
            elsif (_is_really($child, 'XML::LibXML::Node')) {
                # hey, why not?
                $elem->appendChild($child);
            }
            elsif (my $huh = ref $child) {
                Carp::croak
                      ("$huh is neither a CODE ref or an XML::LibXML::Node");
            }
            else {
                $elem->appendTextNode ($child);
            }
        }

        $elem;
    };
}

# processing instruction
sub P ($;$@) {
    my ($target, $attr, @text) = @_;

    return sub {
        my $dom = shift;

        # copy, otherwise this will just keep packing it on if executed
        # more than once
        my @t = @text;

        # turn into k="v" convention
        if (defined $attr) {
            if (_is_really($attr, 'HASH')) {
                my $x = join ' ',
                    map { sprintf '%s="%s"', $_, $attr->{$_} } keys %$attr;
                unshift @t, $x;
            }
            else {
                unshift @t, $attr;
            }
        }

        return $dom->createProcessingInstruction($target, join '', @t);
    };
}

# comment
sub C (;@) {
    my @text = @_;

    return sub {
        my $dom = shift;
        $dom->createComment(join '', @text);
    };
}

# CDATA
sub D (;@) {
    my @text = @_;

    return sub {
        my $dom = shift;
        $dom->createCDATASection(join '', @text);
    };
}

# document fragment
sub F (@) {
    my @children = @_;

    return sub {
        my $dom = shift;
        my $frag = $dom->createDocumentFragment;
        for my $child (@children) {
            # same as E
            if (_is_really($child, 'CODE')) {
                $frag->appendChild($child->($dom));
            }
            elsif (_is_really($child, 'XML::LibXML::Node')) {
                $frag->appendChild($child);
            }
            elsif (my $huh = ref $child) {
                Carp::croak
                      ("$huh is neither a CODE ref or an XML::LibXML::Node");
            }
            else {
                $frag->appendChild($dom->createTextNode($child));
            }
        }
        $frag;
    };
}

sub DTD ($;$$) {
    my ($name, $public, $system) = @_;

    return sub {
        my $dom = shift;

        # must be an XS hiccup; can't just pass these in if they're undef
        $dom->createExternalSubset($name, $public || undef, $system || undef);
    };
}

1;
__END__

=head1 NAME

XML::LibXML::LazyBuilder - easy and lazy way to create XML documents
for XML::LibXML

=head1 SYNOPSIS

  use XML::LibXML::LazyBuilder;

  {
      package XML::LibXML::LazyBuilder;
      $d = DOM (E A => {at1 => "val1", at2 => "val2"},
                ((E B => {}, ((E "C"),
                              (E D => {}, "Content of D"))),
                 (E E => {}, ((E F => {}, "Content of F"),
                              (E "G")))));
  }

=head1 DESCRIPTION

This module significantly abridges the overhead of working with
L<XML::LibXML> by enabling developers to write concise, nested
structures that evaluate into L<XML::LibXML> objects.

=head1 FUNCTIONS

=head2 DOM

    my $doc = DOM (E $name => \%attr, @children), $var, $enc;

    # With defaults, this is shorthand for:

    my $doc = E($name => \%attr,
                @children)->(XML::LibXML::Document->new);

Generates a C<XML::LibXML::Document> object. The first argument is a
C<CODE> reference created by C<E>. C<$var> represents the version in
the XML declaration, and C<$enc> is the character encoding, which
default to C<1.0> and C<utf-8>, respectively.

=head2 E

    my $sub = E tagname => \%attr, @children;

    my $doc = DOM $sub;

This function returns a C<CODE> reference which itself evaluates to an
L<XML::LibXML::Element> object. The function returned from C<E>
expects an L<XML::LibXML::Document> object as its only argument, which
is conveniently provided by L</DOM>.

=head3 Using C<E> with an existing XML document

C<E> can also be used to compose the subtree of an existing XML
element. Instead of supplying a name as the first argument of C<E>,
supply an L<XML::LibXML::Element> object. Note, however, that any
attributes present in that object will be overwritten by C<\%attr>,
and the supplied element I<must> be bound to a document, or the
function will croak. This is to ensure that the subtree is connected
to the element's document and not some other document.

As such, any L<XML::LibXML::Document> object passed into the function
returned by C<E> will be ignored in favour of the document connected
to the supplied element. This also means that C<E($elem =E<gt> \%attr,
@children)-E<gt>($ignored_dom);> can be called in void context, because
it will just return C<$elem>.

    # parse an existing XML document
    my $doc = XML::LibXML->load_xml(location => 'my.xml');

    # find an element of interest
    my ($existing) = $doc->findnodes('//some-element[1]');

    # prepare the subtree
    my $sub = E $existing => \%attr, @children;

    # this will overwrite the attributes of $existing and append
    # @children to it; normally the document is passed as an argument
    # but in this case it would be derived from $existing.

    $sub->();

    # we also don't care about the output of this function, since it
    # will have modified $doc, which we already have access to.

Note as well that members of C<@children> can be L<XML::LibXML::Node>
objects.

=head3 Namespaces

Qualified element names and namespace declaration attributes will
behave largely as expected. This means that:

    E 'foo:bar' => { 'xmlns:foo' => 'urn:x-foo:' }; # ...

...will properly induct the generated element into the C<foo>
namespace. L<E> attempts to infer the namespace mapping from the
document, so child elements with qualified names will inherit the
mapping from their ancestors.

=over 4

B<CAVEAT:> When C<E> is executed in the context of an I<element name>
rather than with an existing L<XML::LibXML::Element>, the namespace
mappings are scanned from the context of the document root, in
document order. This means that the last namespace declaration that
appears in the existing document (depth-first) will occupy the given
prefix. When an existing element is passed into C<E>, the namespace
search begins there and ascends to the root. If you have any concerns
about collisions of namespace declarations, use that form instead.

=back

=head2 P

    my $sub = P target => { key => 'value' }, @othertext;

This function returns a C<CODE> reference which returns a processing
instruction. If you pass in a HASH reference as the first argument, it
will be turned into key-value pairs using double-quotes on the
values. This means you have to take care of your own escaping of any
double quotes that may be in the values. The rest of the arguments are
concatenated into a string (intended to behave like L<perlfunc/print>,
which means if you want spaces between them, you likewise need to add
them yourself).

=head2 C

    my $sub = C @text;

This function creates a C<CODE> reference which returns a comment.
Again, C<@text> is simply concatenated, so if you wish to do any
additional formatting, do so before passing it in.

=head2 D

    my $sub = D @text;

This function creates a C<CODE> reference which returns a CDATA
section. Works identically to L</C>.

=head2 F

    my $sub = F @children;

This function creates a C<CODE> reference which returns a document
fragment. Since L</DOM> can only accept a single node-generating
function, it is particularly useful for the following idiom:

    my $doc = DOM F(
        (P 'xml-stylesheet' => { type => 'text/xsl', href => '/foo.xsl' }),
        (E mydoc => {}, @children));

Which produces:

    <?xml version="1.0" encoding="utf-8"?>
    <?xml-stylesheet type="text/xsl" href="/foo.xsl"?>
    <mydoc>...</mydoc>

=head2 DTD

    my $sub = DTD $name => $public, $system;

This function creates a C<CODE> reference which returns a DTD
declaration. Both C<$public> and C<$system> can be C<undef>.

=head1 EXPORT

None by default.

=head2 :all

Exports L</E>, L</P>, L</C>, L</D>, L</F> and L</DOM>.

=head1 EXAMPLES

If you nest your code in braces and use a C<package> declaration like
so, you can avoid polluting the calling package's namespace:

  my $d;
  {
      package XML::LibXML::LazyBuilder;
      $d = DOM (E A => {at1 => "val1", at2 => "val2"},
                ((E B => {}, ((E "C"),
                              (E D => {}, "Content of D"))),
                 (E E => {}, ((E F => {}, "Content of F"),
                              (E "G")))));
  }

Then, C<< $d->toString >> will generate XML like this:

  <?xml version="1.0" encoding="utf-8"?>
  <A at1="val1" at2="val2"><B><C/><D>Content of D</D></B><E><F>Content of F</F><G/></E></A>

=head1 SEE ALSO

L<XML::LibXML>

The Python module L<lxml.etree|http://lxml.de/tutorial.html>

=head1 AUTHOR

L<Toru Hisai|mailto:toru@torus.jp>

Namespace and non-element support by L<Dorian Taylor|mailto:dorian@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008, 2012 by Toru Hisai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
