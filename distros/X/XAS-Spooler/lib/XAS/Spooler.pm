package XAS::Spooler;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.03';

1;

__END__

=head1 NAME

XAS::Spooler - A set of procedures and modules to implement a spooler

=head1 DESCRIPTION

The spooler is used for messaging within XAS. A spooler is as old as computing.
Computer lore has it that IBM coined the term SPOOL and used spoolers to
buffer line printer output. In our case it is being used to implement a store 
and forward messaging scheme. Which in itself, is almost as old a spooling.

When a process wants to send a message, it creates a spool file. The spool file
is a serialized Perl data structure in L<JSON|http://json.org/> format, with 
special headers. The spooler scans the spool directory and sends the packet 
to an appropriate queue on a message queue server. L<XAS::Collector|XAS::Collector> 
is used as the endpoint to handle those messages. The messaging protocol used 
by the message queue server is known as L<STOMP|http://stomp.github.io/>, 
which is a text based protocol.

The reason to do all of this, is to decouple the message sender from the
message receiver. This simplifies the sender. There is no need to implement
all of the logic to open network connections and the maintenance of those 
connections. It also allows for buffering of the message stream. A fast sender
doesn't have to worry about a slow receiver. The spooler takes care of this.

=head1 UTILITIES

This module provides the following utilities.

=head2 xas-spooler

This is the actual spooler. It reads a configuration file to determine which
spool directories to scan. The configuration file also says which queues to
use for those packets.

The configuration file is documented here: L<XAS::Apps::Spooler::Process|XAS::Apps::Spooler::Process>

=over 4

=item B<xas-spooler --help>

This will display a brief help screen on command options.

=item B<xas-spooler --manual>

This will display the utilities man page.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Docs::Spooler::Installation|XAS::Docs::Spooler::Installation>

=item L<XAS::Apps::Spooler::Process|XAS::Apps::Spooler::Process>

=item L<XAS::Spooler::Connector|XAS::Spooler::Connector>

=item L<XAS::Spooler::Processor|XAS::Spooler::Processor>

=item L<XAS::Spooler|XAS::Spooler>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
