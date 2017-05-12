package XAS;

our $VERSION = '0.15';

1;

__END__

=head1 NAME

XAS - Middleware for Datacenter Operations

=head1 DESCRIPTION

XAS is middleware for datacenter operations. Every datacenter has those little 
one off scripts that perform some important task. Most of them were written 
on the fly, to automate some specific task. These scripts have grown 
organically, they may have actually become an important part of your 
operations and they are generally a pain to maintain. Most of these scripts 
are written in a shell language or an interpreted language such as Perl. They 
have some important characteristics:

=over 4

=item * They have no consistent command structure.

=item * They are not documented.

=item * They represent an investment of time and money.

=item * They are the accumulated knowledge of how your operations really work. 

=back

If you are trying to pull your operations into the 21st century, you need to
refactor those scripts. You could throw them out and restart, but that would 
be a waste of time and money. Your operations people have better things to do 
then rewrite everything from scratch. More importantly, you could choose a 
framework that helps you migrate those old scripts into something more modern. 
XAS is that framework, and it will help you to refactor those old Perl scripts 
into a modern code base.

XAS does this by providing a consistent framework to write your operations 
procedures. It is a layered environment that allows you to follow accepted 
practices for continuous integration and delivery of software.  

=head1 UTILITIES

These utilities are provided with this package. 

=head2 xas-rotate

A simple file rotation program. Primarily used on platforms that don't provide
a file rotation utility.

=over 4

=item B<xas-rotate --help>

This will display a brief help screen on command options.

=item B<xas-rotate --manual>

This will display the utilities man page.

=back

=head2 xas-alert

A will send a XAS alert from the command line. This is useful when you
want to send an alert from a script.

=over 4

=item B<xas-alert --help>

This will display a brief help screen on command options.

=item B<xas-alert --manual>

This will display the utilities man page.

=back

=head2 xas-init

A simple utility that will create directories and set permissions for 
/var/run/xas and /var/lock/xas. This is needed on systemd systems where 
those directories are mounted as tmpfs volumes and go away on system reboots.

=over 4

=item B<xas-init --help>

This will display a brief help screen on command options.

=item B<xas-init --manual>

This will display the utilities man page.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Base|XAS::Base>

=item L<XAS::Class|XAS::Class>

=item L<XAS::Constants|XAS::Constants>

=item L<XAS::Exception|XAS::Exception>

=item L<XAS::Factory|XAS::Factory>

=item L<XAS::Utils|XAS::Utils>

=item L<XAS::Apps::Alert|XAS::Apps::Alert>

=item L<XAS::Apps::Init|XAS::Apps::Init>

=item L<XAS::Apps::Rotate|XAS::Apps::Rotate>

=item L<XAS::Lib::App|XAS::Lib::App>

=item L<XAS::Lib::App::Daemon|XAS::Lib::App::Daemon>

=item L<XAS::Lib::App::Service|XAS::Lib::App::Service>

=item L<XAS::Lib::App::Service::Unix|XAS::Lib::App::Service::Unix>

=item L<XAS::Lib::App::Service::Win32|XAS::Lib::App::Service::Win32>

=item L<XAS::Lib::Batch|XAS::Lib::Batch>

=item L<XAS::Lib::Batch::Job|XAS::Lib::Batch::Job>

=item L<XAS::Lib::Batch::Queue|XAS::Lib::Batch::Queue>

=item L<XAS::Lib::Batch::Server|XAS::Lib::Batch::Server>

=item L<XAS::Lib::Batch::Interface::Torque|XAS::Lib::Batch::Interface::Torque>

=item L<XAS::Lib::Curl::FTP|XAS::Lib::Curl::FTP>

=item L<XAS::Lib::Curl::HTTP|XAS::Lib::Curl::HTTP>

=item L<XAS::Lib::Iterator|XAS::Lib::Iterator>

=item L<XAS::Lib::Lockmgr|XAS::Lib::Lockmgr>

=item L<XAS::Lib::Lockmgr::Filesystem|XAS::Lib::Lockmgr::Filesystem>

=item L<XAS::Lib::Lockmgr::Flom|XAS::Lib::Lockmgr::Flom>

=item L<XAS::Lib::Lockmgr::KeyedMutex|XAS::Lib::Lockmgr::KeyedMutex>

=item L<XAS::Lib::Lockmgr::Nolock|XAS::Lib::Lockmgr::Nolock>

=item L<XAS::Lib::Log|XAS::Lib::Log>

=item L<XAS::Lib::Log::Console|XAS::Lib::Log::Console>

=item L<XAS::Lib::Log::File|XAS::Lib::Log::File>

=item L<XAS::Lib::Log::Json|XAS::Lib::Log::Json>

=item L<XAS::Lib::Log::Syslog|XAS::Lib::Log::Syslog>

=item L<XAS::Lib::Mixins::Bufops|XAS::Lib::Mixins::Bufops>

=item L<XAS::Lib::Mixins::Configs|XAS::Lib::Mixins::Configs>

=item L<XAS::Lib::Mixins::Handlers|XAS::Lib::Mixins::Handlers>

=item L<XAS::Lib::Mixins::Keepalive|XAS::Lib::Mixins::Keepalive>

=item L<XAS::Lib::Mixins::Process|XAS::Lib::Mixins::Process>

=item L<XAS::Lib::Mixins::Process::Unix|XAS::Lib::Mixins::Process::Unix>

=item L<XAS::Lib::Mixins::Process::Win32|XAS::Lib::Mixins::Process::Win32>

=item L<XAS::Lib::Modules::Alerts|XAS::Lib::Modules::Alerts>

=item L<XAS::Lib::Modules::Email|XAS::Lib::Modules::Email>

=item L<XAS::Lib::Modules::Environment|XAS::Lib::Modules::Environment>

=item L<XAS::Lib::Modules::Spool|XAS::Lib::Modules::Spool>

=item L<XAS::Lib::Net::Client|XAS::Lib::Net::Client>

=item L<XAS::Lib::Net::Server|XAS::Lib::Net::Server>

=item L<XAS::Lib::Net::POE::Client|XAS::Lib::Net::POE::Client>

=item L<XAS::Lib::Pidfile|XAS::Lib::Pidfile>

=item L<XAS::Lib::Pidfile::Unix|XAS::Lib::Pidfile::Unix>

=item L<XAS::Lib::Pidfile::Win32|XAS::Lib::Pidfile::Win32>

=item L<XAS::Lib::Pipe|XAS::Lib::Pipe>

=item L<XAS::Lib::Pipe::Unix|XAS::Lib::Pipe::Unix>

=item L<XAS::Lib::POE::PubSub|XAS::Lib::POE::PubSub>

=item L<XAS::Lib::POE::Session|XAS::Lib::POE::Session>

=item L<XAS::Lib::POE::Service|XAS::Lib::POE::Service>

=item L<XAS::Lib::Process|XAS::Lib::Process>

=item L<XAS::Lib::Process::Unix|XAS::Lib::Process::Unix>

=item L<XAS::Lib::Process::Win32|XAS::Lib::Process::Win32>

=item L<XAS::Lib::RPC::JSON::Client|XAS::Lib::RPC::JSON::Client>

=item L<XAS::Lib::RPC::JSON::Server|XAS::Lib::RPC::JSON::Server>

=item L<XAS::Lib::Service|XAS::Lib::Service>

=item L<XAS::Lib::Service::Unix|XAS::Lib::Service::Unix>

=item L<XAS::Lib::Service::Win32|XAS::Lib::Service::Win32>

=item L<XAS::Lib::Spawn|XAS::Lib::Spawn>

=item L<XAS::Lib::Spawn::Unix|XAS::Lib::Spawn::Unix>

=item L<XAS::Lib::Spawn::Win32|XAS::Lib::Spawn::Win32>

=item L<XAS::Lib::SSH::Client|XAS::Lib::SSH::Client>

=item L<XAS::Lib::SSH::Client::Exec|XAS::Lib::SSH::Client::Exec>

=item L<XAS::Lib::SSH::Client::Shell|XAS::Lib::SSH::Client::Shell>

=item L<XAS::Lib::SSH::Client::Subsystem|XAS::Lib::SSH::Client::Subsystem>

=item L<XAS::Lib::SSH::Server|XAS::Lib::SSH::Server>

=item L<XAS::Lib::Stomp::Frame|XAS::Lib::Stomp::Frame>

=item L<XAS::Lib::Stomp::Parser|XAS::Lib::Stomp::Parser>

=item L<XAS::Lib::Stomp::POE::Client|XAS::Lib::Stomp::POE::Client>

=item L<XAS::Lib::Stomp::POE::Filter|XAS::Lib::Stomp::POE::Filter>

=item L<XAS::Lib::Stomp::Utils|XAS::Lib::Stomp::Utils>

=item L<XAS::Lib::WS::Base|XAS::Lib::WS::Base>

=item L<XAS::Lib::WS::Exec|XAS::Lib::WS::Exec>

=item L<XAS::Lib::WS::Manage|XAS::Lib::WS::Manage>

=item L<XAS::Lib::WS::RemoteShell|XAS::Lib::WS::RemoteShell>

=item L<XAS::Lib::WS::Transfer|XAS::Lib::WS::Transfer>

=back

=head1 SUPPORT

Additional support is available at:

  http://scm.kesteb.us/trac

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2017 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
