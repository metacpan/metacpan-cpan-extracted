# ABSTRACT: yamltidy parse tree element
use strict;
use warnings;
use v5.20;
use experimental qw/ signatures /;

package YAML::Tidy::Node;

our $VERSION = '0.006'; # VERSION
use overload '""' => \&_stringify;

sub new($class, %args) {
    my $self = {
        %args,
    };
    return bless $self, $class;
}

sub _stringify($self, @args) {
    my $type = $self->{type} // '';
    my $str = "($type)";
    if ($self->is_collection) {
        my $open = $self->open;
        my $close = $self->close;
        $str .= sprintf " <L %d C %d> <L %d C %d> - <L %d C %d> <L %d C %d>",
            $open->{start}->{line}, $open->{start}->{column},
            $open->{end}->{line}, $open->{end}->{column},
            $close->{start}->{line}, $close->{start}->{column},
            $close->{end}->{line}, $close->{end}->{column},
    }
    else {
        my $val = substr($self->{value}, 0, 20);
        local $Data::Dumper::Useqq = 1;
        $val = Data::Dumper->Dump([$val], ['val']);
        chomp $val;
        $str .= sprintf " <L %d C %d> - <L %d C %d> | %s",
            $self->start->{line}, $self->start->{column},
            $self->end->{line}, $self->end->{column}, $val
    }
    return $str;
}

package YAML::Tidy::Node::Collection;
use constant DEBUG => $ENV{YAML_TIDY_DEBUG} ? 1 : 0;

use base 'YAML::Tidy::Node';

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

sub _move_columns($self, $line, $offset, $fix) {
#    warn __PACKAGE__.':'.__LINE__.": MOVE $self $line $offset $fix\n";
    return if $self->end->{line} < $line;
    return if $self->start->{line} > $line;
    for my $e ($self->open, $self->close) {
        for my $pos (@$e{qw/ start end /}) {
            if ($pos->{line} == $line and $pos->{column} >= $offset) {
                $pos->{column} += $fix;
            }
        }
    }
    for my $c (@{ $self->{children} }) {
        $c->_move_columns($line, $offset, $fix);
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

sub fix_lines($self, $startline, $diff) {
    my $start = $self->open;
    DEBUG and warn __PACKAGE__.':'.__LINE__.": ======== fix_lines $startline $diff ($self)\n";
    my $end = $self->close;
    for my $pos ($start->{start}, $start->{end}) {
        if ($pos->{line} >= $startline) {
            $pos->{line} += $diff;
        }
    }
    for my $pos ($end->{start}, $end->{end}) {
        if ($pos->{column} == 0 and $pos->{line} == $startline) {
        }
        elsif ($pos->{line} >= $startline) {
            $pos->{line} += $diff;
        }
    }
    for my $c (@{ $self->{children} }) {
        $c->fix_lines($startline, $diff);
    }
}

package YAML::Tidy::Node::Scalar;
use constant DEBUG => $ENV{YAML_TIDY_DEBUG} ? 1 : 0;
use YAML::PP::Common qw/
    YAML_PLAIN_SCALAR_STYLE YAML_SINGLE_QUOTED_SCALAR_STYLE
    YAML_DOUBLE_QUOTED_SCALAR_STYLE YAML_LITERAL_SCALAR_STYLE
    YAML_FOLDED_SCALAR_STYLE
    YAML_FLOW_SEQUENCE_STYLE YAML_FLOW_MAPPING_STYLE
/;

use base 'YAML::Tidy::Node';

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

sub _move_columns($self, $line, $offset, $fix) {
#    warn __PACKAGE__.':'.__LINE__.": MOVE $self $line $offset $fix\n";
    return if $self->end->{line} < $line;
    return if $self->start->{line} > $line;
    for my $pos ($self->open, $self->close) {
            if ($pos->{line} == $line and $pos->{column} >= $offset) {
                $pos->{column} += $fix;
            }
    }
#    warn __PACKAGE__.':'.__LINE__.": MOVE $self $line $offset $fix\n";
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

sub fix_lines($self, $startline, $diff) {
    DEBUG and warn __PACKAGE__.':'.__LINE__.": ======== fix_lines $startline $diff ($self)\n";
    for my $pos ($self->open) {
        if ($self->empty_scalar and $pos->{column} == 0 and $pos->{line} == $startline) {
        }
        elsif ($pos->{line} >= $startline) {
            $pos->{line} += $diff;
        }
    }
    for my $pos ($self->close) {
        if ($pos->{column} == 0 and $pos->{line} == $startline) {
        }
        elsif ($pos->{line} >= $startline) {
            $pos->{line} += $diff;
        }
    }
}

1;
