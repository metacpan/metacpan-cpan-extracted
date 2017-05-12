package XML::DifferenceMarkup;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration	use XML::DifferenceMarkup ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
				   make_diff
				   merge_diff
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '1.05';

require XSLoader;
XSLoader::load('XML::DifferenceMarkup', $VERSION);

sub make_diff {
    my ($d1, $d2) = @_;

    my $m = $d1->documentElement;
    my $n = $d2->documentElement;
    return XML::DifferenceMarkup::_make_diff($m, $n);
}

sub merge_diff {
    my ($src_doc, $diff_doc) = @_;

    my $n = $diff_doc->documentElement;
    return XML::DifferenceMarkup::_merge_diff($src_doc, $n);
}

1;

__END__

=head1 NAME

XML::DifferenceMarkup - XML diff and merge

=head1 SYNOPSIS

 use XML::DifferenceMarkup qw(make_diff);
 use XML::LibXML;

 $parser = XML::LibXML->new(keep_blanks => 0, load_ext_dtd => 0);
 $d1 = $parser->parse_file($fname1);
 $d2 = $parser->parse_file($fname2);

 $dom = make_diff($d1, $d2);
 print $dom->toString(1);

=head1 DESCRIPTION

This module implements an XML diff producing XML output. Both input
and output are DOM documents, as implemented by XML::LibXML.

The diff format used by XML::DifferenceMarkup is meant to be
human-readable (i.e. simple, as opposed to short) - basically the diff
is a subset of the input trees, annotated with instruction element
nodes specifying how to convert the source tree to the target by
inserting and deleting nodes. To prevent name colisions with input
trees, all added elements are in a namespace
C<http://www.locus.cz/diffmark> (the diff will fail on
input trees which already use that namespace).

The top-level node of the diff is always <diff/> (or rather <dm:diff
xmlns:dm="http://www.locus.cz/diffmark"> ... </dm:diff> -
this description omits the namespace specification from now on);
under it are fragments of the input trees and instruction nodes:
<insert/>, <delete/> and <copy/>. <copy/> is used in places where the
input subtrees are the same - in the limit, the diff of 2 identical
documents is

 <?xml version="1.0"?>
 <dm:diff xmlns:dm="http://www.locus.cz/diffmark">
   <dm:copy count="1"/>
 </dm:diff>

(copy always has the count attribute and no other content). <insert/>
and <delete/> have the obvious meaning - in the limit a diff of 2
documents which have nothing in common is something like

 <?xml version="1.0"?>
 <dm:diff xmlns:dm="http://www.locus.cz/diffmark">
   <dm:delete>
     <old/>
   </dm:delete>
   <dm:insert>
     <new>
       <tree>with the whole subtree, of course</tree>
     </new>
   </dm:insert>
 </dm:diff>

A combination of <insert/>, <delete/> and <copy/> can capture any
difference, but it's sub-optimal for the case where (for example) the
top-level elements in the two input documents differ while their
subtrees are exactly the same. This case is handled by putting the
element from the second document into the diff, adding to it a special
attribute dm:update (whose value is the element name from the first
document) marking the element change:

 <?xml version="1.0"?>
 <dm:diff xmlns:dm="http://www.locus.cz/XML/diffmark">
   <top-of-second dm:update="top-of-first">
     <dm:copy count="42"/>
   </top-of-second>
 </dm:diff>

<delete/> contains just one level of nested nodes - their subtrees are
not included in the diff (but the element nodes which are included
always come with all their attributes). <insert/> and <delete/> don't
have any attributes and always contain some subtree.

Instruction nodes are never nested; all nodes above an instruction
node (except the top-level <diff/>) come from the input trees. A node
from the second input tree might be included in the output diff to
provide context for instruction nodes when it's an element node whose
subtree is not the same in the two input documents. When such an
element has the same name, attributes (names and values) and namespace
declarations in both input documents, it's always included in the diff
(its different output trees guarantee that it will have some chindren
there). If the corresponding elements are different, the one from the
second document might still be included, with an added dm:update
attribute, provided that both corresponding elements have non-empty
subtrees, and these subtrees are so similar that deleting the first
corresponding element and inserting the second would lead to a larger
diff. And if this paragraph seems too complicated, don't despair -
just ignore it and look at some examples.

=head1 FUNCTIONS

Note that XML::DifferenceMarkup functions must be explicitly imported
(i.e. with C<use XML::DifferenceMarkup qw(make_diff merge_diff);>)
before they can be called.

=head2 make_diff

C<make_diff> takes 2 parameters (the input documents) and produces
their diff. Note that the diff is asymmetric - C<make_diff($a, $b)> is
different from C<make_diff($b, $a)>.

=head2 merge_diff

C<merge_diff> takes the first document passed to C<make_diff> and its
return value and produces the second document. (More-or-less - the
document isn't canonicalized, so opinions on its "equality" may
differ.)

=head2 Error Handling

Both C<make_diff> and C<merge_diff> throw exceptions on invalid input
- their own exceptions as well as exceptions thrown by
XML::LibXML. These exceptions can usually (probably not always, though
- it used to be possible to construct an input which would crash the
calling process) be catched by calling the functions from an eval
block.

=head1 BUGS

=over

=item * information outside the document element is not processed

=back

=head1 AUTHOR

Vaclav Barta <vbar@comp.cz>

=head1 SEE ALSO

L<XML::LibXML>

=cut

