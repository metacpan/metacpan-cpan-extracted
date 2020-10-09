# ABSTRACT: yamltidy parse tree element
use strict;
use warnings;
use v5.20;
use experimental qw/ signatures /;
package YAML::Tidy::Node;

our $VERSION = '0.003'; # VERSION

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
        $end = $self->open->{end};
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
    my $firstevent = $self->open;
    if ($firstevent->{name} eq 'document_start_event') {
        return 0;
    }

    my $startcol = $firstevent->{end}->{column};
    return $startcol;
}

sub open($self) { $self->{start} }
sub close($self) { $self->{end} }

sub end($self) {
    return $self->close->{end};
}

sub closestart($self) {
    return $self->close->{start};
}

sub realendline($self) {
    $self->close->{end}->{line} - 1;
}

sub start($self) {
    return $self->open->{start};
}

sub line($self) {

    my $contentstart = $self->contentstart;
    return $contentstart->{line};
}

sub contentstart($self) {
    my $firstevent = $self->open;
    return $firstevent->{end};
}

sub fix_node_indent($self, $fix) {
    for my $e ($self->open, $self->close) {
        for my $pos (@$e{qw/ start end /}) {
            $pos->{column} += $fix;
        }
    }
    for my $c (@{ $self->{children} }) {
        $c->fix_node_indent($fix);
    }
}

sub _fix_flow_indent($self, %args) {
    my $line = $args{line};
    my $diff = $args{diff};
    my $start = $self->open;
    my $end = $self->close;
    for my $pos ($start->{start}, $start->{end}, $end->{start}, $end->{end}) {
        if ($pos->{line} == $line) {
            $pos->{column} += $diff;
        }
    }
    for my $c (@{ $self->{children} }) {
        $c->_fix_flow_indent(%args);
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
    return $self->open->{column};
}

sub start($self) {
    return $self->open;
}

sub open($self) { $self->{start} }
sub close($self) { $self->{end} }

sub end($self) {
    return $self->close;
}

sub closestart($self) {
    return $self->close;
}

sub realendline($self) {
    my $end = $self->close;
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
    return $self->start;
}

sub multiline($self) {
    if ($self->open->{line} < $self->close->{line}) {
        return 1;
    }
    return 0;
}

sub empty_scalar($self) {
    my ($start, $end) = ($self->open, $self->close);
    if ($start->{line} == $end->{line} and $start->{column} == $end->{column}) {
        return 1;
    }
    return 0;
}


sub fix_node_indent($self, $fix) {
    for my $pos ($self->open, $self->close) {
        $pos->{column} += $fix;
    }
}

sub _fix_flow_indent($self, %args) {
    my $line = $args{line};
    my $diff = $args{diff};
    for my $pos ($self->open, $self->close) {
        if ($pos->{line} == $line) {
            $pos->{column} += $diff;
        }
    }
}

1;
