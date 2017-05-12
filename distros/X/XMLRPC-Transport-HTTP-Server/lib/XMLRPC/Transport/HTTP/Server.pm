package XMLRPC::Transport::HTTP::Server;

use strict;

=encoding utf8

=head1 NAME

XMLRPC::Transport::HTTP::Server - XMLRPC::Lite HTTP Server

=head1 VERSION

Version 0.14

=cut

use XMLRPC::Lite;

use XMLRPC::Transport::HTTP;

@XMLRPC::Transport::HTTP::Server::ISA = qw(SOAP::Transport::HTTP::Server);

our $VERSION = '0.14';

=head1 SYNOPSIS

=over 4

use XMLRPC::Transport::HTTP::Server;

$server = XMLRPC::Transport::HTTP::Server->new(...);

=back

=head1 DESCRIPTION

This module extends the XMLRPC::Lite suite with a XMLRPC::Transport::HTTP::Server
which is just a L<SOAP::Transport::HTTP::Server> with the L<XMLRPC::Server>
functions for understanding the XMLRPC protocol.

=cut

sub initialize; *initialize = \&XMLRPC::Server::initialize;
sub make_fault; *make_fault = \&XMLRPC::Transport::HTTP::CGI::make_fault;
sub make_response; *make_response = \&XMLRPC::Transport::HTTP::CGI::make_response;

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/xmlrpc-transport-http-server/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XMLRPC::Transport::HTTP::Server

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/xmlrpc-transport-http-server/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of XMLRPC::Transport::HTTP::Server
