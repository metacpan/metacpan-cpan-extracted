# NAME

XML::RSS::LibXML - XML::RSS with XML::LibXML

# SYNOPSIS

    use XML::RSS::LibXML;
    my $rss = XML::RSS::LibXML->new;
    $rss->parsefile($file);

    print "channel: $rss->{channel}->{title}\n";
    foreach my $item (@{ $rss->{items} }) {
       print "  item: $item->{title} ($item->{link})\n";
    }

    # Add custom modules
    $rss->add_module(uri => $uri, prefix => $prefix);

    # See docs for XML::RSS for these
    $rss->channel(...);
    $rss->add_item(...);
    $rss->image(...);
    $rss->textinput(...);
    $rss->save(...);

    $rss->as_string($format);

    # XML::RSS::LibXML only methods

    my $version     = $rss->version;
    my $base        = $rss->base;
    my $hash        = $rss->namespaces;
    my $list        = $rss->items;
    my $encoding    = $rss->encoding;
    my $modules     = $rss->modules;
    my $output      = $rss->output;
    my $stylesheets = $rss->stylesheets;
    my $num_items   = $rss->num_items;

# DESCRIPTION

XML::RSS::LibXML uses XML::LibXML (libxml2) for parsing RSS instead of XML::RSS'
XML::Parser (expat), while trying to keep interface compatibility with XML::RSS.

XML::RSS is an extremely handy tool, but it is unfortunately not exactly the
most lean or efficient RSS parser, especially in a long-running process.
So for a long time I had been using my own version of RSS parser to get the
maximum speed and efficiency - this is the re-packaged version of that module,
such that it adheres to the XML::RSS interface.

Use this module when you have severe performance requirements working with
RSS files.

# VERSION 0.3105

The original XML::RSS has been evolving in fairly rapid manner lately,
and that meant that there were a lot of features to keep up with.
To keep compatibility, I've had to pretty much rewrite the module from
ground up.

Now XML::RSS::LibXML is \*almost\* compatible with XML::RSS. If there are
problems, please send in bug reports (or more preferrably, patches ;)

# COMPATIBILITY

There seems to be a bit of confusion as to how compatible XML::RSS::LibXML 
is with XML::RSS: XML::RSS::LibXML is __NOT__ 100% compatible with XML::RSS. 
For instance XML::RS::LibXML does not do a complete parsing of the XML document
because of the way we deal with XPath and libxml's DOM (see CAVEATS below)

On top of that, I originally wrote XML::RSS::LibXML as sort of a fast 
replacement for XML::RAI, which looked cool in terms of abstracting the 
various modules.  And therefore versions prior to 0.02 worked more like 
XML::RAI rather than XML::RSS. That was a mistake in hind sight, so it has
been addressed (Since XML::RSS::LibXML version 0.08, it even supports
writing RSS :)

From now on XML::RSS::LibXML will try to match XML::RSS's functionality as
much as possible in terms of parsing RSS feeds. Please send in patches and
any tests that may be useful!

# PARSED STRUCTURE

Once parsed the resulting data structure resembles that of XML::RSS. However,
as one addition/improvement, XML::RSS::LibXML uses a technique to allow users
to access complex data structures that XML::RSS doesn't support as of this
writing.

For example, suppose you have a tag like the following:

    <rss version="2.0" xml:base="http://example.com/">
    ...
      <channel>
        <tag attr1="val1" attr2="val3">foo bar baz</tag>
      </channel>
    </rss>

All of the fields in this construct can be accessed like so:

    $rss->channel->{tag}        # "foo bar baz"
    $rss->channel->{tag}{attr1} # "val1"
    $rss->channel->{tag}{attr2} # "val2"

See [XML::RSS::LibXML::MagicElement](https://metacpan.org/pod/XML::RSS::LibXML::MagicElement) for details.

# METHODS

## new(%args)

Creates a new instance of XML::RSS::LibXML. You may specify a version or an
XML base in the constructor args to control which output format as\_string()
will use.

    XML::RSS::LibXML->new(version => '1.0', base => 'http://example.com/');

The XML base will be included only in RSS 2.0 output. You can also specify the
encoding that you expect this RSS object to use when creating an RSS string

    XML::RSS::LiBXML->new(encoding => 'euc-jp');

## parse($string)

Parse a string containing RSS.

## parsefile($filename)

Parse an RSS file specified by $filename

## channel(%args)

## add\_item(%args)

## image(%args)

## textinput(%args)

These methods are used to generate RSS. See the documentation for XML::RSS
for details. Currently RSS version 0.9, 1.0, and 2.0 are supported.

Additionally, add\_item takes an extra parameter, "mode", which allows
you to add items either in front of the list or at the end of the list:

    $rss->add_item(
       mode => "append",
       title => "...",
       link  => "...",
    );

    $rss->add_item(
       mode => "insert",
       title => "...",
       link  => "...",
    );

By default, items are appended to the end of the list

## as\_string($format)

Return the string representation of the parsed RSS. If $format is true, this
flag is passed to the underlying XML::LibXML object's toString() method.

By default, $format is true.

## add\_module(uri => $uri, prefix => $prefix)

Adds a new module. You should do this before parsing the RSS.
XML::RSS::LibXML understands a few modules by default:

    rdf     => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    dc      => "http://purl.org/dc/elements/1.1/",
    syn     => "http://purl.org/rss/1.0/modules/syndication/",
    admin   => "http://webns.net/mvcb/",
    content => "http://purl.org/rss/1.0/modules/content/",
    cc      => "http://web.resource.org/cc/",
    taxo    => "http://purl.org/rss/1.0/modules/taxonomy/",

So you do not need to add these explicitly.

## save($file)

Saves the RSS to a file

## items()

Syntactic sugar to allow statement like this:

    foreach my $item ($rss->items) {
      ...
    }

Instead of 

    foreach my $item (@{$rss->{items}}) {
      ...
    }

In scalar context, returns the reference to the list of items.

## create\_libxml()

Creates, configures, and returns an XML::LibXML object. Used by `parse()` to
instantiate the parser used to parse the feed.

# PERFORMANCE

Here's a simple benchmark using benchmark.pl in this distribution,
using XML::RSS 1.29\_02 and XML::RSS::LibXML 0.30

    daisuke@beefcake XML-RSS-LibXML$ perl -Mblib tools/benchmark.pl t/data/rss20.xml 
    XML::RSS -> 1.29_02
    XML::RSS::LibXML -> 0.30
                 Rate        rss rss_libxml
    rss        25.6/s         --       -67%
    rss_libxml 78.1/s       205%         --

# CAVEATS

\- Only first level data under <channel> and <item> tags are
examined. So if you have complex data, this module will not pick it up.
For most of the cases, this will suffice, though.

\- Namespace for namespaced attributes aren't properly parsed as part of 
the structure.  Hopefully your RSS doesn't do something like this:

    <foo bar:baz="whee">

You won't be able to get at "bar" in this case:

    $xml->{foo}{baz}; # "whee"
    $xml->{foo}{bar}{baz}; # nope

\- Some of the structures will need to be handled via 
XML::RSS::LibXML::MagicElement. For example, XML::RSS's SYNOPSIS shows
a snippet like this:

    $rss->add_item(title => "GTKeyboard 0.85",
       # creates a guid field with permaLink=true
       permaLink  => "http://freshmeat.net/news/1999/06/21/930003829.html",
       # alternately creates a guid field with permaLink=false
       # guid     => "gtkeyboard-0.85
       enclosure   => { url=> 'http://example.com/torrent', type=>"application/x-bittorrent" },
       description => 'blah blah'
    );

However, the enclosure element will need to be an object:

    enclosure => XML::RSS::LibXML::MagicElement->new(
      attributes => {
         url => 'http://example.com/torrent', 
         type=>"application/x-bittorrent" 
      },
    );

\- Some elements such as permaLink elements are not really parsed
such that it can be serialized and parsed back and force. I could fix
this, but that would break some compatibility with XML::RSS

# TODO

Tests. Currently tests are simply stolen from XML::RSS. It would be nice
to have tests that do more extensive testing for correctness

# SEE ALSO

[XML::RSS](https://metacpan.org/pod/XML::RSS), [XML::LibXML](https://metacpan.org/pod/XML::LibXML), [XML::LibXML::XPathContext](https://metacpan.org/pod/XML::LibXML::XPathContext)

# COPYRIGHT AND LICENSE

Copyright (c) 2005-2007 Daisuke Maki <dmaki@cpan.org>, Tatsuhiko Miyagawa <miyagawa@bulknews.net>. All rights reserved.

Many tests were shamelessly borrowed from XML::RSS 1.29\_02

Development partially funded by Brazil, Ltd. <http://b.razil.jp>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
