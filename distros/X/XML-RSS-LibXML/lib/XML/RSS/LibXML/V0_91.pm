# $Id$
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::V0_91;
use strict;
use warnings;
use base qw(XML::RSS::LibXML::ImplBase);
use DateTime::Format::W3CDTF;
use DateTime::Format::Mail;

my %DcElements = (
    (map { ("dc:$_" => [ { module => 'dc', element => $_ } ]) }
        qw(language rights date publisher creator title subject description contributer type format identifier source relation coverage)),
);  
            
my %SynElements = (
    (map { ("syn:$_" => [ { module => 'syn', element => $_ } ]) }
        qw(updateBase updateFrequency updatePeriod)),
);  

my $format_dates = sub {
    my $v = eval {
        DateTime::Format::Mail->format_datetime(
            DateTime::Format::W3CDTF->parse_datetime($_[0])
        );
    };
    if ($v && ! $@) {
        $_[0] = $v;
    }
};

my %ChannelElements = (
    %DcElements,
    %SynElements,
    (map { ($_ => [ $_ ]) } qw(title link description)),
    language => [ { module => 'dc', element => 'language' }, 'language' ],
    copyright => [ { module => 'dc', element => 'rights' }, 'copyright' ],
    pubDate   => {
        candidates => [ 'pubDate', { module => 'dc', element => 'date' } ],
        callback   => $format_dates,
    },
    lastBuildDate => {
        candidates => [ { module => 'dc', element => 'date' }, 'lastBuildDate' ],
        callback   => $format_dates,
    },
    docs => [ 'docs' ],
    managingEditor => [ { module => 'dc', element => 'publisher' }, 'managingEditor' ],
    webMaster => [ { module => 'dc', element => 'creator' }, 'webMaster' ],
    category => [ { module => 'dc', element => 'category' }, 'category' ],
    generator => [ { module => 'dc', element => 'generator' }, 'generator' ],
    ttl => [ { module => 'dc', element => 'ttl' }, 'ttl' ],
    rating => [ 'rating' ],
);
delete $ChannelElements{'dc:creator'};

my %ItemElements = (
    %DcElements,
    map { ($_ => [$_]) }
        qw(title link description author category comments pubDate)
);

my %ImageElements = (
    (map { ($_ => [$_]) } qw(title url link description width height)),
    %DcElements,
);

my %TextInputElements = (
    (map { ($_ => [$_]) } qw(title link description name)),
    %DcElements
);

sub definition 
{
    return +{
        channel => {
            title          => '',
            copyright      => undef,
            description    => '',
            docs           => undef,
            language       => undef,
            lastBuildDate  => undef,
            'link'         => '',
            managingEditor => undef,
            pubDate        => undef,
            rating         => undef,
            webMaster      => undef,
        },
        image => bless({
            title       => undef,
            url         => undef,
            'link'      => undef,
            width       => undef,
            height      => undef,
            description => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
        skipDays  => {day  => undef,},
        skipHours => {hour => undef,},
        textinput => bless({
            title       => undef,
            description => undef,
            name        => undef,
            'link'      => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
    }
}

sub accessor_definition
{
    return +{
        channel => {
            "title"          => [1, 100],
            "description"    => [1, 500],
            "link"           => [1, 500],
            "language"       => [1, 5],
            "rating"         => [0, 500],
            "copyright"      => [0, 100],
            "pubDate"        => [0, 100],
            "lastBuildDate"  => [0, 100],
            "docs"           => [0, 500],
            "managingEditor" => [0, 100],
            "webMaster"      => [0, 100],
        },
        image => {
            "title"       => [1, 100],
            "url"         => [1, 500],
            "link"        => [0, 500],
            "width"       => [0, 144],
            "height"      => [0, 400],
            "description" => [0, 500]
        },
        item => {
            "title"       => [1, 100],
            "link"        => [1, 500],
            "description" => [0, 500]
        },
        textinput => {    
            "title"       => [1, 100],
            "description" => [1, 500],
            "name"        => [1, 20],
            "link"        => [1, 500]
        },
        skipHours => {"hour" => [1, 23]},
        skipDays  => {"day"  => [1, 10]}
    }
}

sub parse_dom
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    $c->reset;
    $c->version('0.91');
    $c->encoding($dom->encoding);
    $self->parse_namespaces($c, $dom);
    $self->parse_channel($c, $dom);
    $self->parse_items($c, $dom);
}

sub parse_channel
{
    my ($self, $c, $dom) = @_;

    my $xc = $c->create_xpath_context($c->{namespaces});

    my ($root) = $xc->findnodes('/rss/channel', $dom);
    my %h = $self->parse_children($c, $root);

    foreach my $type (qw(day hour)) {
        my $field = 'skip' . ucfirst($type) . 's';
        if (my $skip = delete $h{$field}) {
            $c->$field(%$skip);
        }
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
    my $xpath   = '/rss/channel/item';
    foreach my $item ($xc->findnodes($xpath, $dom)) {
        my $i = $self->parse_children($c, $item);
        $self->add_item($c, $i);
    }
}

sub create_dtd
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    my $dtd = $dom->createExternalSubset(
        'rss',
        '-//Netscape Communications//DTD RSS 0.91//EN',
        'http://my.netscape.com/publish/formats/rss-0.91.dtd'
    );
    $dom->setInternalSubset($dtd);
}

sub create_rootelement
{
    my ($self, $c, $dom) = @_;

    my $root = $dom->createElement('rss');
    $root->setAttribute(version => '0.91');
    $dom->setDocumentElement($root);
}

sub create_channel
{
    my ($self, $c, $dom) = @_;

    my $root = $dom->getDocumentElement();
    my $channel = $dom->createElement('channel');
    $self->create_element_from_spec($c->channel, $dom, $channel, \%ChannelElements);

    if (my $image = $c->image) {
        if (! UNIVERSAL::isa($image, 'XML::RSS::LibXML::ElementSpec')) {
            my $inode;

            $inode = $dom->createElement('image');
            $self->create_element_from_spec($image, $dom, $inode, \%ImageElements);
            $self->create_extra_modules($image, $dom, $inode, $c->namespaces);
            $channel->appendChild($inode);
        }
    }

    if (my $textinput = $c->textinput) {
        if (! UNIVERSAL::isa($textinput, 'XML::RSS::LibXML::ElementSpec')) {
            my $inode;

            $inode = $dom->createElement('textinput');
            $self->create_element_from_spec($textinput, $dom, $inode, \%TextInputElements);
            $self->create_extra_modules($textinput, $dom, $inode, $c->namespaces);
            $channel->appendChild($inode);
        }
    }

    foreach my $type (qw(day hour)) {
        my $field = 'skip' . ucfirst($type) . 's';
        my $skip = $c->$field;
        if ($skip && defined $skip->{$type}) {
            my $sd = $dom->createElement($field);
            my $d  = $dom->createElement($type);
            $d->appendChild($dom->createTextNode($skip->{$type}));
            $sd->appendChild($d);
            $channel->appendChild($sd);
        }
    }
    $root->appendChild($channel);
}

sub create_items
{
    my ($self, $c, $dom) = @_;

    my ($channel) = $dom->findnodes('/rss/channel');
    foreach my $i ($c->items) {
        my $item = $dom->createElement('item');
        $self->create_element_from_spec($i, $dom, $item, \%ItemElements);

        $channel->appendChild($item);
    }
}

1;
