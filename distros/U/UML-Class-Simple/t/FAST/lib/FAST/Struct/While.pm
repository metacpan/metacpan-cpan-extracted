#: FAST/Struct/While.pm
#: Branching structure in FAST DOM tree
#: Copyright (c) 2006 Agent Zhang
#: 2006-03-08 2006-03-11

package FAST::Struct::While;

use strict;
use warnings;

use base 'FAST::Struct';
use FAST::Node;

our $VERSION = '0.01';

sub new {
    my ($proto, $cond, $body) = @_;
    my $self = $proto->SUPER::new;
    $self->_set_elems(
        $self->_node(''),
        $self->_node($cond),
        $self->_node($body),
        $self->_node(''),
    );
    return $self;
}

sub head {
    my $self = shift;
    return ($self->elems)[0];
}

# Return the conditional statement of the while loop:
sub condition {
    my $self = shift;
    return ($self->elems)[1];
}

# Return the `body' of the while loop:
sub body {
    my $self = shift;
    return ($self->elems)[2];
}

sub tail {
    my $self = shift;
    return ($self->elems)[3];
}

sub entry {
    return $_[0]->head;
}

sub exit {
    return $_[0]->tail;
}

sub must_pass {
    my ($self, $label) = @_;
    return $self->condition->must_pass($label);
}

sub as_c {
    my ($self, $level) = @_;
    $level ||= 0;
    my $cond = $self->condition->as_c($level);
    my $block = $self->body->as_c($level+1);
    my $indent = ' ' x (4 * $level);
    return "${indent}while ($cond) {\n${block}${indent}}\n";
}

sub visualize {
    my ($self, $gv) = @_;
    die if not defined $gv;
    my ($head, $cond, $body, $tail) = 
        ($self->head, $self->condition, $self->body, $self->tail);
    $head->visualize($gv);
    $cond->visualize($gv);
    $body->visualize($gv);
    $tail->visualize($gv);
    $gv->add_edge($head->id => $cond->id);
    $gv->add_edge($cond->id => $body->entry->id, label => 'Y');
    $gv->add_edge($body->exit->id => $head->id);
    $gv->add_edge($cond->id => $tail->id, label => 'N');
}

1;
__END__

=head1 NAME

FAST::Struct::While - While looping structure in FAST DOM tree

=head1 SYNOPSIS

    use FAST::Struct::While;

    $while = FAST::Struct::While->new('<p>', '[L=1]');
    print $while->condition->label;
    print $while->body->label;

    @elems = $while->elems;
    $sucess = $while->subs('[L:=1]', '[L:=3]');
    print $while->must_pass('[L:=3]'); # false
    print $while->must_pass('<p>'); # true
    print $while->might_pass('[L:=3]'); # true

=head1 INHERITANCE

    FAST::Struct::While
        isa FAST::Struct
            isa FAST::Element
                isa FAST::Clone

=head1 DESCRIPTION

=head1 AUTHOR

Agent Zhang L<mailto:agentzh@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2006 Agent Zhang

This library is free software. You can redistribute it and/or
modify it under the same terms as Perl itself.
