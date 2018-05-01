package Tree::Interval::Fast;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.0.1';
our $ENABLE_DEBUG = 0;

require XSLoader;
XSLoader::load('Tree::Interval::Fast', $VERSION);

1; # End of Tree::Interval::Fast

=head1 NAME

Tree::Interval::Fast - Perl extension for efficient creation and manipulation of interval trees.

=head1 VERSION

Version 0.0.1

=head1 DESCRIPTION

This module provides a simple and fast implementation of B<interval trees>.
It uses the Perl XS extension mechanism by providing a tiny wrapper around 
an efficient C library which does the core of the work. 

=head1 SEE ALSO

Tree::Interval::Fast::Interval - implements an interval stored in the tree

=head1 SYNOPSIS

You can create an interval tree, add intervals to it and ask for intervals
overlapping with a certain range.

    use Tree::Interval::Fast;
    use Tree::Interval::Fast::Interval;

    # create the tree
    my $foo = Tree::Interval::Fast->new();
    
    # add some intervals
    $tree->insert(Tree::Interval::Fast::Interval->new(15, 20, 10));
    $tree->insert(Tree::Interval::Fast::Interval->new(10, 30, 20));
    $tree->insert(Tree::Interval::Fast::Interval->new(17, 19, 30));
    ...

    # query the tree for an overlapping interval
    my $result = $tree->find(6., 7.);
    printf "(%.2f, %.2f)", $result->low, $result->high;
    print Dumper $result->data; # overlapping interval might store data

    # another (unsuccesful) query
    $result = $tree->find(1, 4);
    if(!$result) {
      print "No overlapping interval with the query.";
    }

    # query the tree for all overlapping intervals
    my $results = $tree->findall(8, 11);
    foreach my $item (@{$results}) {
      print "Query overlaps with (%.2f, %.2f)\n", $item->low, $item->high;
    }
    

=head1 METHODS

=head2 C<new>

  Arg [...]   : None
  
  Example     : my $tree = Tree::Interval::Fast->new();
                carp "Unable to instantiate tree" unless defined $tree;

  Description : Creates a new empty interval tree object.

  Returntype  : An instance of Tree::Interval::Fast or undef
  Exceptions  : None
  Caller      : General
  Status      : Stable

=head2 C<find>

  Arg [1]     : Number; query interval left boundary
  Arg [2]     : Number; query interval right boundary
  
  Example     : $result = $tree->find(6, 7);
                if($result) {
                  printf "Found an overlapping interval: (%.2f, %.2f)\n", $result->low, $result->high
                } else { print "No overlapping interval with (6, 7)\n"; }

  Description : Query the tree for an overlapping interval with the specified range.

  Returntype  : An instance of Tree::Interval::Fast::Interval, representing the overlapping
                interval, if found, as stored in the tree or undef.
  Exceptions  : None
  Caller      : General
  Status      : Unstable

=head2 C<findall>

  Arg [1]     : Number; query interval left boundary
  Arg [2]     : Number; query interval right boundary
  
  Example     : $results = $tree->findall(6, 7);
                if(!$result) {
                  print "No overlapping intervals with (6, 7)\n"; 
                } else {
                  foreach my $item (@{$results}) {
                    print "Found (%.2f, %.2f)\n", $item->low, $item->high;
                  }
                }

  Description : Query the tree for all overlapping intervals with the specified range.

  Returntype  : ArraryRef; the list of Tree::Interval::Fast::Interval instances, representing 
                each one an overlapping interval, or undef if no interval is found.
  Exceptions  : None
  Caller      : General
  Status      : Stable

=head2 C<insert>

  Arg [1]     : Tree::Interval::Fast::Interval; the interval to insert in the tree
  
  Example     : my $interval = Tree::Interval::Fast::Interval->new(100, 1000, [1, 2, 3]);
                my $ok = $tree->insert($interval);
                if($ok) {
                  printf "Could insert (100, 1000)\n";
                } else { print "Something went wrong\n"; }

  Description : Insert an interval in the tree.

  Returntype  : True/False, depending on whether the insertion was successful or not
  Exceptions  : None
  Caller      : General
  Status      : Unstable

=head2 C<remove>

  Arg [1]     : Tree::Interval::Fast::Interval; the interval to remove from the tree
  
  Example     : my $interval = Tree::Interval::Fast::Interval->new(100, 1000, undef);
                my $ok = $tree->remove($interval);
                if($ok) {
                  printf "Could remove (100, 1000)\n";
                } else { print "Something went wrong\n"; }

  Description : Remove an interval in the tree.

  Returntype  : True/False, depending on whether the operation was successful or not
  Exceptions  : None
  Caller      : General
  Status      : Unstable

=head2 C<size>

  Arg [...]   : None
  
  Example     : printf "Size of the tree: %d\n", $tree->size();

  Description : Get the size (number of intervals) of the tree.

  Returntype  : Int; the number of intervals currently stored in the tree.
  Exceptions  : None
  Caller      : General
  Status      : Stable

=head1 EXPORT

None

=head1 AUTHOR

Alessandro Vullo, C<< <avullo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tree-interval-fast at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tree-Interval-Fast>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 CONTRIBUTING

You can obtain the most recent development version of this module via the GitHub
repository at https://github.com/avullo/AVLTree. Please feel free to submit bug
reports, patches etc.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tree::Interval::Fast


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tree-Interval-Fast>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tree-Interval-Fast>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tree-Interval-Fast>

=item * Search CPAN

L<http://search.cpan.org/dist/Tree-Interval-Fast/>

=back

=head1 ACKNOWLEDGEMENTS

I am very grateful to Julienne Walker for generously providing the source 
code of his production quality C library for handling AVL balanced trees.
The library has been adapted to implement interval trees.

Julienne's library can be found at:

http://www.eternallyconfuzzled.com/Libraries.aspx


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Alessandro Vullo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut
