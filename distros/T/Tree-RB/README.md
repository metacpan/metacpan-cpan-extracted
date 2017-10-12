# NAME

Tree::RB - Perl implementation of the Red/Black tree, a type of balanced binary search tree. 

# SYNOPSIS

    use Tree::RB;

    my $tree = Tree::RB->new;
    $tree->put('France'  => 'Paris');
    $tree->put('England' => 'London');
    $tree->put('Hungary' => 'Budapest');
    $tree->put('Ireland' => 'Dublin');
    $tree->put('Egypt'   => 'Cairo');
    $tree->put('Germany' => 'Berlin');

    $tree->put('Alaska' => 'Anchorage'); # D'oh! Alaska isn't a Country
    $tree->delete('Alaska');

    print scalar $tree->get('Ireland'); # 'Dublin'

    print $tree->size; # 6
    print $tree->min->key; # 'Egypt' 
    print $tree->max->key; # 'Ireland' 

    print $tree->nth(0)->key;  # 'Egypt' 
    print $tree->nth(-1)->key; # 'Ireland' 

    # print items, ordered by key
    my $it = $tree->iter;

    while(my $node = $it->next) {
        printf "key = %s, value = %s\n", $node->key, $node->val;
    }

    # print items in reverse order
    $it = $tree->rev_iter;

    while(my $node = $it->next) {
        printf "key = %s, value = %s\n", $node->key, $node->val;
    }

    # Hash interface
    tie my %capital, 'Tree::RB';

    # or do this to store items in descending order 
    tie my %capital, 'Tree::RB', sub { $_[1] cmp $_[0] };

    $capital{'France'}  = 'Paris';
    $capital{'England'} = 'London';
    $capital{'Hungary'} = 'Budapest';
    $capital{'Ireland'} = 'Dublin';
    $capital{'Egypt'}   = 'Cairo';
    $capital{'Germany'} = 'Berlin';

    # print items in order
    while(my ($key, $val) = each %capital) {
        printf "key = $key, value = $val\n";
    }

# DESCRIPTION

This is a Perl implementation of the Red/Black tree, a type of balanced binary search tree. 

A tied hash interface is also provided to allow ordered hashes to be used.

See the Wikipedia article at [http://en.wikipedia.org/wiki/Red-black\_tree](http://en.wikipedia.org/wiki/Red-black_tree) for further information about Red/Black trees.

# INTERFACE

## new(\[CODEREF\])

Creates and returns a new tree. If a reference to a subroutine is passed to
new(), the subroutine will be used to override the tree's default lexical
ordering and provide a user a defined ordering. 

This subroutine should be just like a comparator subroutine used with [sort](https://metacpan.org/pod/sort), 
except that it doesn't do the $a, $b trick.

For example, to get a case insensitive ordering

    my $tree = Tree::RB->new(sub { lc $_[0] cmp lc $_[1]});
    $tree->put('Wall'  => 'Larry');
    $tree->put('Smith' => 'Agent');
    $tree->put('mouse' => 'micky');
    $tree->put('duck'  => 'donald');

    my $it = $tree->iter;

    while(my $node = $it->next) {
        printf "key = %s, value = %s\n", $node->key, $node->val;
    }

## resort(CODEREF)

Changes the ordering of nodes within the tree. The new ordering is
specified by a comparator subroutine which must be passed to resort().

See ["new"](#new) for further information about the comparator.

## size()

Returns the number of nodes in the tree.

## root()

Returns the root node of the tree. This will either be undef
if no nodes have been added to the tree, or a [Tree::RB::Node](https://metacpan.org/pod/Tree::RB::Node) object.
See the [Tree::RB::Node](https://metacpan.org/pod/Tree::RB::Node) manual page for details on the Node object.

## min()

Returns the node with the minimal key.

## max()

Returns the node with the maximal key.

## nth(INDEX)

Returns the node at the given (zero based) index, or undef if there is no node at that index. Negative indexes can be used, with -1 indicating the last node, -2 the penultimate node and so on.

## lookup(KEY, \[MODE\])

When called in scalar context, lookup(KEY) returns the value
associated with KEY.

When called in list context, lookup(KEY) returns a list whose first
element is the value associated with KEY, and whose second element
is the node containing the key/value.

An optional MODE parameter can be passed to lookup() to influence
which key is returned.

The values of MODE are constants that are exported on demand by
Tree::RB

    use Tree::RB qw[LUEQUAL LUGTEQ LULTEQ LUGREAT LULESS LUNEXT LUPREV];

- LUEQUAL

    This is the default mode. Returns the node exactly matching the key, or `undef` if not found. 

- LUGTEQ

    Returns the node exactly matching the specified key, 
    if this is not found then the next node that is greater than the specified key is returned.

- LULTEQ

    Returns the node exactly matching the specified key, 
    if this is not found then the next node that is less than the specified key is returned.

- LUGREAT

    Returns the node that is just greater than the specified key - not equal to. 
    This mode is similar to LUNEXT except that the specified key need not exist in the tree.

- LULESS

    Returns the node that is just less than the specified key - not equal to. 
    This mode is similar to LUPREV except that the specified key need not exist in the tree.

- LUNEXT

    Looks for the key specified, if not found returns `undef`. 
    If the node is found returns the next node that is greater than 
    the one found (or `undef` if there is no next node). 

    This can be used to step through the tree in order.

- LUPREV

    Looks for the key specified, if not found returns `undef`. 
    If the node is found returns the previous node that is less than 
    the one found (or `undef` if there is no previous node). 

    This can be used to step through the tree in reverse order.

## get(KEY)

get() is an alias for lookup().

## iter(\[KEY\])

Returns an iterator object that can be used to traverse the tree in order.

The iterator object supports a 'next' method that returns the next node in the
tree or undef if all of the nodes have been visited.

See the synopsis for an example.

If a key is supplied, the iterator returned will traverse the tree in order starting from
the node with key greater than or equal to the specified key.

    $it = $tree->iter('France');
    my $node = $it->next;
    print $node->key; # -> 'France'

## rev\_iter(\[KEY\])

Returns an iterator object that can be used to traverse the tree in reverse order.

If a key is supplied, the iterator returned will traverse the tree in order starting from
the node with key less than or equal to the specified key.

    $it = $tree->rev_iter('France');
    my $node = $it->next;
    print $node->key; # -> 'France'

    $it = $tree->rev_iter('Finland');
    my $node = $it->next;
    print $node->key; # -> 'England'

## hseek(KEY, \[{-reverse => 1|0}\])

For tied hashes, determines the next entry to be returned by each.

    tie my %capital, 'Tree::RB';

    $capital{'France'}  = 'Paris';
    $capital{'England'} = 'London';
    $capital{'Hungary'} = 'Budapest';
    $capital{'Ireland'} = 'Dublin';
    $capital{'Egypt'}   = 'Cairo';
    $capital{'Germany'} = 'Berlin';
    tied(%capital)->hseek('Germany');

    ($key, $val) = each %capital;
    print "$key, $val"; # -> Germany, Berlin 

The direction of iteration can be reversed by passing a hashref with key '-reverse' and value 1
to hseek after or instead of KEY, e.g. to iterate over the hash in reverse order:

    tied(%capital)->hseek({-reverse => 1});
    $key = each %capital;
    print $key; # -> Ireland 

The following calls are equivalent

    tied(%capital)->hseek('Germany', {-reverse => 1});
    tied(%capital)->hseek({-key => 'Germany', -reverse => 1});

## put(KEY, VALUE)

Adds a new node to the tree. 

The first argument is the key of the node, the second is its value. 

If a node with that key already exists, its value is replaced with 
the given value and the old value is returned. Otherwise, undef is returned.

## delete(KEY)

If the tree has a node with the specified key, that node is
deleted from the tree and returned, otherwise `undef` is returned.

# DEPENDENCIES

[enum](https://metacpan.org/pod/enum)

# INCOMPATIBILITIES

None reported.

# BUGS AND LIMITATIONS

Please report any bugs or feature requests via the GitHub web interface at 
[https://github.com/arunbear/perl5-red-black-tree/issues](https://github.com/arunbear/perl5-red-black-tree/issues).

# AUTHOR

Arun Prasad  `<arunbear@cpan.org>`

Some documentation has been borrowed from Benjamin Holzman's [Tree::RedBlack](https://metacpan.org/pod/Tree::RedBlack)
and Damian Ivereigh's libredblack ([http://libredblack.sourceforge.net/](http://libredblack.sourceforge.net/)).

# ACKNOWLEDGEMENTS

Thanks for bug reports go to Anton Petrusevich, Wes Thompson, Petre Mierlutiu, Tomer Vromen, Christopher Gurnee and Ole Bjorn Hessen.

# LICENCE AND COPYRIGHT

Copyright (c) 2007, Arun Prasad `<arunbear@cpan.org>`. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
