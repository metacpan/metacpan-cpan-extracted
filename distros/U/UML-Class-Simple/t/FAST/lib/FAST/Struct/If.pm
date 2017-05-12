#: FAST/Struct/If.pm
#: Branching structure in FAST DOM tree
#: Copyright (c) 2006 Agent Zhang
#: 2006-03-08 2006-03-10

package FAST::Struct::If;

use strict;
use warnings;

use base 'FAST::Struct';
use FAST::Node;

our $VERSION = '0.01';

sub new {
    my ($proto, $cond, $yes, $no) = @_;
    my $self = $proto->SUPER::new;
    $self->_set_elems(
        $self->_node($cond),
        $self->_node($yes),
        $self->_node($no),
        $self->_node(''),
    );
    return $self;
}

# Return the conditional statement in the branching structure:
sub condition {
    my $self = shift;
    return ($self->elems)[0];
}

# Return the `true branch' statement in the branching structure:
sub true_branch {
    my $self = shift;
    return ($self->elems)[1];
}

# Return the `false branch' statement in the branching structure:
sub false_branch {
    my $self = shift;
    return ($self->elems)[2];
}

sub tail {
    my $self = shift;
    return ($self->elems)[3];
}

sub entry {
    return $_[0]->condition;
}

sub exit {
    return $_[0]->tail;
}

sub must_pass {
    my ($self, $label) = @_;
    return $self->condition->must_pass($label) ||
        ($self->true_branch->must_pass($label) &&
         $self->false_branch->must_pass($label));
}

sub as_c {
    my ($self, $level) = @_;
    $level ||= 0;
    my $cond = $self->condition->as_c($level);
    my $block1 = $self->true_branch->as_c($level+1);
    my $block2 = $self->false_branch->as_c($level+1);
    my $indent = ' ' x (4 * $level);
    if ($block2 eq '') {
        return "${indent}if ($cond) {\n${block1}${indent}}\n";
    }
    return "${indent}if ($cond) {\n${block1}${indent}} else {\n${block2}${indent}}\n";
}

sub visualize {
    my ($self, $gv) = @_;
    die if not defined $gv;
    my ($cond, $blk1, $blk2, $tail) = 
        ($self->condition, $self->true_branch,
         $self->false_branch, $self->tail);
    $cond->visualize($gv);
    $blk1->visualize($gv);
    $blk2->visualize($gv);
    $tail->visualize($gv);
    $gv->add_edge($cond->id => $blk1->entry->id, label => 'Y');
    $gv->add_edge($blk1->exit->id => $tail->id);
    $gv->add_edge($cond->id => $blk2->entry->id, label => 'N');
    $gv->add_edge($blk2->exit->id => $tail->id);
}

1;
__END__

=head1 NAME

FAST::Struct::If - Branching structure in FAST DOM tree

=head1 SYNOPSIS

    use FAST::Struct::If;

    $if = FAST::Struct::If->new('<p>', '[f]', '[L:=3]');
    print $if->condition->label;
    print $if->true_branch->label;
    print $if->false_branch->label;
    @elems = $if->elems;
    $sucess = $if->subs('[f]', '[L:=3]');
    print $if->must_pass('[f]'); # false
    print $if->must_pass('<p>'); # true
    print $if->might_pass('[L:=3]'); # true

=head1 INHERITANCE

    FAST::Struct::If
        isa FAST::Struct
            isa FAST::Element
                isa Clone

=head1 DESCRIPTION

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang

This library is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.
