package cli::tsv::keyvalue;

use 5.006;
use strict;
use warnings;

=head1 NAME

cli-tsv-keyvalue - Utilites to handle KeyValue relationships are provided.


  Follwoing commands (CLI) are available by installing this module 

    1. crosstable -- providing 2 way contingency table like Excel pivot.
    2. coltr  -- An expansion of Unix/Linux join command.
    3. keyvalues -- How many different values each key has.
    4. kvcmp -- Compare the Key-Value relation when 2 Key-Value files are given.
    5. polar -- gather multiple files along the common key column.


   The detail of each command can be seen by "--help" option after the command,
   and at this moment only Japanese manual is available.


cli::tsv::keyvalue - The great new cli::tsv::keyvalue!

=head1 VERSION

Version 0.31

=cut

our $VERSION = '0.31';


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

1; # End of cli::tsv::keyvalue
