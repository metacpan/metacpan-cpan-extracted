package XAS::Collector;

use strict;
use warnings;

our $VERSION = '0.03';

1;

__END__

=head1 NAME

XAS::Collector - A set of procedures and modules to retrieve messages and store the results

=head1 DESCRIPTION

The collector is the end point of a message queue. L<XAS::Spooler|XAS::Spooler>
places messages  in the queue and the collector removes those messages and 
process them. This process is configuration driven. A XAS message type is
associated with a queue. A processor is used to process each message type. 
What happens to that message depends on the processor. Currently there are
processors for SQL Databases, Logstash and OpenTSDB data stores.

The configuration file is documented here: L<XAS::Apps::Collector::Process|XAS::Apps::Collector::Process>

=head1 UTILITIES

=head2 xas-collector

This is the collector procedure. It runs as a service and processes messages 
based on a configuration file.

=over 4

=item B<xas-collector --help>

This will display a brief help screen on command options.

=item B<xas-collector --manual>

This will display the utilities man page.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Apps::Collector::Process|XAS::Apps::Collector::Process>

=item L<XAS::Collector::Format::Base|XAS::Collector::Format::Base>

=item L<XAS::Collector::Format::Alerts|XAS::Collector::Format::Alerts>

=item L<XAS::Collector::Format::Logs|XAS::Collector::Format::Logs>

=item L<XAS::Collector::Input::Stomp|XAS::Collector::Input::Stomp>

=item L<XAS::Collector::Output::Console::Base|XAS::Collector::Output::Console::Base>

=item L<XAS::Collector::Output::Console::Alerts|XAS::Collector::Output::Console::Alerts>

=item L<XAS::Collector::Output::Console::Logs|XAS::Collector::Output::Console::Logs>

=item L<XAS::Collector::Output::Database::Base|XAS::Collector::Output::Database::Base>

=item L<XAS::Collector::Output::Database::Alerts|XAS::Collector::Output::Database::Alerts>

=item L<XAS::Collector::Output::Database::Logs|XAS::Collector::Output::Database::Logs>

=item L<XAS::Collector::Output::Socket::Base|XAS::Collector::Output::Socket::Base>

=item L<XAS::Collector::Output::Socket::Logstash|XAS::Collector::Output::Socket::Logstash>

=item L<XAS::Collector::Output::Socket::OpenTSDB|XAS::Collector::Output::Socket::OpenTSDB>

=item L<XAS::Model::Database::Messaging::Result::Alert|XAS::Model::Database::Messaging::Alert>

=item L<XAS::Model::Database::Messaging::Result::Log|XAS::Model::Database::Messaging::Result::Log>

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
