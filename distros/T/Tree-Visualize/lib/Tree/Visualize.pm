
package Tree::Visualize;

use strict;
use warnings;
    
our $VERSION = '0.01';

use Tree::Visualize::Exceptions;
use Tree::Visualize::Config;
use Tree::Visualize::Layout::Factory;

sub new {
    my ($_class, $tree, $output_format, $layout) = @_;
    my $class = ref($_class) || $_class;
    my $visulization = {};
    bless($visulization, $class);
    $visulization->_init($tree, $output_format, $layout);
    return $visulization;
}

sub _init {
    my ($self, $tree, $output_format, $layout) = @_;
    (defined($tree) && ref($tree) && defined($output_format)) 
        || throw Tree::Visualize::InsufficientArguments "bad arguments for Tree::Visualize->new"; 
        
    $self->{tree} = $tree;
    $self->{tree_type} = $Tree::Visualize::Config::TREE_TYPES{ref($tree)};    
    $self->{output_format} = $output_format;            
    $self->{layout} = $layout;
}

sub draw {
    my ($self) = @_;
    my $output;
    eval {
        $output = $self->_getVisualizationInstance()->draw($self->{tree});
    };
    throw Tree::Visualize::Exception ("Visualization for tree (" . $self->{tree} . ") failed", $@) if $@;
    return $output->getAsString() if ref($output) && UNIVERSAL::isa($output, 'Tree::Visualize::ASCII::BoundingBox');
    return $output;
}


sub _getVisualizationInstance {
    my ($self) = @_;
    return Tree::Visualize::Layout::Factory->new()->get(
                            output => $self->{output_format}, 
                            tree_type => $self->{tree_type},
                            layout => $self->{layout} || "TopDown"
                            );
}

1;

__END__

=head1 NAME

Tree::Visualize - A module for visualizing Tree structures

=head1 SYNOPSIS

  use Tree::Visualize;
  use Tree::Binary;
  
  my $tree = Tree::Binary->new("*")
                          ->setLeft(
                              Tree::Binary->new("+")
                                          ->setLeft(Tree::Binary->new("2"))
                                          ->setRight(Tree::Binary->new("2"))
                          )
                          ->setRight(
                              Tree::Binary->new("+")
                                          ->setLeft(Tree::Binary->new("4"))
                                          ->setRight(Tree::Binary->new("5"))
                          ); 
  
  my $visualize = Tree::Visualize->new($tree, 'ASCII', 'TopDown');
  print $visualize->draw();   
  
  #                 +---+                 
  #        +--------| * |-------+         
  #        |        +---+       |         
  #      +---+                +---+       
  #   +--| + |--+          +--| + |--+    
  #   |  +---+  |          |  +---+  |    
  # +---+     +---+      +---+     +---+  
  # | 2 |     | 2 |      | 4 |     | 5 |  
  # +---+     +---+      +---+     +---+  

  my $tree = Tree::Binary::Search->new();
  foreach my $value (7, 3, 1, 0, 2, 5, 4, 6, 11, 9, 10, 8, 13, 12, 14) {
    $tree->insert($value => $value);
  }
  
  my $visualize = Tree::Visualize->new($tree, 'ASCII', 'Diagonal');
  print $visualize->draw(); 

  # (7)-------------(11)-----(13)-(14)
  #  |                |        |      
  #  |                |      (12)     
  #  |                |               
  #  |              (9)-(10)          
  #  |               |                
  #  |              (8)               
  #  |                                
  # (3)-----(5)-(6)                   
  #  |       |                        
  #  |      (4)                       
  #  |                                
  # (1)-(2)                           
  #  |                                
  # (0)
  
  my $tree = Tree::Simple->new("test")
                        ->addChildren(
                            Tree::Simple->new("test-1")
                                ->addChildren(
                                    Tree::Simple->new("test-1-1")
                                    ),
                            Tree::Simple->new("test-2"),
                            Tree::Simple->new("test-3")
                            );  
                            
  my $visualize = Tree::Visualize->new($tree, 'ASCII', 'TopDown');
  print $visualize->draw();   
  
  #                   |                  
  #               +------+               
  #               | test |               
  #               +------+               
  #       ____________|_____________     
  #       |            |           |     
  #  +--------+   +--------+  +--------+ 
  #  | test-1 |   | test-2 |  | test-3 | 
  #  +--------+   +--------+  +--------+ 
  #       |                              
  #       |                              
  # +----------+                         
  # | test-1-1 |                         
  # +----------+                                                       

=head1 DESCRIPTION

B<NOTE: This is I<very> early release alpha software>

The goal of this module is to provide a means of easily visualizing trees in a number of output formats and layouts. Currently only ASCII output and a limited number of formats are supported. There is some support for output as GraphViz dot files, but that is buggy at best right now. 

As I said, this is alpha software, and so please don't expect it to do all that much. Many of the classes inside are not even implemented, and few if any are documented. I am releasing this to CPAN largely as a means of self-motivation, although I can make no promises about the speed of my progress. If you find this module interesting at all and would either like to know more (or even to help in it's development) please don't hesitate contact me at the email address listed below in the L<AUTHOR> section. 

=head2 Supported Tree Types

This module really only draws Tree::Simple, Tree::Binary and Tree::Binary::Search objects currently. However through the use of some of the conversion Visitors in the Tree::Simple::VisitorFactory module, a number of other tree styles can be first converted, then visualized.

=head2 ASCII Drawing Algorithms

The algorithms for drawing binary and I<n>-ary trees in a top-down layout (as illustrated above in the L<SYNOPSIS> section) have been severely tested with randomly generated trees and have proven to be quite accurate and stable. The algorithm for the diagonal binary tree has not be tested as thoroughly, but so far has proven to be equally as stable as well. I have a few other layouts planned (left-side, right-side and bottom-up) but none of them has been implemented yet.

At this point, none of the drawing algorithms are space efficient, they are concerned more with accurate drawing then with space efficiency. Future work includes trying to develop some space optimizing algorithms.

=head1 METHODS

=over 4

=item B<new ($tree_to_visualize, $output_format, $layout_stype)>

Given a C<$tree_to_visualize> with a specified C<$output_format> and C<$layout_stype>, this will return a Tree::Visualize instance ready to be drawn into a string.

=item B<draw>

This will call C<draw> on the underlying Tree::Visualize::Layout::ILayout instance and then return a string.

=back

=head1 TO DO

=over 4

=item A lot of stuff

The list is to large for the moment, as this is early release alpha software here. Lets put it this way, most of the classes are not even implemented yet.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, this section will have the B<Devel::Cover> report on this module test suite once this module is more developed.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

