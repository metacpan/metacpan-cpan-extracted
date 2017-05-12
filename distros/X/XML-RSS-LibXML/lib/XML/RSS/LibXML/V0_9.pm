# $Id$
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::V0_9;
use strict;
use base qw(XML::RSS::LibXML::ImplBase);
use Carp qw(croak);
use XML::RSS::LibXML::Namespaces qw(NS_RSS09 NS_RDF);

my $format_dates = sub {
    my $v = eval {
        DateTime::Format::W3CDTF->format_datetime(
            DateTime::Format::Mail->parse_datetime($_[0])
        );
    };
    if ($v && ! $@) {
        $_[0] = $v;
    }
};

my %DcElements = (
    'dc:date' => {
        candidates => [
            { module => 'dc', element => 'date' },
            'pubDate',
            'lastBuildDate',
        ],  
        callback => $format_dates
    },  
    (map { ("dc:$_" => [ { module => 'dc', element => $_ } ]) }
        qw(language rights publisher creator title subject description contributer type format identifier source relation coverage)),
);

my %ImageElements = (
    (map { ($_ => [$_]) } qw(title url link)),
    %DcElements,
);

my %TextInputElements = (
    (map { ($_ => [$_]) } qw(title link description name)),
    %DcElements
);

sub definition
{
    return {
        channel => {
            title       => '',
            description => '',
            link        => '',
        },
        image => bless({
            title => undef,
            url   => undef,
            link  => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
        textinput => bless({
            title       => undef,
            description => undef,
            name        => undef,
            link        => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
    },
}

sub accessor_definition
{
    return +{
        channel => {
            "title"       => [1, 40],
            "description" => [1, 500],
            "link"        => [1, 500]
        },
        image => {
            "title" => [1, 40],
            "url"   => [1, 500],
            "link"  => [1, 500]
        },
        item => {
            "title" => [1, 100],
            "link"  => [1, 500]
        },
        textinput => {
            "title"       => [1, 40],
            "description" => [1, 100],
            "name"        => [1, 500],
            "link"        => [1, 500]
        }
    }
}

sub parse_dom
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    $c->reset;
    $c->version(0.9);
    $c->encoding($dom->encoding);
    $self->parse_namespaces($c, $dom);
    $c->internal('prefix', 'rss09');
    # Check if we have non-default RSS namespace
    my $namespaces = $c->namespaces;
    while (my($prefix, $uri) = each %$namespaces) {
        if ($uri eq NS_RSS09 && $prefix ne '#default') {
            $c->internal('prefix', $prefix);
            last;
        }
    }

    $dom->getDocumentElement()->setNamespace(NS_RSS09, $c->internal('prefix'), 0);
    $self->parse_channel($c, $dom);
    $self->parse_items($c, $dom);
    $self->parse_misc_simple($c, $dom);
}

sub parse_namespaces
{
    my ($self, $c, $dom) = @_;

    $self->SUPER::parse_namespaces($c, $dom);

    my $namespaces = $c->namespaces;
    while (my($prefix, $uri) = each %$namespaces) {
        if ($uri eq NS_RSS09) {
            
        }
    }
}

sub parse_channel
{
    my ($self, $c, $dom) = @_;

    my $xc = $c->create_xpath_context($c->{namespaces});

    my ($root) = $xc->findnodes('/rdf:RDF/rss09:channel', $dom);
    my %h = $self->parse_children($c, $root);
    foreach my $field (qw(textinput image)) {
        delete $h{$field};
#        if (my $v = $h{$field}) {
#            $c->$field(UNIVERSAL::isa($v, 'XML::RSS::LibXML::MagicElement') ? $v : %$v);
#        }
    }
    $c->channel(%h);
}

sub parse_items
{
    my $self    = shift;
    my $c       = shift;
    my $dom     = shift;

    my @items;

    my $version = $c->version;
    my $xc      = $c->create_xpath_context($c->{namespaces});
    my $xpath   = '/rdf:RDF/rss09:item';
    foreach my $item ($xc->findnodes($xpath, $dom)) {
        my $i = $self->parse_children($c, $item);
        $self->add_item($c, $i);
    }
}

sub parse_misc_simple
{
    my ($self, $c, $dom) = @_;

    my $xc = $c->create_xpath_context($c->{namespaces});
    foreach my $node ($xc->findnodes('/rdf:RDF/*[name() != "channel" and name() != "item"]', $dom)) {
        my $h = $self->parse_children($c, $node);
        my $name = $node->localname;
        $name = 'textinput' if $name eq 'textInput';
        my $prefix = $node->getPrefix();
        if ($prefix) {
            $c->{$prefix} ||= {};
            $self->store_element($c->{$prefix}, $name, $h);

            # XML::RSS requires us to allow access to elements both from
            # the prefix and the namespace
            $c->{$c->{namespaces}{$prefix}} ||= {};
            $self->store_element($c->{$c->{namespaces}{$prefix}}, $name, $h);
        } else {
            $self->store_element($c, $name, $h);
        }
    }
}

sub validate_item
{
    my $self = shift;
    my $c    = shift;
    my $h    = shift;

    # make sure we have a title and link
    croak "title and link elements are required"
      unless (defined $h->{title} && defined $h->{'link'});

    # check string lengths
    croak "title cannot exceed 100 characters in length"
      if (length($h->{title}) > 100);
    croak "link cannot exceed 500 characters in length"
      if (length($h->{'link'}) > 500);
    croak "description cannot exceed 500 characters in length"
      if (exists($h->{description})
        && length($h->{description}) > 500);

    # make sure there aren't already 15 items
    croak "total items cannot exceed 15 " if (@{$c->items} >= 15);
}

sub create_dom
{
    my ($self, $c) = @_;

    my $dom = $self->SUPER::create_dom($c);
    my $xc = $c->create_xpath_context($c->namespaces);
    my ($channel) = $xc->findnodes('/rdf:RDF/channel', $dom);
    my $root = $dom->getDocumentElement();
    if (my $image = $c->image) {
        my $inode;

        $inode = $dom->createElement('image');
        $inode->setAttribute('rdf:resource', $image->{url}) if defined $image->{url};
        $channel->appendChild($inode);

        $inode = $dom->createElement('image');
        $inode->setAttribute('rdf:resource', $image->{url}) if defined $image->{url};
        $self->create_element_from_spec($image, $dom, $inode, \%ImageElements);
        $self->create_extra_modules($image, $dom, $inode, $c->namespaces);
        $root->appendChild($inode);
    }

    if (my $textinput = $c->textinput) {
        my $inode;

        $inode = $dom->createElement('textinput');
        $inode->setAttribute('rdf:resource', $textinput->{link}) if $textinput->{link};
        $channel->appendChild($inode);

        $inode = $dom->createElement('textinput');
        $inode->setAttribute('rdf:resource', $textinput->{link}) if $textinput->{link};
        $self->create_element_from_spec($textinput, $dom, $inode, \%TextInputElements);
        $self->create_extra_modules($textinput, $dom, $inode, $c->namespaces);
        $root->appendChild($inode);
    }

    return $dom;
}

sub create_rootelement
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    my $e = $dom->createElementNS(NS_RSS09, 'RDF');
    $dom->setDocumentElement($e);
    $e->setNamespace(NS_RDF, 'rdf', 1);
    $c->add_module(prefix => 'rdf', uri => NS_RDF);
}

sub create_channel
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;
    my $root = $dom->getDocumentElement();

    my $channel = $dom->createElement('channel');
    $root->appendChild($channel);

    my $node;
    foreach my $p (qw(title link description)) {
        my $text = $c->{channel}{$p};
        next unless defined $text;
        $node = $dom->createElement($p);
        $node->appendText($c->{channel}{$p});
        $channel->appendChild($node);
    }
}

sub create_items
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;
    my $root = $dom->getDocumentElement();

    foreach my $i ($c->items) {
        my $item = $self->create_item($c, $dom, $i);
        $root->appendChild($item);
    }
}

sub create_item
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;
    my $i    = shift;

    my $item = $dom->createElement('item');
    my $node;
    foreach my $e (qw(title link)) {
        $node = $dom->createElement($e);
        $node->appendText($i->{$e});
        $item->addChild($node);
    }
    return $item;
}

1;
