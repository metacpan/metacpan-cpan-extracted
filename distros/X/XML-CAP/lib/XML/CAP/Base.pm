# XML::CAP::Base - base class for XML::CAP element classes
# Copyright 2009 by Ian Kluft
# This is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.
# 
# derived from XML::Atom::Base

package XML::CAP::Base;
use strict;
use warnings;
use base qw( XML::CAP Class::Data::Inheritable );
use XML::LibXML;

use Encode;
use XML::CAP::Util qw( set_ns first nodelist childlist create_element );

__PACKAGE__->mk_classdata('__attributes', []);

sub initialize {
    my $self = shift;
    my %param = @_;
    if (!exists $param{Namespace} and my $ns = $self->element_ns) {
        $param{Namespace} = $ns;
    }
    $self->set_ns(\%param);
    my $elem;
    unless ($elem = $param{Elem}) {
        my $doc = XML::LibXML::Document->createDocument();
        my $ns = $self->ns;
        my ($ns_uri, $ns_prefix);
        if ( ref $ns and $ns->isa('XML::CAP::Namespace') ) {
            $ns_uri     = $ns->{uri};
            $ns_prefix  = $ns->{prefix};
        } else {
            $ns_uri = $ns;
        }
        if ( $ns_uri and $ns_prefix ) {
            $elem = $doc->createElement($self->element_name);
            $elem->setNamespace( $ns_uri, $ns_prefix, 1 );
        } else {
            $elem = $doc->createElementNS($self->ns, $self->element_name);
        }
        $doc->setDocumentElement($elem);
    }
    $self->{elem} = $elem;
    $self;
}

sub element_name { }
sub element_ns { }

sub ns   { $_[0]->{ns} }
sub elem { $_[0]->{elem} }

sub version {
    my $self = shift;
    XML::CAP::Util::ns_to_version($self->ns);
}

sub content_type {
    my $self = shift;
    return "application/common-alerting-protocol+xml";
}

sub get {
    my $self = shift;
    my($ns, $name) = @_;
    my @list = $self->getlist($ns, $name);
    return $list[0];
}

sub getlist {
    my $self = shift;
    my($ns, $name) = @_;
    my $ns_uri = ref($ns) eq 'XML::CAP::Namespace' ? $ns->{uri} : $ns;
    my @node = nodelist($self->elem, $ns_uri, $name);
    return map {
        my $val = $_->textContent;
        if ($] >= 5.008) {
            require Encode;
            Encode::_utf8_off($val) unless $XML::CAP::ForceUnicode;
        }
        $val;
     } @node;
}

sub add {
    my $self = shift;
    my($ns, $name, $val, $attr) = @_;
    return $self->set($ns, $name, $val, $attr, 1);
}

sub set {
    my $self = shift;
    my($ns, $name, $val, $attr, $add) = @_;
    my $ns_uri = ref $ns eq 'XML::CAP::Namespace' ? $ns->{uri} : $ns;
    my @elem = childlist($self->elem, $ns_uri, $name);
    if (!$add && @elem) {
        $self->elem->removeChild($_) for @elem;
    }
    my $elem = create_element($ns, $name);
    if (UNIVERSAL::isa($val, 'XML::CAP::Base')) {
        for my $child ($val->elem->childNodes) {
            $elem->appendChild($child->cloneNode(1));
        }
        for my $attr ($val->elem->attributes) {
            next unless ref($attr) eq 'XML::LibXML::Attr';
            $elem->setAttribute($attr->getName, $attr->getValue);
        }
    } else {
        $elem->appendChild(XML::LibXML::Text->new($val));
    }
    $self->elem->appendChild($elem);
    if ($attr) {
        while (my($k, $v) = each %$attr) {
            $elem->setAttribute($k, $v);
        }
    }
    return $val;
}

sub get_attr {
    my $self = shift;
    my($attr) = @_;
    my $val = $self->elem->getAttribute($attr);
    if ($] >= 5.008) {
        require Encode;
        Encode::_utf8_off($val) unless $XML::CAP::ForceUnicode;
    }
    $val;
}

sub set_attr {
    my $self = shift;
    if (@_ == 2) {
        my($attr, $val) = @_;
        $self->elem->setAttribute($attr => $val);
    } elsif (@_ == 3) {
        my($ns, $attr, $val) = @_;
        my $attribute = "$ns->{prefix}:$attr";
        $self->elem->setAttributeNS($ns->{uri}, $attribute, $val);
    }
}

sub get_object {
    my $self = shift;
    my($ns, $name, $class) = @_;
    my $ns_uri = ref($ns) eq 'XML::CAP::Namespace' ? $ns->{uri} : $ns;
    my @elem = childlist($self->elem, $ns_uri, $name) or return;
    my @obj = map { $class->new( Elem => $_, Namespace => $ns ) } @elem;
    return wantarray ? @obj : $obj[0];
}

sub mk_elem_accessors {
    my $class = shift;
    my (@list) = @_;
    my $override_ns;

    if ( ref $list[-1] ) {
        my $ns_list = pop @list;
        if ( ref $ns_list eq 'ARRAY' ) {
            $ns_list = $ns_list->[0];
        }
        if ( ref($ns_list) =~ /Namespace/ ) {
            $override_ns = $ns_list;
        } else {
            if ( ref $ns_list eq 'HASH' ) {
                $override_ns = XML::CAP::Namespace->new(%$ns_list);
            }
            elsif ( not ref $ns_list and $ns_list ) {
                $override_ns = $ns_list;
            }
        } 
    }

    no strict 'refs';
    for my $elem ( @list ) {
        (my $meth = $elem) =~ tr/\-/_/;
        *{"${class}::$meth"} = sub {
            my $self = shift;
            if (@_) {
                return $self->set( $override_ns || $self->ns, $elem, $_[0]);
            } else {
                return $self->get( $override_ns || $self->ns, $elem);
            }
        };
    }
}

sub mk_attr_accessors {
    my $class = shift;
    my(@list) = @_;
    no strict 'refs';
    for my $attr (@list) {
        (my $meth = $attr) =~ tr/\-/_/;
        *{"${class}::$meth"} = sub {
            my $self = shift;
            if (@_) {
                return $self->set_attr($attr => $_[0]);
            } else {
                return $self->get_attr($attr);
            }
        };
        $class->_add_attribute($attr);
    }
}

sub _add_attribute {
    my($class, $attr) = @_;
    push @{$class->__attributes}, $attr;
}

sub attributes {
    my $class = shift;
    @{ $class->__attributes };
}

sub mk_xml_attr_accessors {
    my($class, @list) = @_;
    no strict 'refs';
    for my $attr (@list) {
        (my $meth = $attr) =~ tr/\-/_/;
        *{"${class}::$meth"} = sub {
            my $self = shift;
            my $elem = $self->elem;
            if (@_) {
                $elem->setAttributeNS('http://www.w3.org/XML/1998/namespace',
                                      $attr, $_[0]);
            }
            return $elem->getAttribute("xml:$attr");
        };
    }
}

sub mk_object_accessor {
    my $class = shift;
    my($name, $ext_class) = @_;
    no strict 'refs';
    (my $meth = $name) =~ tr/\-/_/;
    *{"${class}::$meth"} = sub {
        my $self = shift;
        my $ns_uri = $ext_class->element_ns || $self->ns;
        if (@_) {
            return $self->set($ns_uri, $name, $_[0]);
        } else {
            return $self->get_object($ns_uri, $name, $ext_class);
        }
    };
}


sub mk_object_list_accessor {
    my $class = shift;
    my($name, $ext_class, $moniker) = @_;

    no strict 'refs';

    *{"$class\::$name"} = sub {
        my $self = shift;

        my $ns_uri = $ext_class->element_ns || $self->ns;
        if (@_) {
            # setter: clear existent elements first
            my @elem = childlist($self->elem, $ns_uri, $name);
            for my $el (@elem) {
                $self->elem->removeChild($el);
            }

            # add the new elements for each
            my $adder = "add_$name";
            for my $add_elem (@_) {
                $self->$adder($add_elem);
            }
        } else {
            # getter: just call get_object which is a context aware
            return $self->get_object($ns_uri, $name, $ext_class);
        }
    };

    # moniker returns always list: array ref in a scalar context
    if ($moniker) {
        *{"$class\::$moniker"} = sub {
            my $self = shift;
            if (@_) {
                return $self->$name(@_);
            } else {
                my @obj = $self->$name;
                return wantarray ? @obj : \@obj;
            }
        };
    }

    # add_$name
    *{"$class\::add_$name"} = sub {
        my $self = shift;
        my($stuff) = @_;

        my $ns_uri = $ext_class->element_ns || $self->ns;
        my $elem = (ref $stuff && UNIVERSAL::isa($stuff, $ext_class)) ?
            $stuff->elem : create_element($ns_uri, $name);
        $self->elem->appendChild($elem);

        if (ref($stuff) eq 'HASH') {
            for my $k ( $ext_class->attributes ) {
                defined $stuff->{$k} or next;
                $elem->setAttribute($k, $stuff->{$k});
            }
        }
    };
}

sub as_xml {
    my $self = shift;
    my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
    $doc->setDocumentElement($self->elem->cloneNode(1));
    return $doc->toString(1);
}

sub as_xml_utf8 {
    my $self = shift;
    my $xml = $self->as_xml;
    if (utf8::is_utf8($xml)) {
        return Encode::encode_utf8($xml);
    }
    return $xml;
}

1;
