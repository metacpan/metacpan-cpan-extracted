#: FAST/Struct/Seq.pm
#: Sequential structure in FAST DOM tree
#: Copyright (c) 2006 Agent Zhang
#: 2006-03-08 2006-03-14

package FAST::Struct::Seq;

use strict;
use warnings;

use base 'FAST::Struct';
use FAST::Node;

our $VERSION = '0.01';

sub new {
    my ($proto, $first, $second) = @_;
    my $self = $proto->SUPER::new;
    $self->_set_elems(
        $self->_node($first),
        $self->_node($second)
    );
    return $self;
}

# Return the first statement in the sequential structure:
sub first {
    my $self = shift;
    return ($self->elems)[0];
}

# Return the second statement in the sequential structure:
sub second {
    my $self = shift;
    return ($self->elems)[1];
}

sub entry {
    my $self = shift;
    my $first = $self->first;
    my $second = $self->second;
    if ($first->isa('FAST::Node') and $first->label eq '') {
        if ($second->isa('FAST::Node') and $second->label eq '') {
            return $second;
        } else {
            return $second->entry;
        }
    }
    return $first->entry;
}

sub exit {
    my $self = shift;
    my $first = $self->first;
    my $second = $self->second;
    if ($second->isa('FAST::Node') and $second->label eq '') {
        if ($first->isa('FAST::Node') and $first->label eq '') {
            return $second;
        } else {
            return $first->exit;
        }
    }
    return $second->exit;
}

sub must_pass {
    my ($self, $label) = @_;
    return $self->first->must_pass($label) ||
        $self->second->must_pass($label);
}

sub as_c {
    my ($self, $level) = @_;
    return $self->first->as_c($level) .
        $self->second->as_c($level);
}

sub visualize {
    my ($self, $gv) = @_;
    die if not defined $gv;
    my ($first, $second) = ($self->first, $self->second);
    my $empty1 = $first->isa('FAST::Node') && $first->label eq '';
    my $empty2 = $second->isa('FAST::Node') && $second->label eq '';
    if ($empty1 and $empty2) {
        $second->visualize($gv);
    } else {
        if (!$empty1) {
            $first->visualize($gv);
        }
        if (!$empty2) {
            $second->visualize($gv);
        }
    }
    if (!$empty1 and !$empty2) {
        $gv->add_edge($first->exit->id => $second->entry->id);
    }
}

1;
__END__

=head1 NAME

FAST::Struct::Seq - Sequential structure in FAST DOM tree

=head1 INHERITANCE

    FAST::Struct::Seq
        isa FAST::Struct
            isa FAST::Element
                isa Clone

=head1 SYNOPSIS

    use FAST::Struct::Seq;

    $seq = FAST::Struct::Seq->new('[p]', '[L:=1]');
    print $seq->first->label;
    print $seq->second->label;
    print $seq->id;
    @elems = $seq->elems;
    $sucess = $seq->subs('[p]', '[L:=3]');

=head1 DESCRIPTION

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang

This library is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.
