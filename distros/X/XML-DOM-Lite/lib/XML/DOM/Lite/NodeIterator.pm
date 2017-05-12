package XML::DOM::Lite::NodeIterator;

use XML::DOM::Lite::Constants qw(:all);

use constant BEFORE => -1;
use constant AFTER  => 1;

sub new {
    my ($class, $root, $whatToShow, $nodeFilter) = @_;
    my $self = bless {
        root => $root,
        whatToShow => $whatToShow
    }, $class;
    unless (defined $nodeFilter) {
        $self->filter({ acceptNode => sub { return FILTER_ACCEPT } });
    } else {
        $self->filter($nodeFilter);
    }
    $self->{currentNode} = $root;
    $self->{POSITION} = BEFORE;

    return $self;
}

sub filter { $_[0]->{filter} = $_[1] if $_[1]; $_[0]->{filter} }

sub nextNode {
    my $self = shift;
    for (;;) {
        if ($self->{POSITION} == BEFORE) {
            # do nothing so we test the currentNode
        } elsif ($self->{currentNode}->childNodes->length) {
            $self->{currentNode} = $self->{currentNode}->childNodes->[0];
        } elsif ($self->{currentNode}->nextSibling) {
            $self->{currentNode} = $self->{currentNode}->nextSibling;
        } elsif ($self->{currentNode}->parentNode) {
            my $p = $self->{currentNode}->parentNode;
            while ($p and $p->nextSibling == undef and $p != $self->{root}) {
                $p = $p->parentNode;
            }
            last unless ($p and $p->nextSibling);
            $self->{currentNode} = $p->nextSibling;
        } else {
            last;
        }
        $self->{POSITION} = AFTER;
        my $rv;
        if ($self->filter->{whatToShow} & (1 << ($self->{currentNode}->nodeType - 1))) {
            $rv = $self->filter->{acceptNode}->($self->{currentNode});
        } else {
            $rv = FILTER_REJECT;
        }

        if ($rv == FILTER_ACCEPT) {
            return $self->{currentNode};
        }
        elsif ($rv == FILTER_SKIP) {
            if ($self->{currentNode}->nextSibling) {
                $self->{currentNode} = $self->{currentNode}->nextSibling;
            } else {
                my $p = $self->{currentNode}->parentNode;
                while ($p and $p->nextSibling == undef) {
                    $p = $p->parentNode;
                }
                last unless ($p and $p->nextSibling);
                $self->{currentNode} = $p->nextSibling;
            }
            next;
        }
        elsif ($rv != FILTER_REJECT) {
            die('filter returned unknown value: `'.$rv."'");
        }
    }
    return undef;
}

sub previousNode {
    my $self = shift;
    for (;;) {
        if ($self->{POSITION} == AFTER) {
            # do nothing
        } elsif ($self->{currentNode}->previousSibling) {
            my $p = $self->{currentNode}->previousSibling;
            if ($p->childNodes->length) {
                $self->{currentNode} = $p->childNodes->[$p->childNodes->length-1];
		while ($self->{currentNode}->childNodes->length) {
		    $self->{currentNode} = $self->{currentNode}->childNodes->[$self->{currentNode}->childNodes->length - 1];
		}
            } else {
                $self->{currentNode} = $p;
            }
        } elsif ($self->{currentNode}->parentNode and $self->{currentNode}->parentNode != $self->{root}) {
            $self->{currentNode} = $self->{currentNode}->parentNode;
        } else {
            last;
        }
        $self->{POSITION} = BEFORE;
        my $rv;
        if ($self->filter->{whatToShow} & (1 << ($self->{currentNode}->nodeType - 1))) {
            $rv = $self->filter->{acceptNode}->($self->{currentNode});
        } else {
            $rv = FILTER_REJECT;
        }

        if ($rv == FILTER_ACCEPT) {
             return $self->{currentNode};
        }
        elsif ($rv == FILTER_SKIP) {
            if ($self->{currentNode}->previousSibling) {
                $self->{currentNode} = $self->{currentNode}->previousSibling;
            } elsif ($self->{currentNode}->parentNode) {
                $self->{currentNode} = $self->{currentNode}->parentNode;
            } else {
                last;
            }
            next;
        }
        elsif ($rv != FILTER_REJECT) {
            die('filter returned unknown value: `'.$rv."'");
        }
    }
    return undef;
}

1;
