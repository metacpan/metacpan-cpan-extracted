package XML::RSS::LibXML;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp;
use UNIVERSAL::require;
use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::RSS::LibXML::Namespaces qw(NS_RSS10);

our $VERSION = '0.3105';

__PACKAGE__->mk_accessors($_) for qw(impl encoding strict namespaces modules output stylesheets _internal num_items);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $impl  = $class->create_impl($args{version});
    my $self = bless {
        impl       => $impl,
        version    => $args{version},
        base       => $args{base},
        encoding   => $args{encoding} || 'UTF-8',
        strict     => exists $args{strict} ? $args{strict} : 0,
        namespaces => {},
        modules    => {},
        _internal  => {},
        stylesheets => $args{stylesheet} ? (ref ($args{stylesheet}) eq 'ARRAY' ? $args{stylesheet} : [ $args{stylesheet} ]) : [],
        num_items   => 0,
        libxml_opts => $args{libxml_opts} || {
            recover => 1,
            load_ext_dtd => 0
        },
    }, $class;

    $self->impl->reset($self);
    return $self;
}

{
    # Proxy methods
    foreach my $method (qw(reset channel image add_item textinput skipDays skipHours)) {
        no strict 'refs';
        *{$method} = sub { my $self = shift; $self->impl->$method($self, @_) };
    }
}

sub internal
{
    my $self = shift;
    my $name = shift;

    my $value = $self->{_internal}{$name};
    if (@_) {
        $self->{_internal}{$name} = $_[0];
    }
    return $value;
}

sub version
{
    my $self = shift;
    my $version = $self->{version};
    if (@_) {
        $self->{version} = $_[0];
        $self->internal('version', $_[0]);
    }
    return $version;
}

sub base
{
    my $self = shift;
    my $base = $self->{base};
    if (@_) {
        $self->{base} = $_[0];
        $self->internal('base', $_[0]);
    }
    return $base;
}

sub add_module
{
    my $self = shift;
    my %args = @_;

    if ($args{prefix} eq '#default') {
        # no op
    } else {
        $args{prefix} =~ /^[a-zA-Z_][a-zA-Z0-9.\-_]*$/
            or croak "a namespace prefix should look like [a-z_][a-z0-9.\\-_]*";
    }

    $args{uri}
        or croak "a URI must be provided in a namespace declaration";

    $self->namespaces->{$args{prefix}} = $args{uri};
    $self->modules->{$args{uri}} = $args{prefix};
}

sub items
{
    my $self = shift;
    my $items = $self->{items};
    $items ?
        (wantarray ? @$items : $items) :
        (wantarray ? ()      : undef);
}

sub create_impl
{
    my $self = shift;
    my $version = shift;
    my $module = "Null";
    if ($version) {
        $module = $version;
        $module =~ s/\./_/g;
        $module = "V$module";
    }

    my $pkg;
    REQUIRE: {
        $pkg = "XML::RSS::LibXML::$module";
        eval {
            $pkg->require or die;
        };
        if (my $e = $@) {
            if ($e =~ /Can't locate/) {
                $module = "V1_0";
                $version = '1.0';
                redo REQUIRE;
            }
        }
    }
    return $pkg->new;
}

sub create_libxml
{
    my $self = shift;
    my $p    = XML::LibXML->new;
    my $opts = $self->{libxml_opts} || {};
    while (my($key, $value) = each %$opts) {
        $p->$key($value);
    }

    return $p;
}

sub parse
{
    my $self = shift;
    $self->reset();
    my $p    = $self->create_libxml;
    my $dom  = $p->parse_string($_[0]);
    $self->parse_dom($dom);
    $self;
}

sub parsefile
{
    my $self = shift;
    $self->reset();
    my $p    = $self->create_libxml;
    my $dom  = $p->parse_file($_[0]);
    $self->parse_dom($dom);
    $self;
}

sub parse_dom
{
    my $self = shift;
    my $dom  = shift;
    my $version = $self->guess_version_from_dom($dom);
    my $impl = $self->create_impl($version);
    $self->impl($impl);
    $self->impl->parse_dom($self, $dom);
    $self;
}

sub get_namespaces
{
    my $self = shift;
    my $node = shift;
    my %h = map {
        (($_->getLocalName() || '#default') => $_->getData)
    } $node->getNamespaces();

    if ($h{rdf} && ! $h{'#default'}) {
        $h{'#default'} = NS_RSS10;
    }

    return wantarray ? %h : \%h;
}

sub create_xpath_context
{
    my $self = shift;
    my $namespaces = shift || {};
    my $xc = XML::LibXML::XPathContext->new;
    foreach my $prefix (keys %$namespaces) {
        my $namespace = $namespaces->{$prefix};
        $xc->registerNs($prefix, $namespace);
    }
    return $xc;
}

sub guess_version_from_dom
{
    my $self = shift;
    my $dom = shift;
    my $root = $dom->documentElement();
    my $namespaces = $self->get_namespaces($root);
    # Check if we have non-default RSS namespace 
    my $rss10_prefix = 'rss10';
    while (my($prefix, $uri) = each %$namespaces) {
        if ($uri eq NS_RSS10) {
            $rss10_prefix = $prefix;
            last;
        }
    }

    if ($rss10_prefix && $rss10_prefix eq '#default') {
        $rss10_prefix = 'rss10';
        $namespaces->{$rss10_prefix} = NS_RSS10;
        $root->setNamespace(NS_RSS10, $rss10_prefix, 0);
    }

    keys %{$namespaces}; # reset iterator

    my $xc  = $self->create_xpath_context(
        # use the minimum required to guess
        $namespaces
    );

    my $version = 'UNKNOWN';

    # Test starting from the most likely candidate
    if (eval { $xc->findnodes('/rdf:RDF', $dom) }) {
        # 1.0 or 0.9.
        # Wrap up in evail, because we may not have registered rss10
        # namespace prefix
        if (eval { $xc->findnodes("/rdf:RDF/$rss10_prefix:channel", $dom) }) {
            $version = '1.0';
        } else {
            $version = '0.9';
        }
    } elsif (eval { $xc->findnodes('/rss', $dom) }) {
        # 0.91 or 2.0 -ish
        $version = $xc->findvalue('/rss/@version', $dom);
    } else {
        die "Failed to guess version";
    }
    $version = "$1.0" if $version =~ /^(\d)$/;
    return $version;
}

sub as_string
{
    my $self = shift;
    my $format = @_ ? $_[0] : 1;
    my $impl = $self->create_impl($self->output || $self->version);
    $self->impl($impl);
    $self->impl->as_string($self, $format);
}

sub save
{   
    my $self = shift;
    my $file = shift;
    
    open(OUT, ">$file") or Carp::croak("Cannot open file $file for write: $!");
    print OUT $self->as_string;
    close(OUT);
}

1;

__END__

=head1 NAME

XML::RSS::LibXML - XML::RSS with XML::LibXML

=head1 SYNOPSIS

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

=head1 DESCRIPTION

XML::RSS::LibXML uses XML::LibXML (libxml2) for parsing RSS instead of XML::RSS'
XML::Parser (expat), while trying to keep interface compatibility with XML::RSS.

XML::RSS is an extremely handy tool, but it is unfortunately not exactly the
most lean or efficient RSS parser, especially in a long-running process.
So for a long time I had been using my own version of RSS parser to get the
maximum speed and efficiency - this is the re-packaged version of that module,
such that it adheres to the XML::RSS interface.

Use this module when you have severe performance requirements working with
RSS files.

=head1 VERSION 0.3105

The original XML::RSS has been evolving in fairly rapid manner lately,
and that meant that there were a lot of features to keep up with.
To keep compatibility, I've had to pretty much rewrite the module from
ground up.

Now XML::RSS::LibXML is *almost* compatible with XML::RSS. If there are
problems, please send in bug reports (or more preferrably, patches ;)

=head1 COMPATIBILITY

There seems to be a bit of confusion as to how compatible XML::RSS::LibXML 
is with XML::RSS: XML::RSS::LibXML is B<NOT> 100% compatible with XML::RSS. 
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

=head1 PARSED STRUCTURE

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

See L<XML::RSS::LibXML::MagicElement|XML::RSS::LibXML::MagicElement> for details.

=head1 METHODS

=head2 new(%args)

Creates a new instance of XML::RSS::LibXML. You may specify a version or an
XML base in the constructor args to control which output format as_string()
will use.

  XML::RSS::LibXML->new(version => '1.0', base => 'http://example.com/');

The XML base will be included only in RSS 2.0 output. You can also specify the
encoding that you expect this RSS object to use when creating an RSS string

  XML::RSS::LiBXML->new(encoding => 'euc-jp');

=head2 parse($string)

Parse a string containing RSS.

=head2 parsefile($filename)

Parse an RSS file specified by $filename

=head2 channel(%args)

=head2 add_item(%args)

=head2 image(%args)

=head2 textinput(%args)

These methods are used to generate RSS. See the documentation for XML::RSS
for details. Currently RSS version 0.9, 1.0, and 2.0 are supported.

Additionally, add_item takes an extra parameter, "mode", which allows
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

=head2 as_string($format)

Return the string representation of the parsed RSS. If $format is true, this
flag is passed to the underlying XML::LibXML object's toString() method.

By default, $format is true.

=head2 add_module(uri =E<gt> $uri, prefix =E<gt> $prefix)

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

=head2 save($file)

Saves the RSS to a file

=head2 items()

Syntactic sugar to allow statement like this:

  foreach my $item ($rss->items) {
    ...
  }

Instead of 

  foreach my $item (@{$rss->{items}}) {
    ...
  }

In scalar context, returns the reference to the list of items.

=head2 create_libxml()

Creates, configures, and returns an XML::LibXML object. Used by C<parse()> to
instantiate the parser used to parse the feed.

=head1 PERFORMANCE

Here's a simple benchmark using benchmark.pl in this distribution,
using XML::RSS 1.29_02 and XML::RSS::LibXML 0.30

  daisuke@beefcake XML-RSS-LibXML$ perl -Mblib tools/benchmark.pl t/data/rss20.xml 
  XML::RSS -> 1.29_02
  XML::RSS::LibXML -> 0.30
               Rate        rss rss_libxml
  rss        25.6/s         --       -67%
  rss_libxml 78.1/s       205%         --

=head1 CAVEATS

- Only first level data under E<lt>channelE<gt> and E<lt>itemE<gt> tags are
examined. So if you have complex data, this module will not pick it up.
For most of the cases, this will suffice, though.

- Namespace for namespaced attributes aren't properly parsed as part of 
the structure.  Hopefully your RSS doesn't do something like this:

  <foo bar:baz="whee">

You won't be able to get at "bar" in this case:

  $xml->{foo}{baz}; # "whee"
  $xml->{foo}{bar}{baz}; # nope

- Some of the structures will need to be handled via 
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

- Some elements such as permaLink elements are not really parsed
such that it can be serialized and parsed back and force. I could fix
this, but that would break some compatibility with XML::RSS

=head1 TODO

Tests. Currently tests are simply stolen from XML::RSS. It would be nice
to have tests that do more extensive testing for correctness

=head1 SEE ALSO

L<XML::RSS|XML::RSS>, L<XML::LibXML|XML::LibXML>, L<XML::LibXML::XPathContext>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2007 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>, Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>. All rights reserved.

Many tests were shamelessly borrowed from XML::RSS 1.29_02

Development partially funded by Brazil, Ltd. E<lt>http://b.razil.jpE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut



