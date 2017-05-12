#!/usr/local/bin/perl
#
#   pRPC - Perl RPC, package for writing simple, RPC like clients and
#       servers
#
#   client.t is both a test script and an example of how to create
#   clients with the package
#
#
#   Copyright (c) 1997  Jochen Wiedmann
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   Author: Jochen Wiedmann
#           Am Eisteich 9
#           72555 Metzingen
#           Germany
# 
#           Email: wiedmann@neckar-alb.de
#           Phone: +49 7123 14881
#
#
#   $Id: noStorableOo.t,v 0.1001 1997/09/14 22:53:31 joe Exp $
#


require ((-f "lib.pl") ? "lib.pl" : "t/lib.pl");
$RPC::pClient::haveOoStorable = $RPC::pClient::haveOoStorable = 0;


############################################################################
#
#   This is main().
#
############################################################################

{
    #   Force output being written immediately
    $| = 1;
    print "1..14\n";

    $SIG{'PIPE'} = sub { print STDERR "Got signal PIPE.\n"; };

    if (defined(&Sys::Syslog::setlogsock)  &&
	defined(&Sys::Syslog::_PATH_LOG)) {
        Sys::Syslog::setlogsock('unix');
    }
    Sys::Syslog::openlog('client.t', 'pid', 'daemon');

    #
    #   We'd prefer to do the following as part of the Server()
    #   function. This would be fine, if we'd bind on a well
    #   known port. In our case we don't care for the port
    #   the only important thing is, that the child will
    #   now about it.
    #
    my $sock = IO::Socket::INET->new('Proto' => 'tcp',
				     'Listen' => 10,
				     'Reuse' => 1);
    if (!defined($sock)) {
	print STDERR "Cannot create server socket.\n";
	exit 10;
    }

    # Fork into a client and a server
    if (!defined($childPid = fork())) {
	print STDERR "Cannot fork(): $!\n";
	exit 10;
    } elsif ($childPid  ==  0) {
	#
	#   We are the child; create a server 
	#
        Server($sock);
	exit 0;
    }

    #
    #   We are the parent; wait some seconds until the server is up
    #   and then try to connect.
    #
    sleep 5;
    Client($sock->sockhost, $sock->sockport);
}
