package Tree::R;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use Tree::R ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.072';

=pod

=head1 NAME

Tree::R - Perl extension for the R-tree data structure and algorithms

=head1 SYNOPSIS

  use Tree::R;

  my $rtree = Tree::R->new

  for my $object (@objects) {
      my @bbox = $object->bbox(); # (minx,miny,maxx,maxy)
      $rtree->insert($object,@bbox);
  }

  my @point = (123, 456); # (x,y)
  my @results;
  $rtree->query_point(@point,\@results);
  for my $object (@results) {
      # point is in object's bounding box
  }

  my @rect = (123, 456, 789, 1234); # (minx,miny,maxx,maxy)
  @results = ();
  $rtree->query_completely_within_rect(@rect,\@results);
  for my $object (@results) {
      # object is within rectangle
  }

  @results = ();
  $rtree->query_partly_within_rect(@rect,\@results);
  for my $object (@results) {
      # object's bounding box and rectangle overlap
  }

=head1 DESCRIPTION

R-tree is a data structure for storing and indexing and efficiently
looking up non-zero-size spatial objects.

=head2 EXPORT

None by default.

=head1 SEE ALSO

A. Guttman: R-trees: a dynamic index structure for spatial
indexing. ACM SIGMOD'84, Proc. of Annual Meeting (1984), 47--57.

N. Beckmann, H.-P. Kriegel, R. Schneider & B. Seeger: The R*-tree: an
efficient and robust access method for points and rectangles. Proc. of
the 1990 ACM SIGMOD Internat. Conf. on Management of Data (1990),
322--331.

The homepage of this module is on github:
https://github.com/ajolma/Tree-R

=head1 AUTHOR

Ari Jolma

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005- by Ari Jolma

This library is free software; you can redistribute it and/or modify
it under the terms of The Artistic License 2.0.

=head1 REPOSITORY

L<https://github.com/ajolma/Tree-R>

=cut

sub new {
    my $package = shift;
    my %opt = @_;
    my $self = {};
    for my $k (keys %opt) {
        $self->{$k} = $opt{$k};
    }
    $self->{m} = 2 unless $self->{m};
    $self->{M} = 5 unless $self->{M};
#    $self->{root} = [1,$child,@rect];
#    $child == [[0,$object,@rect],...] if leaf or [[1,$child,@rect],...] if non-leaf
    bless $self => (ref($package) or $package);
    return $self;
}

sub objects {
    my ($self,$objects,$N) = @_;
    return unless $self->{root};
    $N = $self->{root} unless $N;
    return unless $N;
    unless ($N->[0]) {
        push @$objects,$N->[1];
    } else {
        # check entries
        for my $entry (@{$N->[1]}) {
            $self->objects($objects,$entry);
        }
    }
}

sub query_point {
    my($self,$x,$y,$objects,$N) = @_;
    return unless $self->{root};
    $N = $self->{root} unless $N;
    return unless $x >= $N->[2] and $x <= $N->[4] and $y >= $N->[3] and $y <= $N->[5];
    unless ($N->[0]) {
        push @$objects,$N->[1];
    } else {
        # check entries
        for my $entry (@{$N->[1]}) {
            $self->query_point($x,$y,$objects,$entry);
        }
    }
}

#non-recursive from liuyi at cis.uab.edu
sub query_completely_within_rect {
    my($self,$minx,$miny,$maxx,$maxy,$objects,$Node) = @_;
    return unless $self->{root};

    $Node = $self->{root} unless $Node;
    my @entries;
    push @entries,\$Node;

    while (@entries>0) {
        my $N = pop @entries;
        if (${$N}->[2] > $maxx or # right
            ${$N}->[4] < $minx or # left
            ${$N}->[3] > $maxy or # above
            ${$N}->[5] < $miny)   # below
        {
            next;
        } 
        else {
            if ((!${$N}->[0])
                and (${$N}->[2] >= $minx)
                and (${$N}->[4] <= $maxx)
                and (${$N}->[3] >= $miny)
                and (${$N}->[5] <= $maxy))
            {
                push @$objects,${$N}->[1];
            }
            
            if (${$N}->[0]) {
                foreach my $e (@{${$N}->[1]}) {
                    push @entries,\$e;
                }
            }
        }
    }
    return $objects;
}

#non-recursive from liuyi at cis.uab.edu
sub query_partly_within_rect {
    my($self,$minx,$miny,$maxx,$maxy,$objects,$Node) = @_;
    return unless $self->{root};

    $Node = $self->{root} unless $Node;
    my @entries;
    push @entries,\$Node;

    while (@entries>0) {
        my $N = pop @entries;
        if (${$N}->[2] > $maxx or # right
            ${$N}->[4] < $minx or # left
            ${$N}->[3] > $maxy or # above
            ${$N}->[5] < $miny) # below
        {
            next;
        }
        else {
            if (!${$N}->[0]) {
                push @$objects,${$N}->[1];
            }
            else {
                foreach my $e (@{${$N}->[1]}) {
                    push @entries,\$e;
                }
            }
        }
    }
    return $objects;
}

sub insert {
    my ($self,$object,@rect) = @_; # rect = $minX,$minY,$maxX,$maxY
    my $child = [0,$object,@rect];
    unless ($self->{root}) {
        $self->{root} = [1,[$child],@rect];
    } else {
        my $N = $self->ChooseSubTree(@rect);
        push @{$N->[1]},$child;
        $self->QuadraticSplit($N->[1]) if @{$N->[1]} > $self->{M};
    }
}

# returns the leaf which contains the object, the index of the object
# in the leaf, and the parent of the leaf

sub get_leaf {
    my ($self,$object,$leaf,$index_of_leaf,$parent) = @_;
    $leaf = $self->{root} unless $leaf;
    for my $index (0..$#{$leaf->[1]}) {
        my $entry = $leaf->[1]->[$index];
        unless ($entry->[0]) {
            return ($parent,$index_of_leaf,$leaf,$index) if $entry->[1] == $object;
        } else {
            my @ret = $self->get_leaf($object,$entry,$index,$leaf);
            return @ret if @ret;
        }
    }
    return ();
}

sub set_bboxes {
    my ($self,$N) = @_;
    $N = $self->{root} unless $N;
    return @$N[2..5] if $N->[0] == 0;
    my @bbox;
    for my $child (@{$N->[1]}) {
        my @bbox_of_child = $self->set_bboxes($child);
        @bbox = @bbox ? enlarged_rect(@bbox_of_child,@bbox) : @bbox_of_child;
    }
    @$N[2..5] = @bbox;
    return @bbox;
}

sub remove {
    my ($self,$object) = @_;
    my ($parent,$index_of_leaf,$leaf,$index) = $self->get_leaf($object);

    return unless $leaf;

    # remove the object
    splice(@{$leaf->[1]},$index,1);

    # is the leaf too small now?
    if ($parent and @{$leaf->[1]} < $self->{m}) {

        # remove the leaf
        splice(@{$parent->[1]},$index_of_leaf,1);

        # is the parent now too small?
        if (@{$parent->[1]} < $self->{m}) {

            # yes, move the children up
            my @new_child_list;
            for my $entry (@{$parent->[1]}) {
                for my $child (@{$entry->[1]}) {
                    push @new_child_list,$child;
                }
            }
            $parent->[1] = [@new_child_list];

        }

        $self->set_bboxes();

        # reinsert the orphans
        for my $child (@{$leaf->[1]}) {
            my $N = $self->ChooseSubTree(@$child[2..5]);
            push @{$N->[1]},$child;
            $self->QuadraticSplit($N->[1]) if @{$N->[1]} > $self->{M};
        }

    } else {

        $self->set_bboxes();

    }
    delete $self->{root} unless defined $self->{root}->[2];
}

sub dump {
    my ($self,$N,$level) = @_;
    return unless $self->{root};
    $N = $self->{root} unless $N;
    return unless $N;
    $level = 0 unless $level;
    unless ($N->[0]) {
        print "($level) object $N $N->[1] rect @$N[2..5]\n";
    } else {
        print "($level) subtree $N $N->[1] rect @$N[2..5]\n";
        for my $entry (@{$N->[1]}) {
            $self->dump($entry,$level+1);
        }
    }
}

sub ChooseSubTree {
    my ($self,@rect) = @_;
    # CS1
    unless ($self->{root}) {
        $self->{root} = [1,[],@rect];
        return $self->{root};
    }
    my $N = $self->{root};
  CS2:
    @$N[2..5] = enlarged_rect(@$N[2..5],@rect);
#    print STDERR "N = $N, $N->[0], @{$N->[1]}\n";
    unless ($N->[1]->[0]->[0]) { # is leaf
        return $N;
    } else {
        my $chosen;
        my $needed_enlargement_of_chosen;
        my $area_of_chosen;
        for my $entry (@{$N->[1]}) {
            my @rect_of_entry = @$entry[2..5];
            my $area = area_of_rect(@rect_of_entry);
            my $needed_enlargement = area_of_rect(enlarged_rect(@rect_of_entry,@rect)) - $area;
            if (!$chosen or
                $needed_enlargement < $needed_enlargement_of_chosen or
                $area < $area_of_chosen)
            {
                $chosen = $entry;
                $needed_enlargement_of_chosen = $needed_enlargement;
                $area_of_chosen = $area;
            }
        }
        # CS3
        $N = $chosen;
        goto CS2;
    }
}

sub QuadraticSplit {
    my($self,$group) = @_;
    my($E1,$E2) = PickSeeds($group);
    $E2 = splice(@$group,$E2,1);
    $E1 = splice(@$group,$E1,1);
    $E1 = [1,[$E1],@$E1[2..5]];
    $E2 = [1,[$E2],@$E2[2..5]];
    do {
        DistributeEntry($group,$E1,$E2);
    } until @$group == 0 or
        @$E1 == $self->{M}-$self->{m}+1 or
        @$E2 == $self->{M}-$self->{m}+1;
    unless (@$group == 0) {
        if (@$E1 < @$E2) {
            while (@$group > 1) {
                add_to_group($E1,pop @$group);
            }
        } else {
            while (@$group > 1) {
                add_to_group($E2,pop @$group);
            }
        }
    }
    push @$group,($E1,$E2);
}

sub PickSeeds {
    my($group) = @_;
    my ($seed1,$seed2,$d,$e1);
    for ($e1 = 0; $e1 < @$group-1; $e1++) {
        my @rect1 = @{$group->[$e1]}[2..5];
        my $a1 = area_of_rect(@rect1);
        my $e2;
        for ($e2 = $e1+1; $e2 < @$group; $e2++) {
            my @rect2 = @{$group->[$e2]}[2..5];
            my @R = enlarged_rect(@rect1,@rect2);
            my $d_test = area_of_rect(@R) - $a1 - area_of_rect(@rect2);
            if (!$d or $d_test > $d) {
                $seed1 = min($e1,$e2);
                $seed2 = max($e1,$e2);
            }
        }
    }
    return ($seed1,$seed2);
}

sub DistributeEntry {
    my($from,$to1,$to2) = @_;
    my $area_of_to1 = area_of_rect(@$to1[2..5]);
    my $area_of_to2 = area_of_rect(@$to2[2..5]);
    my ($next,$area_of_enlarged1,$area_of_enlarged2) =
        PickNext($from,$to1,$to2,$area_of_to1,$area_of_to2);
    my $cmp = $area_of_enlarged1 - $area_of_to1 <=> $area_of_enlarged2 - $area_of_to2;
    $cmp = $area_of_to1 <=> $area_of_to2 if $cmp == 0;
    $cmp = @{$to1->[1]} <=> @{$to2->[1]} if $cmp == 0;
    if ($cmp <= 0) {
        add_to_group($to1,$from->[$next]);
        splice(@$from,$next,1);
    } elsif ($cmp > 0) {
        add_to_group($to2,$from->[$next]);
        splice(@$from,$next,1);
    }
}

sub PickNext {
    my($from,$to1,$to2,$area_of_to1,$area_of_to2) = @_;
    my $next;
    my $max_diff;
    my $area_of_enlarged1;
    my $area_of_enlarged2;
    my @cover_of_to1 = @$to1[2..5];
    my @cover_of_to2 = @$to2[2..5];
    for my $i (0..$#$from) {
        my $a1 = area_of_rect(enlarged_rect(@cover_of_to1,@{$from->[$i]}[2..5]));
        $area_of_enlarged1 = $a1 unless defined $area_of_enlarged1;
        my $a2 = area_of_rect(enlarged_rect(@cover_of_to2,@{$from->[$i]}[2..5]));
        $area_of_enlarged2 = $a2 unless defined $area_of_enlarged2;
        my $diff = abs(($area_of_enlarged1 - $area_of_to1) - ($area_of_enlarged2 - $area_of_to2));
        if (!$next or $diff > $max_diff) {
            $next = $i;
            $max_diff = $diff;
            $area_of_enlarged1 = $a1;
            $area_of_enlarged2 = $a2;
        }
    }
    return ($next,$area_of_enlarged1,$area_of_enlarged2);
}

sub add_to_group {
    my($to,$entry) = @_;
    push @{$to->[1]},$entry;
    @$to[2..5] = enlarged_rect(@$to[2..5],@$entry[2..5]);
}

sub enlarged_rect {
    return (min($_[0],$_[4]),min($_[1],$_[5]),max($_[2],$_[6]),max($_[3],$_[7]));
}

sub area_of_rect {
    ($_[3]-$_[1])*($_[2]-$_[0]);
}

sub min {
    $_[0] > $_[1] ? $_[1] : $_[0];
}

sub max {
    $_[0] > $_[1] ? $_[0] : $_[1];
}

1;
__END__
