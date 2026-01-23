package Tree::STR;

use 5.010;
use strict;
use warnings;

use Tree::STR::Node;

use POSIX qw /ceil/;
use List::Util qw /min max/;
use Ref::Util qw/is_blessed_ref is_arrayref/;


=head1 NAME

Tree::STR - A Sort-Tile-Recursive tree index

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use Tree::STR;

    my $data = [[0,1,2,2,'item 1'], [10,20,100,200,'item 2']];
    my $tree = Tree::STR->new($data);
    my $intersects_point = $tree->query_point(50,50); # ['item 2']
    my $intersects_poly  = $tree->query_partly_within_rect(20,20,200,200); # ['item 2']
    ...

=head1 DESCRIPTION

Create a Sort-Tile-Recursive tree.  This is a read-only R-Tree that
is more efficient to create than a standard R-Tree.

The input data need to be an array of arrays, where each internal
array contains the bounding box coordinates as (xmin, ymin, xmax, ymax)
followed by the item to be stored.

Alternately one can pass an array of objects that provide a bbox method
that returns an array of coordinates in the order (xmin, ymin, xmax, ymax).

=head1 EXPORT

None.

=head1 METHODS

=head2 new

=cut

sub new {
    my ($class, $data, $n) = @_;
    my $self = bless { nrects => $n // 3}, $class;
    $self->{root} = $self->_load_data ($data);
    return $self;
}

sub bbox {
    my ($self) = @_;
    return if !$self->{root};
    $self->{root}->bbox;
}

sub _load_data {
    my ($self, $data) = @_;
    #  we need to work on the bbox centres
    my @bboxed = map {is_blessed_ref $_ && $_->can('bbox') ? [$_->bbox, $_] : $_} @$data;
    my @centred = map {[($_->[0] + $_->[2] / 2), ($_->[1] + $_->[3] / 2), $_]} @bboxed;
    my @bbox = $self->_get_bbox_from_centred_recs(\@centred);
    my $children = $self->_load_data_inner(\@centred);
    return Tree::STR::Node->new (
        bbox     => \@bbox,
        children => $children,
    );
}

sub _load_data_inner {
    my ($self, $data, $sort_axis) = @_;

    $sort_axis //= 0;
    my @sorted = sort {$a->[$sort_axis] <=> $b->[$sort_axis]} @$data;

    my $nrects = $self->{nrects};
    my $nitems = @$data;
    my $n_per_box = ceil ($nitems / $nrects);
    my @ranges;
    my $i = 0;
    while ($i < $nitems) {
        push @ranges, [$i,$i+$n_per_box-1];
        $i += $n_per_box;
    }

    #  switch axis for inner calls
    $sort_axis = $sort_axis ? 0 : 1;

    my @nodes;
    for my $range (@ranges) {
        my @recs = @sorted[$range->[0]..min($#sorted, $range->[1])];

        next if !@recs;

        my @bbox = $self->_get_bbox_from_centred_recs(\@recs);
        if (@recs > 1) {
            push @nodes, Tree::STR::Node->new (
                bbox     => \@bbox,
                children => $self->_load_data_inner(\@recs, $sort_axis),
            );
        }
        else {
            push @nodes, Tree::STR::Node->new (
                bbox => \@bbox,
                tip  => $recs[0][2][-1],  #  nasty...
            );
        }
    }
    return \@nodes;
}

sub _get_bbox_from_centred_recs {
    my ($self, $recs) = @_;
    state $bbox_idx = 2;
    my ($x1, $y1, $x2, $y2) = @{$recs->[0][$bbox_idx]}[0 .. 3];
    return ($x1, $y1, $x2, $y2)
        if @$recs == 1;
    foreach my $rec (@$recs) {
        my $bbox = $rec->[$bbox_idx];
        $x1 = min($x1, $bbox->[0]);
        $y1 = min($y1, $bbox->[1]);
        $x2 = max($x2, $bbox->[2]);
        $y2 = max($y2, $bbox->[3]);
    }
    return $x1, $y1, $x2, $y2;
}

=head2 query_point

=cut

sub query_point {
    my $self = shift;
    return $self->{root}->query_point(@_);
}

=head2 query_partly_within_rect

=cut

sub query_partly_within_rect {
    my $self = shift;
    return $self->{root}->query_partly_within_rect(@_);
}

=head2 query_completely_within_rect

=cut

sub query_completely_within_rect {
    my $self = shift;
    return $self->{root}->query_completely_within_rect(@_);
}

=head1 AUTHOR

Shawn Laffan <shawnlaffan@gmail.com>

=head1 BUGS

L<https://github.com/biogeospatial/Tree-STR/issues>


=head1 SEE ALSO

L<Tree::R>

L<Geo::Geos::Index::STRtree>

Leutenegger, Scott T.; Edgington, Jeffrey M.; Lopez, Mario A. (1997).
"STR: A Simple and Efficient Algorithm for R-Tree Packing".
L<https://ia600900.us.archive.org/27/items/nasa_techdoc_19970016975/19970016975.pdf>


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Shawn Laffan <shawnlaffan@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Tree::STR
