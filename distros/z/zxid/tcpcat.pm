#!/usr/bin/perl -I../p
# Copyright (c) 1998 Sampo Kellomaki <sampo@iki.fi>, All Rights Reserved.
# This software may not be used or distributed for free or under any other
# terms than those detailed in file COPYING. There is ABSOLUTELY NO WARRANTY.

package tcpcat;

# tcpcat.pm - Send a message and receive a reply from server.
#
# Usage: $reply = &tcpcat ($address, $port, $message);
# E.g:   $reply = &tcpcat ('foo.bar.com', 900, "Hello World!");

use Socket;

$trace = 0;

### Start listening on given port

sub open_tcp_server {
    my ($port) = @_;  # port=0 --> let system pick any free port
    $port = getservbyname  ($port, 'tcp') unless $port =~ /^\d+$/;
    my $serv_params = pack ('S n a4 x8', &AF_INET, $port, "\0\0\0\0");
    
    if (socket (SERV_S, &PF_INET, &SOCK_STREAM, 0)) {
        warn "next bind\n" if $trace > 2;
        if (bind (SERV_S, $serv_params)) {
            my $old_out = select (SERV_S); $| = 1; select ($old_out);
	    warn "next listen\n" if $trace > 2;
	    if (listen(SERV_S, 5)) {
		$serv_params = getsockname(SERV_S); # getpeername(SERV_S);
		my ($fam, $sport, $saddr) = unpack('S n a4 x8',$serv_params);
		my ($a,$b,$c,$d) = unpack('C4',$saddr);
		$saddr = "$a.$b.$c.$d";
		warn "bound to $saddr:$sport\n" if $trace > 2;
		return ($saddr, $sport); # Success, now we're ready to accept
	    }
        }
    }
    warn "$0 $$: open_tcp_server: failed 0.0.0.0, $port ($!)\n";
    close SERV_S;
    return 0; # Fail
}

### Open stream to given host and port

sub open_tcp_connection {
    my ($dest_serv, $port) = @_;
    $port = getservbyname  ($port, 'tcp') unless $port =~ /^\d+$/;
    my $dest_serv_ip = gethostbyname ($dest_serv);
    unless (defined($dest_serv_ip)) {
        warn "$0 $$: open_tcp_connection: destination host not found:"
            . " `$dest_serv' (port $port) ($!)\n";
        return 0;
    }
    my $dest_serv_params = pack ('S n a4 x8', &AF_INET, $port, $dest_serv_ip);
    
    if (socket (S, &PF_INET, &SOCK_STREAM, 0)) {
        warn "next connect\n" if $trace > 2;
        if (connect (S, $dest_serv_params)) {
            my $old_out = select (S); $| = 1; select ($old_out);
            warn "connected to $dest_serv, $port\n" if $trace > 2;
            return 1; # Success
        }
    }
    warn "$0 $$: open_tcp_connection: failed `$dest_serv', $port ($!)\n";
    close S;
    return 0; # Fail
}

### Perform full roundtrip: open, write, read, close

sub tcpcat { # address, port, message --> returns reply, undef on error
    my ($dest_serv, $port, $out_message) = @_;
    my $reply = '';
    
    return unless (open_tcp_connection($dest_serv, $port));
    
    warn "$0 $$: tcpcat: sending `$out_message'\n" if $trace>2;
    print S $out_message;
    shutdown S, 1;   # Half close --> No more output, sends EOF to server
    warn "$0 $$: tcpcat: receiving...\n" if $trace>2;
    while (<S>)      { $reply .= $_; }
    warn "$0 $$: tcpcat: Done -- EOF. Got `$reply'.\n" if $trace>1;
    
    close S;
    return $reply;
}

1;
#__END__
