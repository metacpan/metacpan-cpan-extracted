package Tree::VP;
use v5.8;
our $VERSION = "0.05";

use Moo;
use List::Priority;
use Tree::DAG_Node;

has distance => (
    is => "ro",
    required => 1,
);

has tree => (
    is => "rw",
);

sub build {
    my ($self, $values) = @_;
    $self->tree( $self->_build_tree_maybe($values) ) if @$values;
    return $self;
}

sub _build_tree_maybe {
    my ($self, $values) = @_;
    my $node;
    if (@$values) {
        my $vp = shift @$values;
        my @v = ($vp);

        $node = Tree::DAG_Node->new({
            name => "$vp",
            attributes => { vp => $vp }
        });

        return $node unless @$values;

        my @dist = sort { $a->[1] <=> $b->[1] } map {[$_, $self->distance->($_, $vp)]} @$values;

        my $center = int( $#dist/2 );
        my (@left, @right, $min, $max);

        my $median = (@dist == 1)
        ? $dist[0][1] : (@dist % 2 == 1)
        ? $dist[$center][1] : ($dist[$center][1] + $dist[$center+1][1])/2;

        for (@dist) {
            if ($_->[1] == 0) {
                push @v, $_->[0];
            } elsif ($_->[1] < $median) {
                $min = $_->[1] if !defined($min);
                push @left, $_->[0];
            } else {
                push @right, $_->[0];
                $max = $_->[1];
            }
        }

        $node->attributes->{mu} = $median;
        $node->attributes->{distance_min} = $min;
        $node->attributes->{distance_max} = $max || $min || 0;

        if (@left) {
            if (my $node_left = $self->_build_tree_maybe(\@left)) {
                $node_left->attributes->{is_left_daughter} = 1;
                $node->add_daughter( $node_left );
            }
        }
        if (@right) {
            if (my $node_right = $self->_build_tree_maybe(\@right)) {
                $node_right->attributes->{is_right_daughter} = 1;
                $node->add_daughter( $node_right );
            }
        }
    }
    return $node;
}

sub search {
    my ($self, %args) = @_;
    $args{size} ||= 2;
    return $self->_search_tree( $self->tree, %args );
}

sub _search_tree {
    my ($self, $tree, %args)= @_;
    my $result = { values => [] };

    my ($left, $right) = $tree->daughters;
    if (!$right && $left && $left->{attributes}{is_right_daughter}) {
        $right = $left;
        $left = undef;
    }

    my $is_top_level = !defined($args{__pq});
    my $pq = $args{__pq} ||= List::Priority->new;

    my $v = $tree->attributes->{vp};
    my $d = $self->distance->($v, $args{query});

    $args{tau} = $tree->attributes->{distance_max} unless defined $args{tau};
    if ($d < $args{tau}) {
        $pq->insert($d, $v);
        if ($pq->size() > $args{size}) {
            $pq->pop();
            $args{tau} = $pq->highest_priority;
        }
    }

    if (defined($tree->attributes->{mu})) {
        my $mu = $tree->attributes->{mu};
        if ($d < $args{tau}) {
            if ($left && $tree->attributes->{distance_min} - $args{tau} < $d) {
                $self->_search_tree($left, %args);
                $args{tau} = $pq->highest_priority;
            }
            if ($right && $mu - $args{tau} < $d && $d < $tree->attributes->{distance_max} + $args{tau}) {
                $self->_search_tree($right, %args);
            }
        } else {
            if ($right && $d < $tree->attributes->{distance_max} + $args{tau}) {
                $self->_search_tree($right, %args);
                $args{tau} = $pq->highest_priority;
            }
            if ($left && $tree->attributes->{distance_min} - $args{tau} < $d && $d < $mu + $args{tau}) {
                $self->_search_tree($left, %args);
            }
        }
    }

    if ($is_top_level) {
        my @results;
        while ($pq->size() > 0) {
            my $d = $pq->lowest_priority;
            my $x = $pq->shift();
            push @results, {
                distance => $d,
                value    => $x,
            }
        }
        $result->{results} = \@results;
    }
    return $result;
}


1;

__END__

=head1 Name

Tree::VP - Vantage-Point Tree builder and searcher.

=head1 Synopsis

A spellchecker.

    my @words = read_file("/usr/share/dict/words", { chomp => 1, binmode => ":utf8" });
    my $vptree = Tree::VP->new( distance => \&Text::Levenshtein::XS::distance );
    $vptree->build(\@words);

    my $r = $vptree->search(query => "amstedam", size => 5);
    say "suggestion: " . join " ", map { $_ . " (" . distance($_, $q) . ")" } @{$r->{values}};


=head1 Methods

=over 4

=item new( distance => sub { ... })

Construct the top-level tree object. The C<distance> function must be able to calculate the distance between any 2
values in the ArrayRef passed to C<build> method. It must return a number range from 0 to Inf. The number "0" meaning
that the 2 values are the same, and larger number means that the given 2 values are further away in space.

=item build( ArrayRef[ Val ] )

Take a ArrayRef of values of whatever type that can be handled by the C<distance> function, and build the tree
structure.

=item search( query => Val, size => Int )

Take a "query", which is just a value of whatever type contained in the tree. And return HashRef that contains the
results of top-K nearest nodes according to the distance function. C<size> means the the upper-bound of result size.

=item tree() (a public attribute)

This points to the underlying tree data structure, which is an
instance of L<Tree::DAG_Node> . Since the creation process of VP trees
is expensive, it is desired to be able to store the tree structure and
re-use the stored state. To achieve this, do something like this:

    # Storing
    my $vptree = Tree::VP->new( distance => \&distance );
    $vptree->build(\@words);
    write_file("/db/tree_stored.db", freeze($vptree->tree));

    # Loading and use
    my $tree =  unfreeze(read_file("/db/tree_stored.db"));
    my $vptree = Tree::VP->new( tree => $tree, distance => \&distance );
    $vptree->search(...);

Since we use L<Tree::DAG_Node> objects, the C<freeze> and C<unfreeze>
subroutine here needs be able to serealize and unserealize perl
objects.  L<Sereal> is a good choice, but basically any subroutines
that can convert L<Tree::DAG_Node> objects to string and back, can be
used. Obviously, the distance function must be the same in order to
produce valid response.

=back

=head1 See Also

L<http://en.wikipedia.org/wiki/Vantage-point_tree>

=head1 Author

Kang-min Liu <gugod@gugod.org>

=head1 License

The MIT License.
