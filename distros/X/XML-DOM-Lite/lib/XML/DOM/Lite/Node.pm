package XML::DOM::Lite::Node;
use warnings;
use strict;

use Scalar::Util qw(weaken);
use XML::DOM::Lite::NodeList;
use XML::DOM::Lite::Constants qw(:all);

sub new {
    my ($class, $proto) = @_;
    unless (UNIVERSAL::isa($proto->{childNodes}, 'XML::DOM::Lite::NodeList')) {
	$proto->{childNodes} = XML::DOM::Lite::NodeList->new(
            $proto->{childNodes} || [ ]
        );
    }
    $proto->{attributes} = XML::DOM::Lite::NodeList->new([ ])
        unless defined $proto->{attributes};

    weaken($proto->{parentNode}) if defined $proto->{parentNode};
    weaken($proto->{ownerDocument}) if defined $proto->{ownerDocument};

    my $self = bless $proto, $class;
    return $self;
}

sub childNodes {
    my $self = shift; $self->{childNodes} = shift if @_;
    return $self->{childNodes};
}

sub parentNode {
    my $self = shift;
    if (@_) {
	weaken($self->{parentNode} = shift());
    } else {
	return $self->{parentNode};
    }
}

sub documentElement {
    $_[0]->{documentElement} = $_[1] if $_[1];
    $_[0]->{documentElement};
}

sub nodeType {
    my $self = shift; $self->{nodeType} = shift if @_;
    $self->{nodeType};
}

sub nodeName {
    my $self = shift; $self->{nodeName} = shift if @_;
    $self->{nodeName};
}

sub tagName {
    my $self = shift; $self->{tagName} = shift if @_;
    $self->{tagName};
}

sub appendChild {
    my ($self, $node) = @_;
    if ($node->{parentNode}) {
        $node->{parentNode}->removeChild($node);
    }
    unless ($node->nodeType == DOCUMENT_FRAGMENT_NODE) {
        $node->parentNode($self);
        $self->{childNodes}->insertNode($node);
    } else {
        while ($node->childNodes->length) {
            $self->appendChild($node->firstChild);
        }
    }

    return $node;
}

sub previousSibling {
    my $self = shift;
    if ($self->parentNode) {
        my $index = $self->parentNode->childNodes->nodeIndex($self);
        return undef if $index == 0;
        return $self->parentNode->childNodes->[$index - 1];
    }
}

sub nextSibling {
    my $self = shift;
    if ($self->parentNode) {
        my $index = $self->parentNode->childNodes->nodeIndex($self);
        return undef if $index == $self->parentNode->childNodes->length - 1;
        return $self->parentNode->childNodes->[$index + 1];
    }
}

sub removeChild {
    my ($self, $node) = @_;
    if ($node->parentNode == $self) {
	undef($node->{parentNode});
	return $self->childNodes->removeNode($node);
    } else {
	die "$node is not a child of $self";
    }
}

sub insertBefore {
    my ($self, $node, $refNode) = @_;
    die "usage error" unless (scalar(@_) == 3);
    if ($node->parentNode) {
        $node->parentNode->removeChild($node);
    }
    if ($node->nodeType == DOCUMENT_FRAGMENT_NODE) {
        foreach my $c (@{$node->childNodes}) {
            $self->insertBefore($c, $refNode);
        }
        return;
    }
    $node->parentNode($self);
    my $index = $self->childNodes->nodeIndex($refNode);
    if (defined $index) {
	if ($index <= 0) {
	    $self->childNodes->insertNode($node, 0);
	} else {
	    $self->childNodes->insertNode($node, $index);
	}
    } else {
	die "$refNode is not a child of $self";
    }
}

sub replaceChild {
    my ($self, $node, $refNode) = @_;
    die "usage error" unless (scalar(@_) == 3);
    $self->insertBefore($refNode, $node);
    $self->removeChild($refNode);
}

sub nodeValue {
    my $self = shift; $self->{nodeValue} = shift if @_;
    $self->{nodeValue};
}

sub attributes {
    my $self = shift; $self->{attributes} = shift if @_;
    return $self->{attributes};
}

sub getAttribute {
    my ($self, $attname) = @_;
    for (my $x = 0; $x < $self->{attributes}->length; $x++) {
        return  $self->{attributes}->[$x]->{nodeValue}
            if ($self->{attributes}->[$x]->{nodeName} eq $attname);
    }
    return undef;
}

sub setAttribute {
    my ($self, $attname, $value) = @_;
    for (my $x = 0; $x < $self->{attributes}->length; $x++) {
        if ($self->{attributes}->[$x]->{nodeName} eq $attname) {
            $self->{attributes}->[$x]->{nodeValue} = $value;
            return $value;
        }
    }
    push @{$self->{attributes}}, XML::DOM::Lite::Node->new({
        nodeType => ATTRIBUTE_NODE,
        nodeName => $attname,
        nodeValue => $value
    });
    return $value;

}

sub firstChild {
    my ($self) = @_;
    return $self->childNodes->item(0);
}

sub lastChild {
    my ($self) = @_;
    return $self->childNodes->[$#{$self->childNodes}];
}

sub ownerDocument {
    my $self = shift; weaken($self->{ownerDocument} = shift) if @_;
    $self->{ownerDocument};
}

sub getElementsByTagName {
    my ($self, $tag_name) = @_;
    my $nlist = XML::DOM::Lite::NodeList->new([ ]);
    my @stack = @{ $self->childNodes };
    while (my $n = shift(@stack)) {
        if ($n->nodeType  == ELEMENT_NODE) {
            if ($n->tagName eq $tag_name) {
                $nlist->insertNode($n);
            }
            push @stack, @{ $n->childNodes };
        }
    }
    return $nlist;
}

sub cloneNode {
    my ($self, $deep) = @_;

    my $copy = { %$self };
    $copy->{childNodes} = XML::DOM::Lite::NodeList->new([ ]);
    $copy->{attributes} = XML::DOM::Lite::NodeList->new([@{$self->attributes}]);
    weaken($copy->{ownerDocument});
    weaken($copy->{parentNode});

    bless $copy, ref($self);

    if ($deep) {
	$copy->{documentElement} = $copy->{documentElement}->cloneNode($deep)
	    if defined $copy->{documentElement};
	foreach (@{$self->childNodes}) {
	    $copy->childNodes->insertNode($_->cloneNode($deep));
	}
    }
    return $copy;
}

sub xml {
    my $self = shift;
    require XML::DOM::Lite::Serializer;
    my $serializer = XML::DOM::Lite::Serializer->new();
    return $serializer->serializeToString( $self );
}


1;

