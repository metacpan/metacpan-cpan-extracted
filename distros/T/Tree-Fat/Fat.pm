use strict;
package Tree::Fat;

use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();
$VERSION = '1.111';

'Tree::Fat'->bootstrap($VERSION);

sub TIEHASH {
    bless Tree::Fat->new(), shift;
}

sub new_hash {
    my %fake;
    tie %fake, shift;
    \%fake;
}

*fetch = \&FETCH;
*clear = \&CLEAR;
*delete = \&DELETE;

1;
__END__

=head1 NAME

Tree::Fat - Perl Extension to Implement Fat-Node Trees

=head1 SYNOPSIS

This is not a plug-and-play perl extension.  This module is designed
for embedding (and there is no default embedding).

  1. tvgen.pl -p PREFIX

  2. Edit PREFIXtv.tmpl

  3. Compile and link into your own application!

=head1 DESCRIPTION

Implements object-oriented trees using algorithms adapted from b-trees
and AVL trees (without resorting to yucky C++).  Fat-node trees are
not the best for many niche applications but they do have excellent
all-terrain performance.

 TYPE       Speed       Flexibility  Scales     Memory   Keeps-Order
 ---------- ----------- ------------ ---------- -------- ------------
 Arrays     fastest     so-so        not good   MIN      yes
 Hashes     fast        good         so-so      so-so    no
 Fat-Trees  medium      silly        big        good     yes

=head1 WHAT IS A FAT-TREE?

It's a cross between a tree and an array.  Each tree node contains a
fixed length array of slots.  Tree performance is enhanced by
balancing array operations with tree operations.  Moreover, tree
operations are better optimized by taking the arrays into account.

=head1 HOW ABOUT PERSISTANCE?

F-Trees are designed for embedding.  (If you want I<persistent>
F-Trees without the work, then check out the C<ObjStore> extension by
the same author.  F-Trees are already integrated into the ObjectStore
database, right now!)

=head1 CURSOR BEHAVIOR

The only way to access a tree is via a cursor.  Cursors behavior is
derived from the principle of least-surprise (rather than greatest
efficiency).  More documentation there isn't.  Please read the source
code for more information.

=over 4

=item *

Both cursors and trees store a version number.  If you modify the same
tree with more than one cursor, you can get mismatched versions.  If
there is a mismatch, an exception is thrown.

=item *

If you allow duplicate keys, seek always returns the first key that
matches.  For example, the cursor will always match at the first
instance of 'c': (a,b,*c,c,c,d,e).

=back

=head1 EMBEDDING API

Flexibility is paramount.  The embedding API is much more flexible
than would be possible with C++ templates.  See C<tvcommon.*> &
C<tv.*>.

=head1 PERFORMANCE

=over 4

=item * Average Fill

The number elements in the collection divided by the number of
available slots.  Higher is better.  (Perl built-in hashes max out
around 50-60%.  Hash tables generally max out at around 70%.)

=item * Average Depth

The average number of nodes to be inspected during a search.  Lower is
better.

=item * Average Centering

Each fat-node is essentially an array of elements.  This array is
allocated contiguously from the available slots.  The best arrangement
(for insertions & deletions) is if the block of filled slots is
centered.

=back

=head1 REFERENCES

=over 4

=item * http://paris.lcs.mit.edu/~bvelez/std-colls/cacm/cacm-2455.html

Author: Foster, C. C. 

A generalization of AVL trees is proposed in which imbalances up to
(triangle shape) is a small integer. An experiment is performed to
compare these trees with standard AVL trees and with balanced trees on
the basis of mean retrieval time, of amount of restructuring expected,
and on the worst case of retrieval time. It is shown that, by
permitting imbalances of up to five units, the retrieval time is
increased a small amount while the amount of restructuring required is
decreased by a factor of ten. A few theoretical results are derived,
including the correction of an earlier paper, and are duly compared
with the experimental data. Reasonably good correspondence is found.

CACM August, 1973 

=item * http://www.imada.ou.dk/~kslarsen/Papers/AVL.html

  AVL Trees with Relaxed Balance 
  Kim S. Larsen 
  Proceedings of the 8th International Parallel Processing Symposium,
  pp. 888-893, IEEE Computer Society Press, 1994. 

AVL trees with relaxed balance were introduced with the aim of
improving runtime performance by allowing a greater degree of
concurrency. This is obtained by uncoupling updating from
rebalancing. An additional benefit is that rebalancing can be
controlled separately. In particular, it can be postponed completely
or partially until after peak working hours.

We define a new collection of rebalancing operations which allows for
a significantly greater degree of concurrency than the original
proposal. Additionally, in contrast to the original proposal, we prove
the complexity of our algorithm.  If N is the maximum size the tree
could ever have, we prove that each insertion gives rise to at most
floor(log_phi(N + 3/2) + log_phi(sqrt(5)) - 3) rebalancing operations
and that each deletion gives rise to at most floor(log_phi(N + 3/2) +
log_phi(sqrt(5)) - 4) rebalancing operations, where phi is the golden
ratio.

=back

=head1 PUBLIC SOURCE CODE

The source code is being released in a malleable form to encourage as
much testing as possible.  Bugs in fundemental collections are simply
UNACCEPTABLE and it is hard to trust a single vendor to debug their
code properly.

Get it via http://www.perl.com/CPAN/authors/id/JPRIT/ !

=head1 TODO

Optimize more!

Clean up refcnts in test scripts.

More documentation.

=head1 AUTHOR

Copyright © 1997-1999 Joshua Nathaniel Pritikin.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
