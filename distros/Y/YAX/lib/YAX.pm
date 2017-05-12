package YAX;

use strict;

use YAX::Parser;
use YAX::Builder;

our $VERSION = '0.03';
1;
__END__

=head1 NAME

YAX - Yet Another XML library

=head1 SYNOPSIS

 use YAX::Parser;
  
 # DOM parse
 my $xdoc = YAX::Parser->parse( $xstr );
 my $xdoc = YAX::Parser->parse_file( '/some/file.xml' );
  
 # stream parse
 YAX::Parser->stream( $xstr, $state,
    text => \&parse_text,
    elmt => \&parse_element_open,
    elcl => \&parse_element_close,
    ... # see YAX::Parser
 );
 YAX::Parser->stream_file( '/some/file.xml', $state, %handlers );
  
 # access the document root
 my $root = $xdoc->root;
  
 # get an element by id
 my $elmt = $xdoc->get( 'foo' );
  
 # attribute access
 $elmt->{meaning} = 42;
  
 # loop over children
 for my $child ( @$elmt ) {
     ...
 }
  
 # query the DOM
 my $nlst = $elmt->query(q{..a.b.*.(@foo eq 'bar')[1 .. 2]});
  
 # declarative programmatic DOM construction
 use YAX::Builder;
 my $node = YAX::Builder->node(
    [ table => { border => 1 },
        [ tr =>
            [ td => { align => 'top' },
                [ a => { href => '/foo' }, "Click Me!" ]
            ]
        ]
    ]
 );
  
 # serialization
 my $xstr = $node->as_string;
 my $xstr = "$node";    # '""' is overloaded

=head1 DESCRIPTION

YAX is a fast pure Perl XML library for easily parsing, constructing,
querying and manipulating XML. Simple benchmarks have shown that it is
substantially faster than L<XML::DOM::Parser> which uses Expat internally
(which is written in C), see L</PERFORMANCE> for an explanation and
related caveats.

However, the main point of YAX is to remove the verbosity of the DOM API
by using more perlish tricks such as operator overloading. For example,
element nodes can behave as both array references and hash references. If
dereferenced as an array reference, then a list of children is returned;
as a hash reference, the attributes hash is returned. So the following
show uses cases for this:

 my @good_books = grep { $_->{author} =~ /\bAsimov\b/ } @$elmt;

You can also hang out of band data onto your elements:

 $elmt->{notes} = IO::File->new( './notes/asimov.txt' );

without affecting serialization since attributes who's values are
references are ignored during stringification.

YAX nodes, of course, also provide methods for appending, replacing
and removing children as well (note the following all operate on
the children of C<$node>):

 $node->replace( $new_child, $ref_child );
 $node->remove( $child );
 $node->append( $child );
 $node->insert( $new_child, $ref_child );

=head2 Parsing

The YAX parser supports both tree parsing and stream based parsing. For
the most part, we'll focus on tree parsing, since stream based parsing
is very simple and documented in detail in L<YAX::Parser>.

Although constructing a parser via YAX::Parser->new is supported, it
isn't neccessary since the parser doesn't keep any state other than
what's on the stack, so normally you would use the C<parse*> or C<stream*>
class methods:

 use YAX::Parser;
 my $xdoc = YAX::Parser->parse(<<XML);
    <doc>
        <title>Shallow Parsing with Regular Expressions</title>
        <author>Robert D. Cameron</author>
    </doc>
 XML

or to parse a file:

 my $xdoc = YAX::Parser->parse_file( $filename ) || die $!;

YAX is not a strict parser, per se, and it does no validation. It's
internals are based on a shallow regular expression parser (credit to
Robert D.Cameron) and as such is a little bit forgiving. It will still
try to make sense of HTML tag soup which isn't well formed (i.e. <p>
tags without matching closing tags), so you will still get a DOM, but
the nesting of elements will probably not be what was intended.

This can be a good thing or a bad thing, depending on the use to which
it is put. The idea is to make it useful in most cases while keeping
it fast, lean and pure Perl.

=head2 Querying

YAX also provides a way to query the DOM based on a dialect (of a subset)
of E4X (ECMA for XML). That is: path expressions are supported in much the
same way, but filter expressions contain Perl operators, and assignment
isn't supported (this latter isn't a problem because L<YAX::Builder>
provides an equally powerful way of constructing DOM fragments).

For example, the following:

 my $list = $node->query(q{..a.*.(@foo eq 'bar')});

This reads: fetch all <a> descendents of C<$node> `..a' then from this
set select all child elements `.*' and apply a filter for those which
have a C<foo> attribute equal to bar `.(@foo eq 'bar')'.

The returned C<$query> object is special in that it supports chained calls
via the query's OO interface, so the following does exactly the same:

 my $query = $node->query('..a.*')->filter(sub { $_->{foo} eq 'bar' });

or the more verbose:

 use YAX::Constants qw/:all/; # for ELEMENT_NODE
  
 $list = $node->query->descendants->child('a')->children(ELEMENT_NODE);
 $list = $list->filter(sub { $_->{foo} eq 'bar' });

To learn more see the L<YAX::Query> documentation.

=head2 Building

YAX provides a way of programmatically constructing DOM fragments.
The general pattern is as follows:

 use YAX::Builder;
 my $node = YAX::Builder->node([ 'name', \%atts, @kids ]);

The rules are simple:

An element descriptor is an array reference;

The first element is the name of the element;

If a hash reference is in the second position, it is assumed to be the
attributes (optional);

Anything else are the children, any of which may be strings (converted to
text nodes), array references (converted to elements by the same rules)
or YAX::Node objects (passed through).

This is all, of course, recursive, so arbitrarily deep nesting is
supported (and indeed, encouraged).

Details are in L<YAX::Builder>, including creating document fragments
and text nodes.

=head1 PERFORMANCE

The following benchmark results compares XML::DOM::Parser with YAX::Parser:

 xml_dom:  8 wallclock secs ( 8.61 usr +  0.00 sys =  8.61 CPU) @ 580.72/s (n=5000)
 yax_dom:  4 wallclock secs ( 3.52 usr +  0.00 sys =  3.52 CPU) @ 1420.45/s (n=5000)

The results should speak for themselves.

However, it is important to note that we're not comparing oranges with
oranges here, since L<XML::DOM> firstly, is a strict parser (so it reports
well-formed-ness errors), and secondly, it creates objects for attributes,
whereas YAX is more lenient and just uses a hash references for attributes.

Also, the benchmark only tests parsing, and not manipulation or
traversal.  You may well find bottlenecks in these areas since some of
the manipulation operations have O(n) complexity. Not much effort has
been made to optimize these for the sake of simplicity, and because
it is usually possible to make manipulations more coarse grained using
L<YAX::Fragment> nodes and L<YAX::Builder>.

However, for most cases it should be fast enough :-)

=head1 ACKNOWLEDGEMENTS

YAX's parser is based on Robert D. Cameron's REX grammar:

L<http://www.cs.sfu.ca/~cameron/REX.html>

=head1 SEE ALSO

L<YAX::Parser>, L<YAX::Document>, L<YAX::Element>, L<YAX::Builder>, L<YAX::Query>

=head1 AUTHOR

 Richard Hundt

=head1 LICENSE

This program is free software and may be modified and distributed under
the same terms as Perl itself.


