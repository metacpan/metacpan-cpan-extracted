# $Id$
#
# Copyright (c) 2005-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package XML::RSS::LibXML::ImplBase;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Carp qw(croak);
use XML::RSS::LibXML::MagicElement;
use XML::RSS::LibXML::Namespaces;

sub rss_accessor
{
    my $self = shift;
    my $name = shift;
    my $c    = shift;

    if (! exists $c->{$name}) {
        croak "Unregistered entity: Can't access $name field in object of class " . ref($self);
    }

    my $ret;


    if (@_ == 1) {
        if (ref $_[0]) { #  eval { $_[0]->isa('XML::RSS::LibXML::MagicElement') }) {
            $ret = $c->{$name};
            $c->{$name} = $_[0];
        } else {
            $ret = $c->{$name}->{$_[0]};
            if (ref $ret && eval { $ret->isa('XML::RSS::LibXML::ElementSpec') }) {
                $ret = undef;
            }
        }
    } elsif (@_ > 1) {
        my %hash = @_;
        my $definition = $self->accessor_definition;

        foreach my $key (keys %hash) {
            $self->validate_accessor($definition, $name, $key, $hash{$key}) if $definition;

            if ($key =~ /^(?:rdf|dc|syn|taxo|admin|content|cc)$/) {
                if (! exists $c->namespaces->{$key}) {
                    $c->add_module(prefix => $key, uri => XML::RSS::LibXML::Namespaces::lookup_uri($key));
                }
            }

#            $self->store_element($c, $c->{$name}, $key, $hash{$key});
            $self->set_value($c, $name, $key, $hash{$key});
            if (my $uri = $c->namespaces->{$key}) {
                $self->set_value($c, $name, $uri, $hash{$key});
#                $self->store_element($c, $c->{$name}, $uri, $hash{$key});
            }
        }
        $ret = $c->{$name};
    } else {
        $ret = $c->{$name};
        if (ref $ret && eval { $ret->isa('XML::RSS::LibXML::ElementSpec') }) {
            $ret = undef;
        }
    }

    return $ret;
}

sub definition {}
sub accessor_definition { }

sub validate_accessor
{
    my ($self, $definition, $prefix, $key, $value) = @_;

    if (! defined $value) {
        croak "Undefined value in XML::RSS::LibXML::validate_accessor";
    }
    my $spec = $definition->{$prefix}{$key};
    croak "$key cannot exceed " . $spec->[1] . " characters in length"
        if defined $spec->[1] && length($value) > $spec->[1];
}

sub set_value
{
    my ($self, $c, $prefix, $key, $value) = @_;

    if (eval { $c->{$prefix}->isa('XML::RSS::LibXML::ElementSpec') }) {
        $c->{$prefix} = +{ %{ $c->{$prefix} } };
    }
    $c->{$prefix}{$key} = $value;
}

sub validate_item { }

sub channel   { shift->rss_accessor('channel', @_) }
sub image     { shift->rss_accessor('image', @_) }
sub textinput { shift->rss_accessor('textinput', @_) }
sub skipDays  { shift->rss_accessor('skipDays', @_) }
sub skipHours { shift->rss_accessor('skipHours', @_) }

sub reset
{
    my ($self, $c) = @_;

    # internal hash
    $c->_internal({});

    # init num of items to 0
    $c->num_items(0);

    # initialize items
    $c->{items} = [];

    my $definition = $self->definition;
    while (my ($k, $v) = each(%$definition)) {
        $c->{$k} = +{%{$v}};
        bless($c->{$k}, 'XML::RSS::LibXML::ElementSpec')
            if (ref($v) eq 'XML::RSS::LibXML::ElementSpec');
    }

    return;
}

sub store_element
{
    my ($self, $container, $name, $value) = @_;

    my $v = $container->{$name};
    if (! $v || eval { $v->isa('XML::RSS::LibXML::ElementSpec') }) {
        $container->{$name} = $value;
    } elsif (ref($v) eq 'ARRAY') {
        push @$v, $value;
    } else {
        $container->{$name} = [ $v, $value ];
    }
}

sub parse_dom { }

sub parse_base
{
    my ($self, $c, $dom) = @_;
    my $xc = $c->create_xpath_context(scalar $c->namespaces);
    if (my $b = $xc->findvalue('/rss/@xml:base', $dom)) {
        $c->base($b);
    } else {
        $c->base(undef);
    }
}

sub parse_namespaces
{   
    my ($self, $c, $dom) = @_;

    my %namespaces = $self->parse_namespaces_recurse($c, $dom->documentElement());

    while (my ($prefix, $uri) = each %namespaces) {
        $c->add_module(prefix => $prefix, uri => $uri);
    }
}

sub parse_namespaces_recurse
{
    my ($self, $c, $parent) = @_;

    my %namespaces;
    foreach my $node ($parent->findnodes('./*')) {
        my %h = $self->parse_namespaces_recurse($c, $node);
        %namespaces = (%namespaces, %h);
    }
    return (%namespaces, $c->get_namespaces($parent));
}

sub parse_taxo
{
    my ($self, $c, $dom, $container, $parent) = @_;

    my $xc = $c->create_xpath_context(scalar $c->namespaces);
    my @nodes = $xc->findnodes('taxo:topics/rdf:Bag/rdf:li', $parent);
    return unless @nodes;

    my $uri = XML::RSS::LibXML::Namespaces::lookup_uri('taxo');
    if (! exists $c->namespaces->{taxo}) {
        $c->add_module(prefix => 'taxo', uri => $uri);
    }

    $container->{taxo} ||= [];
    foreach my $p (@nodes) {
        push @{ $container->{taxo} }, $p->findvalue('@resource');
    }
    $container->{$uri} = $container->{taxo};
}
    
sub parse_misc_simple
{
}

sub may_have_children {
    qw(channel item image textinput skipHours skipDays)
}

sub parse_children
{
    my ($self, $c, $node, $xpath) = @_;

    my %h;

    $xpath ||= './*';
    my $xc = $c->create_xpath_context(scalar $c->namespaces);
    foreach my $child ($xc->findnodes($xpath, $node)) {
        my $prefix = $child->getPrefix();
        my $name   = $child->localname();
        # XXX - this is probably the only case where we need to explicitly
        # normalize a name
        $name = 'textinput' if ($name eq 'textInput');
        my $val    = undef;
        if ($child->findnodes('./*')) {
            if (!grep { $_ eq $name } $self->may_have_children) {
                # Urk. Should have been encoded and wasn't! Stupid thing.
                $val = join '', map { $_->toString } $child->childNodes;
            } else {
                $val = $self->parse_children($c, $child);
            }
        } else {
            my $text   = $child->textContent();
            $text = '' if $text !~ /\S/ ;

            # argh. it has attributes. we do our little hack...
            if ($child->hasAttributes) {
                $val = XML::RSS::LibXML::MagicElement->new(
                    content => $text,
                    attributes => [ $child->attributes ]
                );
            } else {
                $val = $text;
            }
        }

        # XXX - XML::RSS now can store multiple elements in a slot.
        # This we detect and change the underlying structure from a
        # scalar to an array

        if ($prefix) {
            $h{$prefix} ||= {};
            $self->store_element($h{$prefix}, $name, $val);

            # XML::RSS requires us to allow access to elements both from
            # the prefix and the namespace
            $h{$c->{namespaces}{$prefix}} ||= {};
            $self->store_element($h{$c->{namespaces}{$prefix}}, $name, $val);
        } else {
            $self->store_element(\%h, $name, $val);
        }
    }
    return wantarray ? %h : \%h;
}

sub as_string
{
    my ($self, $c, $format) = @_;

    my $dom = $self->create_dom($c);
    return $dom->toString($format);
}

sub create_dom
{
    my ($self, $c) = @_;

    my $dom  = $self->create_document($c);
    $self->create_dtd($c, $dom);
    $self->create_pi($c, $dom);
    $self->create_rootelement($c, $dom);
    $self->create_namespaces($c, $dom);
    $self->create_channel($c, $dom);
    $self->create_items($c, $dom);

    return $dom;
}

sub create_pi
{
    my ($self, $c, $dom) = @_;

    my $styles = $c->stylesheets;
    foreach my $style (@$styles) {
        my $pi = $dom->createProcessingInstruction('xml-stylesheet');
        $pi->setData(type => 'text/xsl', href => $style);
        $dom->appendChild($pi);
    }
}

sub create_document 
{   
    my $self = shift;
    my $c    = shift;
    return XML::LibXML::Document->new('1.0', $c->encoding);
}   

sub create_rootelement {}
sub create_dtd {}
sub create_channel {}
sub create_items {}

sub create_misc_simple
{
    my ($self, $c, $dom, $parent) = @_;

    my $definition = $self->definition;
    while (my($p, $children) = each %$definition) {
        next if ! $c->{$p};

        my @nodes;
        while (my($e, $value) = each %$children) {
            if (defined $value) {
                my $node = $dom->createElement($e);
                $node->appendText($value);
                push @nodes, $node;
            }
        }

        if (@nodes) {
            my $local_parent = $dom->createElement($p);
            $local_parent->appendChild($_) for @nodes;
            $parent->appendChild($local_parent);
        }
    }
}

sub create_taxo
{
    my ($self, $c, $dom, $parent) = @_;

    my $list  = $c->{taxo};
    if (! $list || @$list <= 0) {
        return;
    }

    my $topic = $dom->createElement('taxo:topics');
    my $bag   = $dom->createElement('rdf:Bag');
    foreach my $taxo (@$list) {
        my $node = $dom->createElement('rdf:li');
        $node->setAttribute(resource => $taxo);
        $bag->appendChild($node);
    }
    $topic->appendChild($bag);
    $parent->appendChild($topic);
}

sub create_extra_modules
{
    my ($self, $c, $dom, $parent, $namespaces) = @_;

    while (my ($prefix, $uri) = each %$namespaces) {
        next if $prefix =~ /^(?:dc|syn|taxo|rss\d\d)$/;
        next if ! defined $c->{$prefix};

        while (my($e, $value) = each %{ $c->{$prefix} }) {
            my $node = $dom->createElement("$prefix:$e");
            $node->appendText($value);
            $parent->appendChild($node);
        }
    }
}
 
sub create_namespaces
{       
    my $self = shift;
    my $c    = shift;
    my $dom  = shift;
    my $root = $dom->getDocumentElement() or
        croak "No document element found?!";
    my $namespaces = $c->namespaces;
    while (my($prefix, $url) = each %$namespaces) {
        next if $prefix =~ /^rss\d\d$/;
        next if $prefix =~ /^#default$/;
        $root->setNamespace($url, $prefix, 0);
    }
} 

sub create_element_from_spec
{
    my ($self, $c, $dom, $parent, $specs) = @_;

    my $root = $dom->getDocumentElement();

    my $node;
    while (my ($e, $spec) = each %$specs) {
        my( $callback, $list );
        if (ref $spec eq 'HASH') {
            $callback = $spec->{callback};
            $list = $spec->{candidates};
        } elsif (ref $spec eq 'ARRAY') {
            $list = $spec;
        }
        foreach my $p (@$list) {
            my ($prefix, $value);
            if (ref $p && ref $p eq 'HASH') {
                if ($c->{$p->{module}}) {
                    $prefix = $p->{module};
                    $value  = $c->{$p->{module}}{$p->{element}};
                }
            } else {
                $value = $c->{$p};
            }

            if (defined $value) {
                if ($prefix) {
                    $root->setNamespace(
                        XML::RSS::LibXML::Namespaces::lookup_uri($prefix),
                        $prefix,
                        0
                    );
                } 

                $node = $dom->createElement($e);
                if (ref $value && eval { $value->isa('XML::RSS::LibXML::MagicElement') }) {
                    foreach my $attr ($value->attributes) {
                        $node->setAttribute($attr, $value->{$attr});
                    }
                } elsif ($callback) {
                    $callback->($value);
                }
                $node->appendText($value);
                $parent->appendChild($node);
                last;
            }
        }
    }
}

sub add_item
{
    my $self = shift;
    my $c    = shift;
    my $h    = ref($_[0]) eq 'HASH' ? $_[0] : {@_};

    $self->validate_item($c, $h);

    my $guid = $h->{guid};
    if (defined $guid) {
        # guid should *only* be MagicElement
        if (! eval { $guid->isa('XML::RSS::LibXML::MagicElement') }) {
            $h->{permaLink} = $guid;
        } else {
            if (my $is_permalink = $guid->{isPermaLink}) {
                if ($is_permalink eq 'true') {
                    $h->{permaLink} = $guid->{_content};
                }
            } else {
                $h->{permaLink} = $guid->{_content};
            }
        }
    } elsif (defined (my $permaLink = $h->{permaLink})) {
        $h->{guid} = XML::RSS::LibXML::MagicElement->new(
            content => $permaLink,
            attributes => { isPermaLink => 'true' }
        );
    }

    my $namespaces = $c->namespaces;
    foreach my $p (keys %$namespaces) {
        if ($h->{$p}) {
            $h->{ $namespaces->{$p} } = $h->{$p};
        }
    }

    # add the item to the list 
    if (defined($h->{mode}) && delete $h->{mode} eq 'insert') {
        unshift(@{$c->items}, $h);
    }
    else {
        push(@{$c->items}, $h);
    }

    # return reference to the list of items
    return $c->{items};
}

1;

__END__

=head1 NAME

XML::RSS::LibXML::ImplBase - Implementation Base For XML::RSS::LibXML 

=head1 SYNOPSIS

  # Internal use only

=head1 DESCRIPTION

=cut
