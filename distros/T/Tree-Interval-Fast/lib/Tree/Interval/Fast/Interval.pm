package Tree::Interval::Fast::Interval;

use Tree::Interval::Fast; # load the XS

$Tree::Interval::Fast::Interval::VERSION = '0.0.1';

=head1 NAME

Tree::Interval::Fast::Interval - Represents an interval in an instance
of Tree::Interval::Fast

=head1 VERSION

Version 0.0.1

=head1 DESCRIPTION

An interval in an interval tree. It is meant to be used in conjuction with
an instance of Tree::Interval::Fast.

=head1 SEE ALSO

Tree::Interval::Fast - The interval tree storing instances of Tree::Interval::Fast::Interval

=head1 SYNOPSIS

You can create an interval by specifying the range and the data it holds.

    use Tree::Interval::Fast::Interval;

    # create an interval representing the range (15.0, 20.0) which holds
    # a simple integer
    my $interval1 = Tree::Interval::Fast::Interval->new(15, 20, 10);
    
    # another interval with more complicated data
    my $interval2 = Tree::Interval::Fast::Interval->new(10.0, 30.0, [1, 2, 3]);

    # this one holds a hash instead
    my $interval2 = Tree::Interval::Fast::Interval->new(10.0, 30.0, { a=>1, b=>2 });
    ...

    # can get the left/right boundaries of each of the intervals
    printf "I1: (%.2f, %.2f)\n", $interval1->low, $interval1->high;

    # can get the data associated with each interval
    use Data::Dumper;
    print Dumper $interval2->data;
    

=head1 METHODS

=head2 C<new>

  Arg [1]     : Float; the left boundary of the interval
  Arg [2]     : Float; the right boundary of the interval
  Arg [3]     : Anything; the data associated with the interval

  Example     : my $i = Tree::Interval::Fast::Interval->new(10, 20, [1,2,3]);
                carp "Unable to instantiate tree" unless defined $i;

  Description : Creates a new interval tree object which holds some data

  Returntype  : An instance of Tree::Interval::Fast::Interval or undef
  Exceptions  : None
  Caller      : General
  Status      : Stable

=head2 C<low>

  Arg [...]   : None
  
  Example     : my $left = $tree->low;

  Description : Get the left boundary of the interval.

  Returntype  : Float
  Exceptions  : None
  Caller      : General
  Status      : Stable

=head2 C<high>

  Arg [...]   : None
  
  Example     : my $right = $tree->high;

  Description : Get the right boundary of the interval.

  Returntype  : Float
  Exceptions  : None
  Caller      : General
  Status      : Stable

=head2 C<data>

  Arg [...]   : None
  
  Example     : print Dumper $tree->data;

  Description : Get the data associated to the interval.

  Returntype  : The type of the data stored in the interval 
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

    perldoc Tree::Interval::Fast::Interval


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

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Alessandro Vullo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;
