package Win32::Girder::IEvent::Common;

#==============================================================================#

=head1 NAME

Win32::Girder::IEvent::Common - Shared components for access to the Girder Internet Events API

=head1 SYNOPSIS

	use Win32::Girder::IEvent::Common qw($def_pass hash_password);

=head1 DESCRIPTION

This module is not really intended for use outside of the 
Win32::Girder::IEvent::Client and Win32::Girder::IEvent::Server modules.
However if you have a use for the exported functions feel free to use them.

=head2 EXPORTABLE

=over 4

=cut

#==============================================================================#

require 5.6.0;

use strict;
use warnings::register;
use Digest::MD5 qw(md5_hex);
use Exporter;

use base qw(Exporter);
our @EXPORT_OK;

our $VERSION = 0.01;

#==============================================================================#

=item $def_pass

The default password for InternetEvents ('NewDefPWD').

=cut

push @EXPORT_OK, qw($def_pass);
our $def_pass = 'NewDefPWD';

#==============================================================================#

=item $def_host

The default hostname for InternetEvents ('localhost').

=cut

push @EXPORT_OK, qw($def_host);
our $def_host = 'localhost';

#==============================================================================#

=item $def_port

The default port for InternetEvents (1024).

=cut

push @EXPORT_OK, qw($def_port);
our $def_port = 1024;

#==============================================================================#

=item hash_password($cookie,$pass)

Generate an MD5 hash of the cookie and the password for sending accross the
wire.

=cut

push @EXPORT_OK, qw(hash_password);
sub hash_password ($$) {
	my ($cookie,$pass) = @_;
	return md5_hex("$cookie:$pass");
}

#==============================================================================#


=back

=head1 AUTHOR

Copyright (c) 2001 Gavin Brock (gbrock@cpan.org). All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

The Girder application is Copyright (c) Ron Bessems. Please see the 
'copying.txt' that came with your copy of Girder or visit http://www.girder.nl  
for contact information.

=head1 SEE ALSO

L<Win32::Girder::IEvent::Client>

L<Win32::Girder::IEvent::Server>

L<Digest::MD5>

=cut

#
# That's all folks..
#==============================================================================#
