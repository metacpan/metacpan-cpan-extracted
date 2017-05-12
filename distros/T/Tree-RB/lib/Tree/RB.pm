package Tree::RB;

use strict;
use Carp;

use Tree::RB::Node qw[set_color color_of parent_of left_of right_of];
use Tree::RB::Node::_Constants;
use vars qw( $VERSION @EXPORT_OK );
$VERSION = '0.500005';
$VERSION = eval $VERSION;

require Exporter;
*import    = \&Exporter::import;
@EXPORT_OK = qw[LUEQUAL LUGTEQ LULTEQ LUGREAT LULESS LUNEXT LUPREV];

use enum qw{
    LUEQUAL
    LUGTEQ 
    LULTEQ 
    LUGREAT
    LULESS 
    LUNEXT 
    LUPREV 
};

# object slots
use enum qw{
    ROOT
    CMP 
    SIZE
    HASH_ITER
    HASH_SEEK_ARG
};

# Node and hash Iteration

sub _mk_iter {
    my $start_fn = shift || 'min';
    my $next_fn  = shift || 'successor';
    return sub {
        my $self = shift;
        my $key  = shift;
        my $node;
        my $iter = sub {
            if($node) {
                $node = $node->$next_fn;
            }
            else {
                if(defined $key) {
                    # seek to $key
                    (undef, $node) = $self->lookup(
                        $key, 
                        $next_fn eq 'successor' ? LUGTEQ : LULTEQ
                    );
                } 
                else {
                    $node = $self->$start_fn;
                }
            }
            return $node;
        };
        return bless($iter => 'Tree::RB::Iterator');
    };
}

*Tree::RB::Iterator::next = sub { $_[0]->() };

*iter     = _mk_iter(qw/min successor/);
*rev_iter = _mk_iter(qw/max predecessor/);

sub hseek {
    my $self = shift; 
    my $arg  = shift;
    defined $arg or croak("Can't seek to an undefined key");
    my %args;
    if(ref $arg eq 'HASH') {
        %args = %$arg;
    } 
    else {
        $args{-key} = $arg;
    }
    
    if(@_ && exists $args{-key}) {
        my $arg = shift;
        if(ref $arg eq 'HASH') {
            %args = (%$arg, %args);
        } 
    } 
    if(! exists $args{-key}) {
        defined $args{'-reverse'} or croak("Expected option '-reverse' is undefined");
    }
    $self->[HASH_SEEK_ARG] = \%args;
    if($self->[HASH_ITER]) {
        $self->_reset_hash_iter;
    } 
} 

sub _reset_hash_iter {
    my $self = shift; 
    if($self->[HASH_SEEK_ARG]) {
        my $iter = ($self->[HASH_SEEK_ARG]{'-reverse'} ? 'rev_iter' : 'iter');
        $self->[HASH_ITER] = $self->$iter($self->[HASH_SEEK_ARG]{'-key'});
    } 
    else {
        $self->[HASH_ITER] = $self->iter;
    }
} 

sub FIRSTKEY {
    my $self = shift; 
    $self->_reset_hash_iter;

    my $node = $self->[HASH_ITER]->next
      or return;
    return $node->[_KEY];
}

sub NEXTKEY {
    my $self = shift; 

    my $node = $self->[HASH_ITER]->next
      or return;
    return $node->[_KEY];
}

sub new {
    my ($class, $cmp) = @_;
    my $obj = [];
    $obj->[SIZE] = 0;
    if($cmp) {
        ref $cmp eq 'CODE'
          or croak('Invalid arg: codref expected');
        $obj->[CMP] = $cmp;
    }
    return bless $obj => $class;
}

*TIEHASH = \&new;

sub DESTROY { $_[0]->[ROOT]->DESTROY if $_[0]->[ROOT] }

sub CLEAR {
    my $self = shift; 
    if($self->[ROOT]) {
        $self->[ROOT]->DESTROY;
        undef $self->[ROOT];
        undef $self->[HASH_ITER];
        $self->[SIZE] = 0;
    }
}

sub UNTIE {
    my $self = shift; 
    $self->DESTROY;
    undef @$self;
}

sub resort {
    my $self = $_[0];
    my $cmp  = $_[1];
    ref $cmp eq 'CODE'
      or croak sprintf(q[Arg of type coderef required; got %s], ref $cmp || 'undef');

    my $new_tree = __PACKAGE__->new($cmp);
    $self->[ROOT]->strip(sub { $new_tree->put($_[0]) });
    $new_tree->put(delete $self->[ROOT]);
    $_[0] = $new_tree;
}

sub root { $_[0]->[ROOT] }
sub size { $_[0]->[SIZE] }

*SCALAR = \&size;

sub min {
    my $self = shift;
    return undef unless $self->[ROOT];
    return $self->[ROOT]->min;
}

sub max {
    my $self = shift;
    return undef unless $self->[ROOT];
    return $self->[ROOT]->max;
}

sub lookup {
    my $self = shift;
    my $key  = shift;
    defined $key
      or croak("Can't use undefined value as key");
    my $mode = shift || LUEQUAL;
    my $cmp = $self->[CMP];

    my $y;
    my $x = $self->[ROOT]
      or return;
    my $next_child;
    while($x) {
        $y = $x;
        if($cmp ? $cmp->($key, $x->[_KEY]) == 0
                : $key eq $x->[_KEY]) {
            # found it!
            if($mode == LUGREAT || $mode == LUNEXT) {
                $x = $x->successor;
            }
            elsif($mode == LULESS || $mode == LUPREV) {
                $x = $x->predecessor;
            }
            return wantarray
              ? ($x->[_VAL], $x)
              : $x->[_VAL];
        }
        if($cmp ? $cmp->($key, $x->[_KEY]) < 0
                : $key lt $x->[_KEY]) {
            $next_child = _LEFT;
        }
        else {
            $next_child = _RIGHT;
        }
        $x = $x->[$next_child];
    }
    # Didn't find it :(
    if($mode == LUGTEQ || $mode == LUGREAT) {
        if($next_child == _LEFT) {
            return wantarray ? ($y->[_VAL], $y) : $y->[_VAL];
        }
        else {
            my $next = $y->successor
              or return;
            return wantarray ? ($next->[_VAL], $next) : $next->[_VAL];
        }
    }
    elsif($mode == LULTEQ || $mode == LULESS) {
        if($next_child == _RIGHT) {
            return wantarray ? ($y->[_VAL], $y) : $y->[_VAL];
        }
        else {
            my $next = $y->predecessor
              or return;
            return wantarray ? ($next->[_VAL], $next) : $next->[_VAL];
        }
    }
    return;
}

*FETCH = \&lookup;
*get   = \&lookup;

sub nth {
    my ($self, $i) = @_;

    $i =~ /^-?\d+$/
      or croak('Integer index expected');
    if ($i < 0) {
        $i += $self->[SIZE];
    }
    if ($i < 0 || $i >= $self->[SIZE]) {
        return;
    }

    my ($node, $next, $moves);
    if ($i > $self->[SIZE] / 2) {
        $node = $self->max;
        $next = 'predecessor';
        $moves = $self->[SIZE] - $i - 1;
    }
    else {
        $node = $self->min;
        $next = 'successor';
        $moves = $i;
    }

    my $count = 0;
    while ($count != $moves) {
        $node = $node->$next;
        ++$count;
    }
    return $node;
}

sub EXISTS {
    my $self = shift;
    my $key  = shift;
    return defined $self->lookup($key);
}

sub put {
    my $self = shift;
    my $key_or_node = shift;
    defined $key_or_node
      or croak("Can't use undefined value as key or node");
    my $val = shift;

    my $cmp = $self->[CMP];
    my $z = (ref $key_or_node eq 'Tree::RB::Node')
              ? $key_or_node
              : Tree::RB::Node->new($key_or_node => $val);

    my $y;
    my $x = $self->[ROOT];
    while($x) {
        $y = $x;
        # Handle case of inserting node with duplicate key.
        if($cmp ? $cmp->($z->[_KEY], $x->[_KEY]) == 0
                : $z->[_KEY] eq $x->[_KEY])
        {
            my $old_val = $x->[_VAL];
            $x->[_VAL] = $z->[_VAL];
            return $old_val;
        }

        if($cmp ? $cmp->($z->[_KEY], $x->[_KEY]) < 0
                : $z->[_KEY] lt $x->[_KEY])
        {
            $x = $x->[_LEFT];
        }
        else {
            $x = $x->[_RIGHT];
        }
    }
    # insert new node
    $z->[_PARENT] = $y;
    if(not defined $y) {
        $self->[ROOT] = $z;
    }
    else {
        if($cmp ? $cmp->($z->[_KEY], $y->[_KEY]) < 0
                : $z->[_KEY] lt $y->[_KEY])
        {
            $y->[_LEFT] = $z;
        }
        else {
            $y->[_RIGHT] = $z;
        }
    }
    $self->_fix_after_insertion($z);
    $self->[SIZE]++;
}

*STORE = \&put;

sub _fix_after_insertion {
    my $self = shift;
    my $x = shift or croak('Missing arg: node');

    $x->[_COLOR] = RED;
    while($x != $self->[ROOT] && $x->[_PARENT][_COLOR] == RED) {
        my ($child, $rotate1, $rotate2);
        if(($x->[_PARENT] || 0) == ($x->[_PARENT][_PARENT][_LEFT] || 0)) {
            ($child, $rotate1, $rotate2) = (_RIGHT, '_left_rotate', '_right_rotate');
        }
        else {
            ($child, $rotate1, $rotate2) = (_LEFT, '_right_rotate', '_left_rotate');
        }
        my $y = $x->[_PARENT][_PARENT][$child];

        if($y && $y->[_COLOR] == RED) {
            $x->[_PARENT][_COLOR] = BLACK;
            $y->[_COLOR] = BLACK;
            $x->[_PARENT][_PARENT][_COLOR] = RED;
            $x = $x->[_PARENT][_PARENT];
        }
        else {
            if($x == ($x->[_PARENT][$child] || 0)) {
                $x = $x->[_PARENT];
                $self->$rotate1($x);
            }
            $x->[_PARENT][_COLOR] = BLACK;
            $x->[_PARENT][_PARENT][_COLOR] = RED;
            $self->$rotate2($x->[_PARENT][_PARENT]);
        }
    }
    $self->[ROOT][_COLOR] = BLACK;
}

sub delete {
    my ($self, $key_or_node) = @_;
    defined $key_or_node
      or croak("Can't use undefined value as key or node");

    my $z = (ref $key_or_node eq 'Tree::RB::Node')
              ? $key_or_node
              : ($self->lookup($key_or_node))[1];
    return unless $z;

    my $y;
    if($z->[_LEFT] && $z->[_RIGHT]) {
        # (Notes kindly provided by Christopher Gurnee)
        # When deleting a node 'z' which has two children from a binary search tree, the
        # typical algorithm is to delete the successor node 'y' instead (which is
        # guaranteed to have at most one child), and then to overwrite the key/values of
        # node 'z' (which is still in the tree) with the key/values (which we don't want
        # to lose) from the now-deleted successor node 'y'.

        # Since we need to return the deleted item, it's not good enough to overwrite the
        # key/values of node 'z' with those of node 'y'. Instead we swap them so we can
        # return the deleted values.

        $y = $z->successor;
        ($z->[_KEY], $y->[_KEY]) = ($y->[_KEY], $z->[_KEY]);
        ($z->[_VAL], $y->[_VAL]) = ($y->[_VAL], $z->[_VAL]);
    }
    else {
        $y = $z;
    }

    # splice out $y
    my $x = $y->[_LEFT] || $y->[_RIGHT];
    if(defined $x) {
        $x->[_PARENT] = $y->[_PARENT];
        if(! defined $y->[_PARENT]) {
            $self->[ROOT] = $x;
        }
        elsif($y == $y->[_PARENT][_LEFT]) {
            $y->[_PARENT][_LEFT] = $x;
        }
        else {
            $y->[_PARENT][_RIGHT] = $x;
        }
        # Null out links so they are OK to use by _fix_after_deletion
        delete @{$y}[_PARENT, _LEFT, _RIGHT];

        # Fix replacement
        if($y->[_COLOR] == BLACK) {
            $self->_fix_after_deletion($x);
        }
    }
    elsif(! defined $y->[_PARENT]) {
        # return if we are the only node
        delete $self->[ROOT];
    }
    else {
        # No children. Use self as phantom replacement and unlink
        if($y->[_COLOR] == BLACK) {
            $self->_fix_after_deletion($y);
        }
        if(defined $y->[_PARENT]) {
            no warnings 'uninitialized';
            if($y == $y->[_PARENT][_LEFT]) {
                delete $y->[_PARENT][_LEFT];
            }
            elsif($y == $y->[_PARENT][_RIGHT]) {
                delete $y->[_PARENT][_RIGHT];
            }
            delete $y->[_PARENT];
        }
    }
    $self->[SIZE]--;
    return $y;
}

*DELETE = \&delete;

sub _fix_after_deletion {
    my $self = shift;
    my $x = shift or croak('Missing arg: node');

    while($x != $self->[ROOT] && color_of($x) == BLACK) {
        my ($child1, $child2, $rotate1, $rotate2);
        no warnings 'uninitialized';
        if($x == left_of(parent_of($x))) {
            ($child1,    $child2,   $rotate1,       $rotate2) =
            (\&right_of, \&left_of, '_left_rotate', '_right_rotate');
        }
        else {
            ($child1,   $child2,    $rotate1,        $rotate2) =
            (\&left_of, \&right_of, '_right_rotate', '_left_rotate');
        }
        use warnings;

        my $w = $child1->(parent_of($x));
        if(color_of($w) == RED) {
            set_color($w, BLACK);
            set_color(parent_of($x), RED);
            $self->$rotate1(parent_of($x));
            $w = right_of(parent_of($x));
        }
        if(color_of($child2->($w)) == BLACK &&
           color_of($child1->($w)) == BLACK) {
            set_color($w, RED);
            $x = parent_of($x);
        }
        else {
            if(color_of($child1->($w)) == BLACK) {
                set_color($child2->($w), BLACK);
                set_color($w, RED);
                $self->$rotate2($w);
                $w = $child1->(parent_of($x));
            }
            set_color($w, color_of(parent_of($x)));
            set_color(parent_of($x), BLACK);
            set_color($child1->($w), BLACK);
            $self->$rotate1(parent_of($x));
            $x = $self->[ROOT];
        }
    }
    set_color($x, BLACK);
}

sub _left_rotate {
    my $self = shift;
    my $x = shift or croak('Missing arg: node');

    my $y = $x->[_RIGHT]
      or return;
    $x->[_RIGHT] = $y->[_LEFT];
    if($y->[_LEFT]) {
        $y->[_LEFT]->[_PARENT] = $x;
    }
    $y->[_PARENT] = $x->[_PARENT];
    if(not defined $x->[_PARENT]) {
        $self->[ROOT] = $y;
    }
    else {
        $x == $x->[_PARENT]->[_LEFT]
          ? $x->[_PARENT]->[_LEFT]  = $y
          : $x->[_PARENT]->[_RIGHT] = $y;
    }
    $y->[_LEFT]   = $x;
    $x->[_PARENT] = $y;
}

sub _right_rotate {
    my $self = shift;
    my $y = shift or croak('Missing arg: node');

    my $x = $y->[_LEFT]
      or return;
    $y->[_LEFT] = $x->[_RIGHT];
    if($x->[_RIGHT]) {
        $x->[_RIGHT]->[_PARENT] = $y
    }
    $x->[_PARENT] = $y->[_PARENT];
    if(not defined $y->[_PARENT]) {
        $self->[ROOT] = $x;
    }
    else {
        $y == $y->[_PARENT]->[_RIGHT]
          ? $y->[_PARENT]->[_RIGHT] = $x
          : $y->[_PARENT]->[_LEFT]  = $x;
    }
    $x->[_RIGHT] = $y;
    $y->[_PARENT] = $x;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Tree::RB - Perl implementation of the Red/Black tree, a type of balanced binary search tree. 


=head1 SYNOPSIS

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

=head1 DESCRIPTION

This is a Perl implementation of the Red/Black tree, a type of balanced binary search tree. 

A tied hash interface is also provided to allow ordered hashes to be used.

See the Wikipedia article at L<http://en.wikipedia.org/wiki/Red-black_tree> for further information about Red/Black trees.


=head1 INTERFACE

=head2 new([CODEREF])

Creates and returns a new tree. If a reference to a subroutine is passed to
new(), the subroutine will be used to override the tree's default lexical
ordering and provide a user a defined ordering. 

This subroutine should be just like a comparator subroutine used with L<sort>, 
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

=head2 resort(CODEREF)

Changes the ordering of nodes within the tree. The new ordering is
specified by a comparator subroutine which must be passed to resort().

See L</new> for further information about the comparator.

=head2 size()

Returns the number of nodes in the tree.

=head2 root()

Returns the root node of the tree. This will either be undef
if no nodes have been added to the tree, or a L<Tree::RB::Node> object.
See the L<Tree::RB::Node> manual page for details on the Node object.

=head2 min()

Returns the node with the minimal key.

=head2 max()

Returns the node with the maximal key.

=head2 nth(INDEX)

Returns the node at the given (zero based) index, or undef if there is no node at that index. Negative indexes can be used, with -1 indicating the last node, -2 the penultimate node and so on.

=head2 lookup(KEY, [MODE])

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

=over

=item LUEQUAL

This is the default mode. Returns the node exactly matching the key, or C<undef> if not found. 

=item LUGTEQ

Returns the node exactly matching the specified key, 
if this is not found then the next node that is greater than the specified key is returned.

=item LULTEQ

Returns the node exactly matching the specified key, 
if this is not found then the next node that is less than the specified key is returned.

=item LUGREAT

Returns the node that is just greater than the specified key - not equal to. 
This mode is similar to LUNEXT except that the specified key need not exist in the tree.

=item LULESS

Returns the node that is just less than the specified key - not equal to. 
This mode is similar to LUPREV except that the specified key need not exist in the tree.

=item LUNEXT

Looks for the key specified, if not found returns C<undef>. 
If the node is found returns the next node that is greater than 
the one found (or C<undef> if there is no next node). 

This can be used to step through the tree in order.

=item LUPREV

Looks for the key specified, if not found returns C<undef>. 
If the node is found returns the previous node that is less than 
the one found (or C<undef> if there is no previous node). 

This can be used to step through the tree in reverse order.

=back

=head2 get(KEY)

get() is an alias for lookup().

=head2 iter([KEY])

Returns an iterator object that can be used to traverse the tree in order.

The iterator object supports a 'next' method that returns the next node in the
tree or undef if all of the nodes have been visited.

See the synopsis for an example.

If a key is supplied, the iterator returned will traverse the tree in order starting from
the node with key greater than or equal to the specified key.

    $it = $tree->iter('France');
    my $node = $it->next;
    print $node->key; # -> 'France'

=head2 rev_iter([KEY])

Returns an iterator object that can be used to traverse the tree in reverse order.

If a key is supplied, the iterator returned will traverse the tree in order starting from
the node with key less than or equal to the specified key.

    $it = $tree->rev_iter('France');
    my $node = $it->next;
    print $node->key; # -> 'France'

    $it = $tree->rev_iter('Finland');
    my $node = $it->next;
    print $node->key; # -> 'England'

=head2 hseek(KEY, [{-reverse => 1|0}])

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

=head2 put(KEY, VALUE)

Adds a new node to the tree. 

The first argument is the key of the node, the second is its value. 

If a node with that key already exists, its value is replaced with 
the given value and the old value is returned. Otherwise, undef is returned.

=head2 delete(KEY)

If the tree has a node with the specified key, that node is
deleted from the tree and returned, otherwise C<undef> is returned.


=head1 DEPENDENCIES

L<enum>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests via the GitHub web interface at 
L<https://github.com/arunbear/perl5-red-black-tree/issues>.

=head1 AUTHOR

Arun Prasad  C<< <arunbear@cpan.org> >>

Some documentation has been borrowed from Benjamin Holzman's L<Tree::RedBlack>
and Damian Ivereigh's libredblack (L<http://libredblack.sourceforge.net/>).

=head1 ACKNOWLEDGEMENTS

Thanks for bug reports go to Anton Petrusevich, Wes Thompson, Petre Mierlutiu, Tomer Vromen and Christopher Gurnee.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Arun Prasad C<< <arunbear@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

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
