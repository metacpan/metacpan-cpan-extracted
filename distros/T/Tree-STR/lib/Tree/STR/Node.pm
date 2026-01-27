package Tree::STR::Node;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.04';

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        bbox     => $args{bbox},
        children => $args{children},
        tip      => $args{tip},
    }, $class;

    return $self;
}

sub is_tip_node {
    my ($self) = @_;
    !!$self->{tip};
}

sub is_inner_node {
    my ($self) = @_;
    !!$self->{children};
}

sub children {
    my ($self) = @_;
    $self->{children} // [];
}

sub tip {
    my ($self) = @_;
    $self->{tip};
}

sub tips {
    my ($self) = @_;
    return $self if $self->is_tip_node;
    my @tips;
    my @children = @{$self->children};
    while (my $child = shift @children) {
        if ($child->is_tip_node) {
            push @tips, $child;
        }
        else {
            push @children, @{$child->children};
        }
    }
    return \@tips;
}

sub bbox {
    my ($self) = @_;
    $self->{bbox};
}

sub query_point {
    my ($self, $x, $y) = @_;
    my $bbox = $self->bbox;

    return [] if $x < $bbox->[0] || $x > $bbox->[2] || $y < $bbox->[1] || $y > $bbox->[3];

    return [$self->{tip}] if $self->is_tip_node;

    my @collated;
    foreach my $child (@{ $self->children }) {
        my $res = $child->query_point ($x, $y);
        push @collated, @$res;
    }
    return \@collated;
}

sub query_partly_within_rect {
    my ($self, $x1, $y1, $x2, $y2) = @_;
    my $bbox = $self->bbox;

    return []
        if $x2 < $bbox->[0] || $x1 > $bbox->[2]
        || $y2 < $bbox->[1] || $y1 > $bbox->[3];

    return [$self->{tip}] if $self->is_tip_node;

    my @collated;
    foreach my $child (@{ $self->children }) {
        my $res = $child->query_partly_within_rect ($x1, $y1, $x2, $y2);
        push @collated, @$res;
    }
    return \@collated;
}

sub query_completely_within_rect {
    my ($self, $x1, $y1, $x2, $y2) = @_;
    my $bbox = $self->bbox;

    #  no overlap
    return []
        if $x2 < $bbox->[0] || $x1 > $bbox->[2]
        || $y2 < $bbox->[1] || $y1 > $bbox->[3];

    if ($self->is_tip_node) {
        #  not fully contained
        return []
            if !($x1 < $bbox->[0] && $x2 > $bbox->[2]
              && $y1 < $bbox->[1] && $y2 > $bbox->[3]
            );

        return [ $self->{tip} ];
    }

    my @collated;
    foreach my $child (@{ $self->children }) {
        my $res = $child->query_completely_within_rect ($x1, $y1, $x2, $y2);
        push @collated, @$res;
    }
    return \@collated;
}

1;

=head1 NAME

Tree::STR::Node - Internal helper class for Tree::STR

=head1 VERSION

Version 0.01

=cut
