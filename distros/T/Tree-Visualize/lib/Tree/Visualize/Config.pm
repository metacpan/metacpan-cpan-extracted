
package Tree::Visualize::Config;

use strict;
use warnings;

our $VERSION = '0.01';

our %TREE_TYPES = (
    'Tree::Binary'         => 'Binary',
    'Tree::Binary::Search' => 'Binary',    
    'Tree::Simple'         => 'Simple'    
    );
    
1;

__END__

=head1 NAME

Tree::Visualize::Config - A set of configuration variables for Tree::Visualize

=head1 SYNOPSIS

    use Tree::Visualize::Config;                                   

=head1 DESCRIPTION

This package is mostly used for storing certain module configuration variables. It's use is questionable at best, but for right now it is needed.

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

=head1 SEE ALSO

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

