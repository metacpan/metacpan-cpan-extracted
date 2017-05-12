package VM::EC2::REST::vm_export;

use strict;
use VM::EC2 '';   # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

=head1 NAME VM::EC2::REST::vm_export

=head1 SYNOPSIS

 use VM::EC2 ':misc';

=head1 METHODS

These methods allow you to export a VM to a non-EC2
environment. Currently not supported by VM::EC2 (volunteers welcome).

Implemented:
 (none)

Unimplemented:
 CancelExportTask
 CreateInstanceExportTask
 DescribeExportTasks

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;
