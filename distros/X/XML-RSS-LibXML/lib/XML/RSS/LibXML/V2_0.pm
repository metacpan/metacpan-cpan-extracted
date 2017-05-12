# $Id$
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::V2_0;
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
); 

my %ItemElements = (
    %DcElements,
    enclosure => ['enclosure'],
    map { ($_ => [$_]) }
        qw(title link description author category comments pubDate)
);

my %ImageElements = (
    (map { ($_ => [$_]) } qw(title url link width height description)),
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
            'link'         => '',
            description    => '',
            language       => undef,
            copyright      => undef,
            managingEditor => undef,
            webMaster      => undef,
            pubDate        => undef,
            lastBuildDate  => undef,
            category       => undef,
            generator      => undef,
            docs           => undef,
            cloud          => '',
            ttl            => undef,
            image          => '',
            textinput      => '',
            skipHours      => '',
            skipDays       => '',
        },
        image => bless ({
            title       => undef,
            url         => undef,
            'link'      => undef,
            width       => undef,
            height      => undef,
            description => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
        skipDays  => bless ({
            day => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
        skipHours => bless ({
            hour => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
        textinput => bless ({
            title       => undef,
            description => undef,
            name        => undef,
            'link'      => undef,
        }, 'XML::RSS::LibXML::ElementSpec'),
    };
}

sub parse_dom
{
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;

    $c->reset;
    $c->version('2.0');
    $c->encoding($dom->encoding);
    $self->parse_base($c, $dom);
    $self->parse_namespaces($c, $dom);
    $self->parse_channel($c, $dom);
    $self->parse_items($c, $dom);
    $self->parse_misc_simple($c, $dom);
}


sub parse_channel
{
    my ($self, $c, $dom) = @_;

    my $xc = $c->create_xpath_context($c->{namespaces});

    my ($root) = $xc->findnodes('/rss/channel', $dom);
    my %h = $self->parse_children($c, $root, './*[name() != "item"]');

    foreach my $type (qw(day hour)) {
        my $field = 'skip' . ucfirst($type) . 's';
        if (my $skip = delete $h{$field}) {
            if (ref $skip ne 'HASH') {
#                warn "field $field has invalid entry (does this RSS validate?)";
            } elsif (! UNIVERSAL::isa($skip, 'XML::RSS::LibXML::ElementSpec')) {
                $c->$field(UNIVERSAL::isa($skip, 'XML::RSS::LibXML::MagicElement') ? $skip : %$skip);
            }
        }
    }

    foreach my $field (qw(textinput image)) {
        if (my $v = $h{$field}) {
            if (ref $v ne 'HASH') {
#                warn "field $field has invalid entry (does this RSS validate?)";
            } elsif (! UNIVERSAL::isa($v, 'XML::RSS::LibXML::ElementSpec')) {
                $c->$field(UNIVERSAL::isa($v, 'XML::RSS::LibXML::MagicElement') ? $v : %$v);
            }
        }
    }
    $c->channel(%h);
}

sub parse_items
{
    my ($self, $c, $dom) = @_;
    my @items;
    my $version = $c->version;
    my $xc      = $c->create_xpath_context($c->{namespaces});
    my $xpath   = '/rss/channel/item';
    foreach my $item ($xc->findnodes($xpath, $dom)) {
        my $i = $self->parse_children($c, $item);
        $self->add_item($c, $i);
    }
}

sub parse_misc_simple
{
    my ($self, $c, $dom) = @_;

    my $xc = $c->create_xpath_context($c->{namespaces});
    foreach my $node ($xc->findnodes('/rss/*[name() != "channel" and name() != "item"]', $dom)) {
        my $h = $self->parse_children($c, $node);
        my $name = $node->localname;
        my $prefix = $node->getPrefix();

        $name = 'textinput' if $name eq 'textInput';

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

sub create_dom
{
    my ($self, $c) = @_;

    my $dom = $self->SUPER::create_dom($c);
    my $root = $dom->getDocumentElement();
    my $xc = $c->create_xpath_context(scalar $c->namespaces);
    my($channel) = $xc->findnodes('/rss/channel', $dom);

    if (my $image = $c->image) {
        my $inode = $dom->createElement('image');
        $self->create_element_from_spec($image, $dom, $inode, \%ImageElements);
        $self->create_extra_modules($image, $dom, $inode, $c->namespaces);
        $channel->appendChild($inode);
    }

    if (my $textinput = $c->textinput) {
        my $inode = $dom->createElement('textInput');
        $self->create_element_from_spec($textinput, $dom, $inode, \%TextInputElements);
        $self->create_extra_modules($textinput, $dom, $inode, $c->namespaces);
        $channel->appendChild($inode);
    }

    return $dom;
}

sub create_rootelement
{
    my ($self, $c, $dom) = @_;
    my $root = $dom->createElement('rss');
    $root->setAttribute(version => '2.0');
    if (my $base = $c->base) {
        $root->setAttribute('xml:base' => $base);
    }
    $dom->setDocumentElement($root);
}

sub create_channel
{
    my ($self, $c, $dom) = @_;

    my $root = $dom->getDocumentElement();
    my $channel = $dom->createElement('channel');

    $self->create_element_from_spec($c->channel, $dom, $channel, \%ChannelElements);

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
        $self->create_extra_modules($i, $dom, $item, $c->namespaces);
        my $guid = $i->{guid};
        if (defined $guid) {
            my $guid_element = $dom->createElement('guid');
            if (eval { $guid->isa('XML::RSS::LibXML::MagicElement') }) {
                my $isperma = 'true';
                if (! $guid->{isPermaLink} || $guid->{isPermaLink} ne 'true') {
                    $isperma = 'false';
                }
                $guid_element->setAttribute(isPermaLink => $isperma);
                $guid_element->appendChild($dom->createTextNode($guid->toString));
            } else {
                $guid_element->setAttribute(isPermaLink => "false");
                $guid_element->appendChild($dom->createTextNode($guid));
            }
            $item->appendChild($guid_element);
        }

        $channel->appendChild($item);
    }
}

1;
