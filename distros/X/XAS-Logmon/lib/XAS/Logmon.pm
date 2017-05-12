package XAS::Logmon;

use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Logmon - A set of procedures and modules to monitor files

=head1 DESCRIPTION

Monitoring and extracting information from log files is an important task.
There is important operational data stored in those files. They detail the
state of your operations. These modules would compliment a centralized syslog 
gathering operationation. Even thou XAS can write to syslog or create JSON 
formatted log messages and spool them directly, these modules provide a 
framework that can be expanded to include other types of files.

The design of this system is a monitoring process that spawns background jobs
that do the actual work. Those background jobs are kept alive when file states
change, such as file rotation or new file creation. 

A multi-process system is simpler to design and keep alive. It follows the XAS
philosophy of small, simple components, that do one thing well.

=head1 UTILITIES

This module provides the following utilities.

=head2 xas-logmon

This is procedure is used to spawn and monitor file monitoring processes. It 
reads a configuration file to determine which files to monitor.

The configuration file is documented here: L<XAS::Apps::Logmon::Monitor|XAS::Apps::Logmon::Monitor>

=over 4

=item B<xas-logmon --help>

This will display a brief help screen on command options.

=item B<xas-logmon --manual>

This will display the utilities man page.

=back

=head2 xas-logs

This procedure monitors XAS log files. It parses them and sends the results 
to a spool directory.

=over 4

=item xas-logs --help

This will display a brief help screen on command options.

=item xas-logs --manual

This will display the utilities man page.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Docs::Logmon::Installation|XAS::Docs::Logmon::Installation>

=item L<XAS::Apps::Logmon::Monitor|XAS::Apps::Logmon::Monitor>

=item L<XAS::Apps::Logmon::XAS::Process|XAS::Apps::Logmon::XAS::Process>

=item L<XAS::Lib::Regexp::Log::XAS|XAS::Lib::Regexp::Log::XAS>

=item L<XAS::Logmon::Filter::Merge|XAS::Logmon::Filter::Merge>

=item L<XAS::Logmon::Format::Logstash|XAS::Logmon::Format::Logstash>

=item L<XAS::Logmon::Input::File|XAS::Logmon::Input::File>

=item L<XAS::Logmon::Input::Tail|XAS::Logmon::Input::Tail>

=item L<XAS::Logmon::Input::Tail::Default|XAS::Logmon::Input::Tail::Default>

=item L<XAS::Logmon::Input::Tail::Linux|XAS::Logmon::Input::Tail::Linux>

=item L<XAS::Logmon::Input::Tail::Win32|XAS::Logmon::Input::Tail::Win32>

=item L<XAS::Logmon::Output::Spool|XAS::Logmon::Output::Spool>

=item L<XAS::Logmon::Parser::XAS::Logs|XAS::Logmon::Parser::XAS::Logs>

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
