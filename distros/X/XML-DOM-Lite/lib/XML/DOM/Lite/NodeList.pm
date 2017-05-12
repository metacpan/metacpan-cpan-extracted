package XML::DOM::Lite::NodeList;

=head1 NAME

XML::DOM::Lite::NodeList - blessed array ref for containing Node objects

=head1 SYNOPSIS

 $node->childNodes->insertNode($childNode, [$index]);
 my @removedNodes = $node->childNodes->removeNode($childNode);
 my $childNode = $node->childNodes->item($index);
 my $numChilds = $node->childNodes->length;

=cut

use overload '%{}' => \&as_hashref, fallback => 1;

sub new {
    my ($class, $nodes) = @_;
    my $self;
    if (ref $nodes eq 'ARRAY') {
	# take a copy of the array
	$self = bless [ @$nodes ], $class;
    } else {
	die "usage error, $class must be constructed with an ARRAY ref";
    }
    return $self;
}

sub as_hashref {
    my $self = shift;
    my $hashref = { };
    foreach my $n (@$self) {
        $hashref->{$n->nodeName} = ($n->nodeValue ? $n->nodeValue : $n);
    }
    return $hashref;
}

sub insertNode {
    my ($self, $node, $index) = @_;
    if (defined $index) {
        splice(@{$self}, $index, 0, $node);
    } else {
        push(@{$self}, $node);
    }
    return $node;
}

sub removeNode {
    my ($self, $node) = @_;
    return splice (@{$self}, $self->nodeIndex($node), 1);
}

sub item {
    my ($self, $index) = @_;
    return $self->[$index];
}

sub length {
    my $self = shift;
    return scalar(@$self);
}

sub nodeIndex {
    my ($self, $node) = @_;
    die "usage error" unless (scalar(@_) == 2);
    my $i = 0;
    foreach (@$self) {
	return $i if $_ eq $node;
	$i++;
    }
    return undef;
}

1;
