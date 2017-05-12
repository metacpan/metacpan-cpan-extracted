# Name

Tree::VP - Vantage-Point Tree builder and searcher.

# Synopsis

A spellchecker.

    my @words = read_file("/usr/share/dict/words", { chomp => 1, binmode => ":utf8" });
    my $vptree = Tree::VP->new( distance => \&Text::Levenshtein::XS::distance );
    $vptree->build(\@words);

    my $r = $vptree->search(query => "amstedam", size => 5);
    say "suggestion: " . join " ", map { $_ . " (" . distance($_, $q) . ")" } @{$r->{values}};

# Methods

- new( distance => sub { ... })

    Construct the top-level tree object. The `distance` function must be able to calculate the distance between any 2
    values in the ArrayRef passed to `build` method. It must return a number range from 0 to Inf. The number "0" meaning
    that the 2 values are the same, and larger number means that the given 2 values are further away in space.

- build( ArrayRef\[ Val \] )

    Take a ArrayRef of values of whatever type that can be handled by the `distance` function, and build the tree
    structure.

- search( query => Val, size => Int )

    Take a "query", which is just a value of whatever type contained in the tree. And return HashRef that contains the
    results of top-K nearest nodes according to the distance function. `size` means the the upper-bound of result size.

- tree() (a public attribute)

    This points to the underlying tree data structure, which is an
    instance of [Tree::DAG\_Node](https://metacpan.org/pod/Tree::DAG_Node) . Since the creation process of VP trees
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

    Since we use [Tree::DAG\_Node](https://metacpan.org/pod/Tree::DAG_Node) objects, the `freeze` and `unfreeze`
    subroutine here needs be able to serealize and unserealize perl
    objects.  [Sereal](https://metacpan.org/pod/Sereal) is a good choice, but basically any subroutines
    that can convert [Tree::DAG\_Node](https://metacpan.org/pod/Tree::DAG_Node) objects to string and back, can be
    used. Obviously, the distance function must be the same in order to
    produce valid response.

# See Also

[http://en.wikipedia.org/wiki/Vantage-point\_tree](http://en.wikipedia.org/wiki/Vantage-point_tree)

# Author

Kang-min Liu <gugod@gugod.org>

# License

The MIT License.
