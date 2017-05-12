package Tree::Ternary_XS;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.04';

bootstrap Tree::Ternary_XS $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Ternary_XS - Perl extension implementing ternary search trees.

=head1 SYNOPSIS

  use Tree::Ternary_XS;
  $obj = new Tree::Ternary_XS;

  $obj->insert($str);

  $obj->search($str);

  $obj->nodes();
  $obj->terminals();

  $cnt = $obj->pmsearch($char, $str);
  @list = $obj->pmsearch($char, $str);

  $cnt = $obj->nearsearch($dist, $str);
  @list = $obj->nearsearch($dist, $str);

  @list = $obj->traverse();


=head1 DESCRIPTION

Tree::Ternary_XS is a Perl interface to a C implementation of ternary
search trees as described by Jon Bentley and Robert Sedgewick.
Ternary search trees are interesting data structures that provide a
means of storing and accessing strings. They combine the time
efficiency of digital tries with the space efficiency of binary search
trees. Unlike a hash, they also maintain information about relative
order.

This module is an adaptation from the C implementation published in
Bentley and Sedgewick's article in the April 1998 issue of Dr. Dobb's
Journal (see SEE ALSO). This module attempts to recreate the interface
as much as possible of Mark Rogaski's Tree::Ternary, a pure Perl
implementation. As Tree::Ternary_XS uses C code, it has important
space and speed advantages over Tree::Ternary.

=head1 METHODS

=head2 new()

Creates a new Tree::Ternary object. 

=head2 insert( STRING )

Inserts STRING into the tree. When a string is inserted, a scalar
variable is created to hold whatever data you may wish to associate
with the string.  A reference to this scalar is returned on a
successful insert. If the string is already in the tree, undef is
returned.

=head2 search( STRING )

Searches for the presence of STRING in the tree. If the string is
found, a reference to the associated scalar is returned, otherwise
undef is returned.

=head2 nodes()

Returns the total number of nodes in the tree. This count does not
include terminal nodes.

=head2 terminals()

Returns the total number of terminal nodes in the tree.

=head2 pmsearch( CHAR, STRING )

Performs a pattern match for STRING against the tree, using CHAR as a
wildcard character. The wildcard will match any characters. For
example, if '.' was specified as the wildcard, and STRING was the
pattern ".a.a.a." would match "bananas" and "pajamas" (if they were
both stored in the tree). In a scalar context, returns the count of
matches found. In an array context, returns a list of the matched
strings.

=head2 nearsearch( DISTANCE, STRING )

Searches for all strings in a tree that differ from STRING by DISTANCE
or fewer characters. In a scalar context, returns the count of matches
found. In an array context, returns a list of the matched strings.

=head2 traverse()

Simply returns a sorted list of the strings stored in the tree. This
method will do more tricks in the future.

=head1 NOTES

=head2 Character Set

Tree::Ternary_XS currently only has support for strings not containing
the null character.

=head2 Incompatibilities

There are a number of differences between Tree::Ternary and
Tree::Ternary_XS:

The rinsert() and rsearch() methods are not supported. Use insert()
and search() instead.

The insert and search methods do not return a reference to a scalar.
This limits the possibilities of the module somewhat, but is expected
to be rectified (with a different interface) in a later version.

=head2 Performance

Tree::Ternary_XS has been benchmarked at about 50 times faster than
Tree::Ternary, with a great reduction in memory usage.

=head1 AUTHOR

Leon Brocard, leon@astray.com

=head1 CREDITS

Thanks to Mark Rogaski for the pure Perl interface. Most of the
documentation and test scripts are simply copies from Tree::Ternary.

=head1 COPYRIGHT

Copyright (c) 2000 Leon Brocard. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

Bentley, Jon and Sedgewick, Robert. "Ternary Search Trees". Dr. Dobbs
Journal, April 1998. http://www.ddj.com/articles/1998/9804/9804a/9804a.htm

Bentley, Jon and Sedgewick, Robert. "Fast Algorithms for Sorting and
Searching Strings". Eighth Annual ACM-SIAM Symposium on Discrete
Algorithms New Orleans, January, 1997. http://www.cs.princeton.edu/~rs/strings/

=cut
