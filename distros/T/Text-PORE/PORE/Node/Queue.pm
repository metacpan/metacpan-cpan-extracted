package Text::PORE::Node::Queue;

use Text::PORE::Node;
use strict;

@Text::PORE::Node::Queue::ISA = qw(Text::PORE::Node);

sub new {
    my ($type) = shift;
    my ($lineno) = shift;

    my (@nodes) = @_;
    my ($self) = { };

    bless $self, ref($type) || $type;

    $self = $self->SUPER::new($lineno);

    $self->enqueue(@nodes);
    $self->reset();

    $self;
}

sub enqueue {
    my $self = shift;

    my @nodes = @_;

    # TODO - should check grep($_->isa(Node), @nodes);
    push(@{$self->{'nodes'}}, @nodes);
}

sub dequeue {
    my $self = shift;

    $self->reset();
    shift(@{$self->{'nodes'}});
}

sub next {
    my $self = shift;

    my $pos = \$self->{'pos'};
    my $nodes = $self->{'nodes'};

    ($$pos > @$nodes) ? ($self->reset()) : $$nodes[$$pos++] ;
}

sub reset {
    my $self = shift;

    $self->{'pos'} = 0;
}

sub length {
    my $self = shift;

    scalar(@{$self->{'nodes'}});
}

sub traverse {
    my $self = shift;
    my $globals = shift;

    my $obj;
    my $return;

    $self->reset();

    $self->output("[Queue:" . $self->{'lineno'} . "]") if $self->getDebug();

    while ($obj = $self->next()) {
	$self->output("[Queue item:" . $self->{'lineno'} . "]")
	    if $self->getDebug();
	$self->error($obj->traverse($globals));
    }

    return $self->errorDump();
}

1;
