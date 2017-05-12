# $Id$
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::V1_0;
use strict;
use warnings;
use base qw(XML::RSS::LibXML::ImplBase);
use XML::RSS::LibXML::Namespaces qw(NS_RSS10 NS_RDF);
use DateTime::Format::W3CDTF;
use DateTime::Format::Mail;

sub definition
{
    return {
        channel => {
            title       => '',
            description => '',
            link        => '',
        },
        image => bless ({
            title => undef,
            url   => undef,
            link  => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
        textinput => bless ({
            title       => undef,
            description => undef,
            name        => undef,
            link        => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
        skipDays => bless ({ day => undef }, 'XML::RSS::LibXML::ElementSpec' ),
        skipHours => bless ({ hour => undef }, 'XML::RSS::LibXML::ElementSpec' ),
    };
}

sub parse_dom
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    $c->reset;
    $c->version('1.0');
    $c->encoding($dom->encoding);
    $self->parse_namespaces($c, $dom);

    $c->internal('prefix', 'rss10');
    # Check if we have non-default RSS namespace
    my $namespaces = $c->namespaces;
    while (my($prefix, $uri) = each %$namespaces) {
        if ($uri eq NS_RSS10 && $prefix ne '#default') {
            $c->internal('prefix', $prefix);
            last;
        }
    }

    $dom->getDocumentElement()->setNamespace(NS_RSS10, $c->internal('prefix'), 0);

    $self->parse_channel($c, $dom);
    $self->parse_items($c, $dom);
    $self->parse_misc_simple($c, $dom);
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

sub parse_channel
{
    my ($self, $c, $dom) = @_;

    my $namespaces = $c->namespaces;
    my $xc = $c->create_xpath_context($namespaces);
    my $xpath = sprintf('/rdf:RDF/%s:channel', $c->internal('prefix'));
    my ($root) = $xc->findnodes($xpath, $dom);
    my %h = $self->parse_children($c, $root);
    if (delete $h{taxo}) {
        $self->parse_taxo($c, $dom, \%h, $root);
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
    my $xc      = $c->create_xpath_context(scalar $c->namespaces);
    my $xpath   = sprintf('/rdf:RDF/%s:item', $c->internal('prefix'));
    foreach my $item ($xc->findnodes($xpath, $dom)) {
        my $i = $self->parse_children($c, $item);
        if (delete $i->{taxo}) {
            $self->parse_taxo($c, $dom, $i, $item);
        }
        $self->add_item($c, $i);
    }
}

sub create_rootelement
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    my $e = $dom->createElementNS(NS_RSS10, 'RDF');
    $dom->setDocumentElement($e);
    $e->setNamespace(NS_RDF, 'rdf', 1);
    $c->add_module(prefix => 'rdf', uri => NS_RDF);
}

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
    'dc:language' => [
        { module => 'dc', element => 'language' },
        'language'
    ],
    'dc:rights' => [
        { module => 'dc', element => 'rights' },
        'copyright'
    ],
    'dc:publisher' => [
        { module => 'dc', element => 'publisher' },
        'managingEditor'
    ],
    'dc:creator' => [
        { module => 'dc', element => 'creator' },
        'webMaster'
    ],
    (map { ("dc:$_" => [ { module => 'dc', element => $_ } ]) }
        qw(title subject description contributer type format identifier source relation coverage)),
);

my %SynElements = (
    (map { ("syn:$_" => [ { module => 'syn', element => $_ } ]) }
        qw(updateBase updateFrequency updatePeriod)),
);

my %ChannelElements = (
    %DcElements,
    %SynElements,
    (map { ($_ => [ $_ ]) } qw(title link description)),
);

my %ItemElements = (
    (map { ($_ => [$_]) } qw(title link description)),
    %DcElements
);

my %ImageElements = (
    (map { ($_ => [$_]) } qw(title url link)),
    %DcElements,
);

my %TextInputElements = (
    (map { ($_ => [$_]) } qw(title link description name)),
    %DcElements
);

sub create_dom
{
    my ($self, $c) = @_;

    my $dom = $self->SUPER::create_dom($c);
    my $root = $dom->getDocumentElement();
    my $xc = $c->create_xpath_context(scalar $c->namespaces);
    my($channel) = $xc->findnodes('/rdf:RDF/channel', $dom);

    if (my $image = $c->image) {
        my $inode;

        $inode = $dom->createElement('image');
        $inode->setAttribute('rdf:resource', $image->{url}) if $image->{url};
        $channel->appendChild($inode);

        $inode = $dom->createElement('image');
        $inode->setAttribute('rdf:resource', $image->{url}) if $image->{url};
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

sub create_channel
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;
    my $root = $dom->getDocumentElement();

    my $channel = $dom->createElement('channel');
    if ($c->{channel} && $c->{channel}{about}) {
        $channel->setAttribute('rdf:about', $c->{channel}{about});
    } elsif ($c->{channel} && $c->{channel}{link}) {
        $channel->setAttribute('rdf:about', $c->{channel}{link});
    }
    $root->appendChild($channel);
    $self->create_taxo($c->{channel}, $dom, $channel);
    $self->create_element_from_spec($c->channel, $dom, $channel, \%ChannelElements);
}

sub create_items
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;
    my $root = $dom->getDocumentElement();

    my $node;
    my $items = $dom->createElement('items');
    my $seq   = $dom->createElement('rdf:Seq');
    foreach my $item ($c->items) {
        my $about = $item->{about} || $item->{link};
        $node = $dom->createElement('rdf:li');
        $node->setAttribute('rdf:resource', $about) if $about;

        $seq->appendChild($node);

        $node = $dom->createElement('item');
        $node->setAttribute('rdf:about', $about) if $about;
        $self->create_element_from_spec($item, $dom, $node, \%ItemElements);
        $self->create_extra_modules($item, $dom, $node, $c->namespaces);
        $self->create_taxo($item, $dom, $node);
        $root->appendChild($node);
    }
    $items->appendChild($seq);

    my $xc = $c->create_xpath_context(scalar $c->namespaces);
    my($channel) = $xc->findnodes('/rdf:RDF/channel', $dom);
    $channel->appendChild($items);
}

1;
