package XAS::Supervisor;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Supervisor - A set of modules and procedures to supervise processes

=head1 DESCRIPTION

A supervisor is a process that manages other processes. On Unix this would be
similar to init, which is the master process. 

=head1 UTILITIES

These utilities are provided with this package.

=head2 xas-supervisor

This is the control process. It reads a configuration file to see what 
processes to start. Once they are started, the supervisor will make sure that 
they continue to run. 

When a process exits, the supervisor checks the exit status. If that status is
known, it will restart the process otherwise it will send alert that the process
has stopped.

=over 4

=item B<xas-supervisor --help>

This will display a brief help screen on command options.

=item B<xas-supervisor --manual>

This will display the utilities man page.

=back

The configuration file is documented here: L<XAS::Apps::Supervisor::Monitor|XAS::Apps::Supervisor::Monitor>

=head2 xas-supctl

This is a command line tool to communicate with the supervisor. With this
tool you can stop, start, pause, resume or kill a managed process. You 
can also retrieve all of the processes that the supervisor knows about and
you can check the status of individual processes.

=over 4

=item B<xas-supctl --help>

This will display a brief help screen on command options.

=item B<xas-supctl --manual>

This will display the utilities man page.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Apps::Supervisor::Client|XAS::Apps::Supervisor::Client>

=item L<XAS::Apps::Supervisor::Monitor|XAS::Apps::Supervisor::Monitor>

=item L<XAS::Docs::Supervisor::Installation|XAS::Docs::Supervisor::Installation>

=item L<XAS::Supervisor::Client|XAS::Supervisor::Client>

=item L<XAS::Supervisor::Controller|XAS::Supervisor::Controller>

=item L<XAS::Supervisor::Monitor|XAS::Supervisor::Monitor>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
