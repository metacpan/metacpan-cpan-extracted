package cli::rows::util;

use 5.006;
use strict;
use warnings;

=head1 NAME

cli::rows::util - Utiliites handling text stream segmented by "new line" characters. 

After installed follwing CLIs (Command Line Interface) are available:

   expskip -- To see the text data on the 1, 10, 100, .. -th line 
   freq  -- Tabulate the frequency of each line (the appearance number table)
   sampler -- Randomy sample lines.
   shuffler -- Shuffle the lines 
   alluniq -- Verify whether all lines has different character string or how they are like.
   idmaker -- Assign sequence codes on each different line. 
   timeput -- Putting the time in the head of each line. 
   eofcheck -- Check whether the file end has new line character.

  Each command has "--help" option so you can see the detail, and the English manual 
  would soon appear. (The oneline help manuals are written in Japanese. )



=head1 VERSION

Version 0.31

=cut

our $VERSION = '0.31';


=head1 AUTHOR

"Toshiyuki Shimono", C<< <bin4tsv at gmail.com> >>

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

1; # End of cli::rows::util
