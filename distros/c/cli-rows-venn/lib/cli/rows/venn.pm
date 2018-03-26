package cli::rows::venn;

use 5.006;
use strict;
use warnings;

=head1 NAME

   cli::rows::venn -- showing the cardinal concerning superposition of 2,3 or 4 sets.

   After this module is installed the following three CLIs are deployed.

      venn2 
      venn3 -- not so good ..
      venn4 -- neat document does not entailed. 

   The author found that the Venn diagram drawing for 3 and 4 sets is 
   sometimes quite important to understand the including relationship 
   among the sets during the data analysis project.  But drawing the 
   diagram and filling the element numbers (cardinals) is really tedious
   work. This CLIs (Command Line Interface) help this work greatly.

   One educational note: the Venn diagram for 3 sets is drawn only 
   by regular circles, and the one for 4 sets is drawn by rectangles 
   or ellipses. My program shows the element numbers of it as in the 
   4 x 4 matrix. 

   Neatly showing about the information of element numbers over multiple 
   sets considering superposition has various ways. The future version 
   would try to implement in CLI. 


=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';

=head1 LICENSE AND COPYRIGHT

Copyright 2018 "Toshiyuki Shimono".

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of cli::rows::venn
