package UDT::Simple;

use 5.012004;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use UDT::Simple ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('UDT::Simple', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

UDT::Simple - simplified Perl bindings for UDT(reliable UDP based application level data transport protocol - http://udt.sourceforge.net/)

=head1 SYNOPSIS

    # example server: (using SOCK_DGRAM $client->recv() 
                       will automatically use recvmsg 
                       instead of recv)
    my $server = UDT::Simple->new(AF_INET,SOCK_STREAM);
    $server->udt_sndbuf(4000);
    $server->udt_rcvbuf(4000);
    $server->udp_sndbuf(4000);
    $server->udp_rcvbuf(4000);
    $server->bind("localhost","12344");
    $server->listen(4);
    while (my $client = $u->accept()) {
       my $data = $client->recv(11);
       $client->close();
    }
    $server->close();

    # example client: (using SOCK_DGRAM $u->send()
                       will automatically use sendmsg
                       instead of send()
    my $u = UDT::Simple->new(AF_INET,SOCK_STREAM);
    $u->udt_sndbuf(4000);
    $u->udt_rcvbuf(4000);
    $u->udp_sndbuf(4000);
    $u->udp_rcvbuf(4000);

    $u->connect("localhost","12344");
    # if the socket is SOCK_STREAM send() might not send the whole thing
    my $message = "hello world";
    my $offset = 0;
    while (lenght($message) - $offset > 0) {
        $offset += $u->send($message,$offset);
    }
    $u->send("hello world")

    # if it is SOCK_DGRAM the whole message will be sent
    $u->send($message);
    $u->close();

=head1 INSTALLATION

 apt-get install libudt-dev
 perl Makefile.PL
 make && make install

or download libudt, install it, and run

 UDT_INCLUDE=/custom/path/to/udt.h perl Makefile.pl && make && make install

=head1 DESCRIPTION

quote from L<http://udt.sourceforge.net/udt4/index.htm>:

 UDT is a high performance data transfer protocol - UDP-based
 data transfer protocol. It was designed for data intensive 
 applications over high speed wide area networks, to overcome
 the efficiency and fairness problems of TCP. As its name
 indicates, UDT is built on top of UDP and it provides both
 reliable data streaming and messaging services.

this module offers incomplete bindings for http://udt.sourceforge.net/, requires C<libudt>
see L<http://udt.sourceforge.net/udt4/index.htm> for how to install it.


=head1 AUTHOR

borislav nikolov, E<lt>jack@sofialondonmoskva.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by borislav nikolov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
