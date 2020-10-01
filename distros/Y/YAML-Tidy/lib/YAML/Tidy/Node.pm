# ABSTRACT: yamltidy parse tree element
use strict;
use warnings;
use v5.20;
use experimental qw/ signatures /;
package YAML::Tidy::Node;

our $VERSION = '0.002'; # VERSION

sub new($class, %args) {
    my $self = {
        %args,
    };
    return bless $self, $class;
}

sub pre($self, $node) {
    my $index = $node->{index} - 1;
    my $end;
    if ($index < 1) {
        $end = $self->{start}->{end};
    }
    else {
        my $previous = $self->{children}->[ $index -1 ];
        $end = $previous->end;
    }
    return $end;
}


package YAML::Tidy::Node::Collection;

use base 'YAML::Tidy::Node';

#sub is_scalar { 0 }

sub is_collection { 1 }

sub indent($self) {
    my $firstevent = $self->{start};
    if ($firstevent->{name} eq 'document_start_event') {
        return 0;
    }

    my $startcol = $firstevent->{end}->{column};
    return $startcol;
}

sub end($self) {
    return $self->{end}->{end};
}

sub realendline($self) {
    $self->{end}->{end}->{line} - 1;
}

sub start($self) {
    return $self->{start}->{start};
}

sub line($self) {

    my $contentstart = $self->contentstart;
    return $contentstart->{line};
}

sub contentstart($self) {
    my $firstevent = $self->{start};
    return $firstevent->{end};
}

sub fix_node_indent($self, $fix) {
    for my $e (@$self{qw/ start end /}) {
        for my $pos (@$e{qw/ start end /}) {
            $pos->{column} += $fix;
        }
    }
    for my $c (@{ $self->{children} }) {
        $c->fix_node_indent($fix);
    }
}


package YAML::Tidy::Node::Scalar;
use YAML::PP::Common qw/
    YAML_PLAIN_SCALAR_STYLE YAML_SINGLE_QUOTED_SCALAR_STYLE
    YAML_DOUBLE_QUOTED_SCALAR_STYLE YAML_LITERAL_SCALAR_STYLE
    YAML_FOLDED_SCALAR_STYLE
    YAML_FLOW_SEQUENCE_STYLE YAML_FLOW_MAPPING_STYLE
/;

use base 'YAML::Tidy::Node';

#sub is_scalar { 1 }

sub is_collection { 0 }

sub indent($self) {

    return $self->{start}->{column};
}

sub start($self) {
    return $self->{start};
}

sub end($self) {
    return $self->{end};
}

sub realendline($self) {
    my $end = $self->{end};
    if ($self->{style} == YAML_LITERAL_SCALAR_STYLE
        or $self->{style} == YAML_FOLDED_SCALAR_STYLE) {
            if ($end->{column} == 0) {
                return $end->{line} - 1;
            }
        }
    $end->{line};
}

sub line($self) {
    my $contentstart = $self->contentstart;
    return $contentstart->{line};
}

sub contentstart($self) {
    return $self->{start};
}

sub multiline($self) {
    if ($self->{start}->{line} < $self->{end}->{line}) {
        return 1;
    }
    return 0;
}

sub empty_scalar($self) {
    my ($start, $end) = @$self{qw/ start end /};
    if ($start->{line} == $end->{line} and $start->{column} == $end->{column}) {
        return 1;
    }
    return 0;
}


sub fix_node_indent($self, $fix) {
    for my $pos (@$self{qw/ start end /}) {
        $pos->{column} += $fix;
    }
}


1;
