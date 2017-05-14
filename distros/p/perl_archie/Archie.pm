########################################################################
# RCS:  $Id: Archie.pm,v 1.5 1995/07/05 01:18:08 bossert Exp $
# File: Archie.pm
# Desc: Archie perl5 module
# By:   Greg Bossert (bossert@noc.rutgers.edu)
#       <http://www-ns.rutgers.edu/~bossert/index.html>
#   
# Copyright (c) 1995 Greg Bossert. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# The latest version of this file is available
# at <http://www-ns.rutgers.edu/doc/archie/>
#
# Use "perldoc Archie" for documentation (or just read the pod source 
# below).
########################################################################

########################################################################
# pod (Perl Online Documentation) data
########################################################################

=head1 NAME

Archie - Perl module to make Archie queries via Prospero requests

=head1 DESCRIPTION

The Archie module finds files available via anonymous ftp by making
requests to an Archie server.  The package communicates with the
Archie server via the Prospero protocol, which is layered on the
Asynchronous Reliable Delivery Protocol, which is layered on UDP.

The usual entry point is Archie::archie_request, which takes arguments
similar to the Unix archie command-line client, and returns an array
of hash references which point to the returned data.

The routine Archie::archie_cancel cancels the request on the server;
this stops the server from sending packets to a canceled client
process.

This release is $Revision: 1.5 $.

=head1 EXAMPLE

    use Archie;
    
    $SIG{'INT'} = 'sig_handler';
    
    [...]
    @responses = Archie::archie_request($server,$match,$order, 
                                        $max_hits,$niceness,$user,
                                        $timeout,@searchterms);
    if ($Archie::ArchieErr) {
        print "Error: $Archie::ArchieErr\n";
    }
    else {
        foreach $response (@responses) {
            print "name: $response->{'name'}\n";
            print "   host: $response->{'host'}\n";
            print "   type: $response->{'type'}\n";
            print "   dir: $response->{'dir'}\n";
            print "   size: $response->{'size'}\n";
            print "   mode: $response->{'mode'}\n";
            print "   lastmod: $response->{'lastmod'}\n";
        }
    }
    
    sub sig_handler {
        my($sig) = @_;
        &Archie::archie_cancel();
        exit;
    }

=head1 NOTES

The Prospero parser is incomplete and only really deals
with standard Archie responses -- this should be generalized.

The archie service was conceived and implemented by Alan Emtage, Peter
Deutsch, and Bill Heelan.  The entire Internet is in their debt.

The Prospero system was created by Clifford Neuman <bcn@isi.edu>;
write to <info-prospero@isi.edu> for more information on the protocol
and its use.

=head1 SEE ALSO

The archie man pages.

Information about Prospero and ARDP is available from ftp.isi.edu.

=head1 AUTHOR

Greg Bossert <bossert@noc.rutgers.edu

=cut
### end pod ###

package Archie;

use Socket;

########################################################################
# config
########################################################################
### uncomment this to print out ardp packet info ###
#$ardp_debug = 1;

### protocol versions ###
$prospero_version = 1;
$ardp_version = 0;

########################################################################
# archie_request (PUBLIC) - Makes an archie request via Prospero and 
#    ARDP.  See the archie client man page for more info on the args.
#
# args:
#        $server:      hostname of archie server
#        $match_arg:   type of match = 
#                      'exact' | 'substring' | 'subcase' | 'regexp'
#        $order_arg:   order of results = 'date' | 'host'
#        $max_hits:    max number of responses from server
#        $niceness:    priority (from 0-35765)
#        $user:        user name for request
#        $timeout:     max time between archie responses
#        $searchterms: list of terms to match
# returns:
#        $sorted_response: sorted array of hash refs:
#           'host' => remote host name
#           'type' => 'Dir' | 'File'
#           'dir' => directory path of match
#           'size' => size in bytes
#           'mode' => eg. Unix file permissions
#           'lastmod' => last modified date of match as YYYYMMHHmmSSZ
#           'name' => file name of match
#        Returns undef and sets ArchieErr if error.
########################################################################
sub archie_request {
    my($server, $match_arg, $order_arg, 
       $max_hits, $niceness, $user, $timeout,
       @searchterms) = @_;

    my($term, $err, %request, $archie_socket, $dest_addr, 
       $local_addr, $local_hostname);

    $ArchieErr = '';

    ### translate match string to Prospero token ###
    my(%match_array) = ("exact", "=", 
                        "substring", "S", 
                        "subcase", "C", 
                        "regexp", "R");
    $match = $match_array{$match_arg};

    ($archie_socket, $dest_addr, $local_addr, $local_hostname) = 
        &ardp_open($server, "dirsrv", 1525);
    return undef if $ArchieErr;

    ### Construct the query packet ###
    $request{'data'} = "VERSION $prospero_version\n";
    $request{'data'} .= "AUTHENTICATOR UNAUTHENTICATED $user\@$local_hostname\n";

    foreach $term (@searchterms) {
        $request{'data'} .=
            "DIRECTORY ASCII ARCHIE/MATCH($max_hits,0,$match)/$term\n";
        $request{'data'} .= "LIST ATTRIBUTES COMPONENTS\n";
    }

    ### kick up priority for debugging ###
    $niceness = -42 if $ardp_debug;

    ### send request ###
    $request{'id'} = $$;
    $request{'current_packet'} = 1;
    $request{'total_packets'} = 1;
    $request{'delay'} = 1;
    $request{'want_ack_flag'} = 1;
    $request{'recvd_through'} = $response{'recvd_through'};
    $request{'priority_flag'} = 1;
    $request{'priority'} = $niceness;
    $request{'request_queue_status_flag'} = 1;
    $request{'queue_status_time_flag'} = 1;
    $request{'queue_status_pos_flag'} = 1;
    $request{'recvd_through'} = 0;
    $request{'current_packet'} = 1;
    $request{'total_packets'} = 1;
    $chars = &ardp_send($archie_socket, $dest_addr, %request);

    do {
        ### try to get response ###
        for($i = 0; $i < $timeout; $i++) {
	    ### poll for a second at a time, up to $timeout seconds ###
            %response = &ardp_recv($archie_socket, 1.0);
            last if( $response{'got_response'} || $response{'got_control'} );
        }

        if( !$response{'got_response'}  && !$response{'got_control'} ) {
            &archie_cancel;
            $ArchieErr = 'Archie has timed out after $timeout seconds';
            return undef;
        }

        ### fill response array ###
        if($response{'got_response'} && 
           !defined($raw_response[$response{'current_packet'}]) ) {
            $response{'data'} =~ s/\000//g;
            $raw_response[$response{'current_packet'}] = $response{'data'};
        }

        ### ack if requested ###
        if( $response{'want_ack_flag'} ) {

            ### calculate "received through" value ###
            for( $ack{'recvd_through'} = 1; 
                defined($raw_response[$ack{'recvd_through'}]); 
                $ack{'recvd_through'}++) {};

            $ack{'recvd_through'}--;

            if( $ack{'recvd_through'} != $response{'current_packet'} ) {
                $ack{'reset_recvd_through_flag'} = 1;
            }

            ### set up ardp fields ###
            $ack{'id'} = $$;
            $ack{'current_packet'} = 1;
            $ack{'total_packets'} = 1;
            $chars = &ardp_send($archie_socket, $dest_addr, %ack);
        }

        ### note that total_packets can be 0 until the last one ###
    } until ($response{'got_response'} &&
             $response{'total_packets'} &&
             $response{'current_packet'} >= $response{'total_packets'} );

    &ardp_close($archie_socket);

    ### parse replies into s_* arrays ###
    @parsed_response = &parse_prospero_response(@raw_response);

    ### sort replies ###
    if ($order_arg eq 'host') {
        @sorted_response = sort(sort_by_host @parsed_response);
    }
    else {
        @sorted_response = sort(sort_by_date @parsed_response);
    }

    ### return sorted list ###
    @sorted_response;
}

########################################################################
# archie_cancel (PUBLIC)  - sends a Prospero (actually an ARDP) cancel  
#    request to the Archie server.
#
# args:    none
# returns: none
########################################################################
sub archie_cancel {
    my(%cancel);

    if( defined($archie_socket) && defined($dest_addr)) {
        $cancel{'id'} = $$;
        $cancel{'current_packet'} = 1;
        $cancel{'total_packets'} = 1;
        $cancel{'delay'} = 1;
        $cancel{'cancel_flag'} = 1;

        &ardp_send($archie_socket, $dest_addr, %cancel);
        &ardp_close($archie_socket);

        undef($archie_socket);
        undef($dest_addr);
    }
}

########################################################################
# parse_prospero_response (PRIVATE) - parses the raw Prospero
#    response.  note that this only handles Prospero V.1 and only
#    really deals with standard Archie responses -- this should really
#    be generalized a bit.
#
# args:
#        lists: array or raw response data
# returns: 
#        $parsed_response: array of hash refs -- see archie_request for
#           details.
########################################################################
sub parse_prospero_response {
    my(@raw_response) = @_;
    my(@parsed_response);

    ### rejoin response lines ###
    @lines = split(/\n/, join('', @raw_response));

    while( $_ = shift(@lines) ) {
        ### switch on line head ###

        /^LINK L/ && do {       # normal link
            my($dum, $host, $type, $dir, $size, $modes, 
               $lastmod, $name, $attr);

            ($dum, $dum, $type, $name, $dum, $host, $dum, $dir, $dum, $dum) =
                split(/ /);
            $host =~ tr/A-Z/a-z/;

            $type = ($type eq 'DIRECTORY') ? 'Directory' : 'File';
            if ($type eq 'Directory' && $dir =~ m.ARCHIE/HOST.) {
                ($archie, $dum, $host, $dir) = 
                    ($dir =~ m|([^/]+)/([^/]+)/([^/]+)/(.*)$|);
                $dir = '/' . $dir;
            }

            ### get the link attributes ###
            while( $lines[0] =~ /^LINK-INFO/ ) {
                ($dum, $dum, $attr, $dum, @info) = split(/ /, shift(@lines));
                ### we only care about a few attribute types ###
                if ($attr eq 'SIZE') {
                    $size = join(' ', @info);
                }
                elsif ($attr eq 'UNIX-MODES') {
                    $modes = join(' ', @info);
                }
                elsif ($attr eq 'LAST-MODIFIED') {
                    $lastmod = join(' ', @info);
                }
            }

            push(@parsed_response, {'host' => $host,
                                    'type' => $type,
                                    'dir' => $dir,
                                    'size' => $size,
                                    'mode' => $modes,
                                    'lastmod' => $lastmod,
                                    'name' => $name});
            next;
        };

        /^LINK U/ && do {       # union link to a directory
            next;
        };

        /^LINK-INFO/ && do {    # link attribute data out of order?
            next;
        };

        /^NONE-FOUND/ && do {
            $ArchieErr = "None found";
            return undef;
        };
        /^UNRESOLVED/ && do {
            $ArchieErr = "Archie server error: Unresolved entries";
            return undef;
        };
        /^FAILURE/ && do {
            $ArchieErr = "Archie server error: $_";
            return undef;
        };
        ### other answers possible, ignored for now ###
    }

    return @parsed_response;
}

########################################################################
# sort_by_date (PRIVATE) - called by sort
########################################################################
sub sort_by_date {
    my($date_a, $date_b) = ($a->{'lastmod'}, $b->{'lastmod'});

    ### remove time zone ###
    $date_a =~ s/\D+//;
    $date_b =~ s/\D+//;

    $date_b <=> $date_a;
}

########################################################################
# sort_by_host (PRIVATE) - called by sort
########################################################################
sub sort_by_host {
    my($host_a, $host_b) = ($a->{'host'}, $b->{'host'});

    $host_a cmp $host_b;
}

########################################################################
# ARDP (Asynchronous Reliable Delivery Protocol) routines
########################################################################
########################################################################
# ardp_open - sets up a UDP socket and returns some useful stuff
#
# args:
#        $service: name of desired service
#        $port: port number of desired service (overrides $service)
# returns:
#        $err: error message
#        $socket: 
#        $dest_addr: socket_addr for destination
#        $local_addr: socket_addr for local host
#        $local_hostname: hostname of local host
########################################################################
sub ardp_open {
    my($server, $service, $port) = @_;
    my($name, $aliases, $proto, $type, $len, $naddr);
    my($sockaddr) = 'S n a4 x8';    # the socketaddr structure.

    ### get protocol and service ###
    ($name, $aliases, $proto) = getprotobyname("udp");
    ($name, $aliases, $port) = getservbyname($service, "udp")
        unless defined($port);

    ### the destination address ###
    ($name, $aliases, $type, $len, @naddrs) = gethostbyname($server);
    if( !defined $name ) {
        $ArchieErr = "could not get address of server $server";
        return undef;
    }

    $dest_addr = pack($sockaddr, &AF_INET, $port, $naddrs[0]);

    ### the local address ###
    ### use 'hostname'.  yuck.  restrict path for safety ###
    $ENV{'PATH'} = '/bin:/usr/bin:/usr/ucb';
    chomp($local_hostname = `hostname`);
    if( !defined $local_hostname ) {
        $ArchieErr = 'could not get local host with "hostname"';
        return undef;
    }

    ($name, $aliases, $type, $len, @naddrs) = gethostbyname($local_hostname);
    if( !defined $name ) {
        $ArchieErr = 'could not get address of local host';
        return undef;
    }

    $local_addr = pack($sockaddr, &AF_INET, 0, $naddrs[0]);

    ### get and bind a socket ###
    socket(ARDP_SOCKET, &AF_INET, &SOCK_DGRAM, $proto) || 
        do {
            $ArchieErr = "could not create socket";
            return undef;
        };

    bind(ARDP_SOCKET, $local_addr) || 
        do {
            $ArchieErr = "could not bind to socket";
            return undef;
        };

    (ARDP_SOCKET, $dest_addr, $local_addr, $local_hostname);
}

########################################################################
# ardp_close - closes a UDP socket
#
# args:
#        $socket: 
# returns:
#        none
########################################################################
sub ardp_close {
    my($socket) = @_;

    close($socket)

    }

########################################################################
# ardp_send - send an ardp packet
#
# args:
#        $socket: ardp socket
#        $dest_addr: sock_addr for destination
#        %req: associative array of packet header fields
# returns:
#        $chars: number of characters sent
########################################################################
sub ardp_send {
    my($socket, $dest_addr, %req) = @_;
    my($header, $flags1, $flags2, $flags3, $hbyte);

    ### set flags ###
    $flags1 = 0x00;
    $flags1 |= 0x01 if $req{'addr_info_flag'};
    $flags1 |= 0x02 if $req{'priority_flag'};
    $flags1 |= 0x04 if $req{'priority_id_flag'};
    $flags1 |= 0x40 if $req{'seq_control_flag'};
    $flags1 |= 0x80 if $req{'want_ack_flag'};

  SET_FLAGS: {
      $flags2 = 0x01, last SET_FLAGS if $req{'cancel_flag'};
      $flags2 = 0x02, last SET_FLAGS if $req{'reset_recvd_through_flag'};
      $flags2 = 0x03, last SET_FLAGS if $req{'extra_packets_recvd_flag'};
      $flags2 = 0x04, last SET_FLAGS if $req{'redirect_flag'};
      $flags2 = 0x05, last SET_FLAGS if $req{'redirect_and_notify_flag'};
      $flags2 = 0x06, last SET_FLAGS if $req{'forward_flag'};
      $flags2 = 0x07, last SET_FLAGS if $req{'forward_and_notify_flag'};
      $flags2 = 0xFD, last SET_FLAGS 
          if $req{'request_queue_status_flag'};
      $flags2 = 0xFE, last SET_FLAGS 
          if $req{'respond_queue_status_flag'};
  }

    ### build header ###
    $header = pack("xnnnnnCC", $req{'id'},
                   $req{'current_packet'}, $req{'total_packets'},
                   $req{'recvd_through'}, $req{'delay'}, 
                   $flags1, $flags2);

    if( $req{'priority_flag'} ) {
        $header .= pack("n", $req{'priority'});
    }
    
    if($req{'request_queue_status_flag'}) {
        $flags3 |= 0x01 if $req{'queue_status_pos_flag'};
        $flags3 |= 0x02 if $req{'queue_status_time_flag'};
        $header .= pack("C", $flags3);
    }

    ### first byte ###
    $hbyte = 0x00;
    $hbyte = pack("C", ($ardp_version & 0x03) << 6);
    $hbyte |= pack("C", length($header) & 0x03F);

    substr($header, 0, 1) = $hbyte;
    
    if($ardp_debug) {
        print ">>>>>>>> ARDP_SEND:\n";
        foreach $key (sort keys %req) {
            print "> $key: $req{$key}\n";
        }
        print "> ", grep($_ = sprintf(" %2.2X ", $_), 
                         unpack("C*", $header)), "\n";
        print "> ", grep($_ = sprintf("%3.3d ", $_), 
                         unpack("C*", $header)), "\n";
        print ">>>>>>>>\n";
    }

    send($socket, $header . $req{'data'}, 0, $dest_addr);

}

########################################################################
# ardp_recv - get and parse a ardp packet
#
# args:
#       $socket: ardp socket
#       $timeout: time in seconds to wait for packet to arrive
# returns: 
#       %resp: associative array of packet header fields and data
########################################################################
sub ardp_recv {
    my($socket, $timeout) = @_;
    my($rin, $rout, $header, $hdr_len);
    my(%resp);

    ### poll for a packet ###
    $rin = '';
    vec($rin, fileno(ARDP_SOCKET), 1) = 1;
    ($nfound, $timeleft) = select($rout = $rin, undef, undef, $timeout);

    ### answer hazy -- try again later ###
    if ($nfound <= 0 or !vec($rin, fileno(ARDP_SOCKET), 1)) {
        return(%resp);
    }

    ### Read a packet from the server ###
    $resp{'data'} = '';
    recv($socket, $resp{'data'}, 10000, 0);

    ### parse first byte ###
    $hbyte = ord($resp{'data'});
    $resp{'ardp_version'} = ($hbyte & 0xc0) >> 6;
    $hdr_len = $hbyte & 0x3F;

    if( $hdr_len ) {
        ### get header ###
        $save_header = $header = substr($resp{'data'}, 0, $hdr_len);

        ### remove header from data ###
        substr($resp{'data'}, 0, $hdr_len) = '';

        ### unpack header ###
        ($hbyte, $resp{'id'}, $resp{'current_packet'}, $resp{'total_packets'}, 
         $resp{'recvd_through'}, $resp{'delay'}, $flags1, $flags2) =
             unpack("CnnnnnCC", $header);

        ### remainder of header ###
        substr($header, 0, 13) = '';

        ### check flags ###
        $resp{'addr_info_flag'} =   (($flags1 & 0x01) != 0);
        $resp{'priority_flag'} =    (($flags1 & 0x02) != 0);
        $resp{'priority_id_flag'} = (($flags1 & 0x04) != 0);
        $resp{'seq_control_flag'} = (($flags1 & 0x40) != 0);
        $resp{'want_ack_flag'} =    (($flags1 & 0x80) != 0);

      FLAGS: {
          last FLAGS if $resp{'cancel_flag'} = ($flags2 == 1);
          last FLAGS if $resp{'reset_recvd_through_flag'} = ($flags2 == 2);
          last FLAGS if $resp{'extra_packets_recvd_flag'} = ($flags2 == 3);
          last FLAGS if $resp{'redirect_flag'} = ($flags2 == 4);
          last FLAGS if $resp{'redirect_and_notify_flag'} = ($flags2 == 5);
          last FLAGS if $resp{'forward_flag'} = ($flags2 == 6);
          last FLAGS if $resp{'forward_and_notify_flag'} = ($flags2 == 7);
          last FLAGS if $resp{'request_queue_status_flag'} = ($flags2 == 253);
          last FLAGS if $resp{'respond_queue_status_flag'} = ($flags2 == 254);
      }

        ### get extra header data ###
        ### there can be one or more of the following ###
        if( $resp{'addr_info_flag'} ) {
            ($resp{'type'},$resp{'addr_length'}) = unpack("CC", $header);
            $resp{'addr'} = substr($header, 2, $resp{'addr_length'});
            substr($header, 0, 2 + $resp{'addr_length'}) = '';
        }
        if( $resp{'priority_flag'} ) {
            $resp{'priority'} = unpack("n", $header);
            substr($header, 0, 2) = '';
        }
        if( $resp{'priority_id_flag'} ) {
            $resp{'priority_id'} =  unpack("n", $header);
            substr($header, 0, 2) = '';
        }

        ### there can only be one of the following ###
        if( $resp{'extra_packets_recvd_flag'} ) {
            $resp{'extra_packets_recvd'} = $header;
        }
        if( $resp{'redirect_flag'} ) {
            ($resp{'addr'}, $resp{'port'}) = unpack("a4n", $header);
        }
        if( $resp{'redirect_and_notify_flag'} ) {
            ($resp{'addr'}, $resp{'port'}) = unpack("a4n", $header);
        }
        if( $resp{'forward_flag'} ) {
            ($resp{'addr'}, $resp{'port'}) = unpack("a4n", $header);
        }
        if( $resp{'forward_and_notify_flag'} ) {
            ($resp{'addr'}, $resp{'port'}) = unpack("a4n", $header);
        }
        if( $resp{'request_queue_status_flag'} ) {
            $flags3 = unpack("C", $header);
            $resp{'queue_status_pos_flag'} = (($flags3 & 0x01) != 0);
            $resp{'queue_status_time_flag'} = (($flags3 & 0x02) != 0);
        }
        if( $resp{'respond_queue_status_flag'} ) {
            $flags3 = unpack("C", $header);
            substr($header, 0, 1) = '';
            $resp{'queue_status_pos_flag'} = (($flags3 & 0x01) != 0);
            $resp{'queue_status_time_flag'} = (($flags3 & 0x02) != 0);

            if( $resp{'queue_status_pos_flag'} ) {
                $resp{'queue_status_pos'} = unpack("n", $header);
                substr($header, 0, 2) = '';
            }

            if( $resp{'queue_status_time_flag'} ) {
                $resp{'queue_status_time'} = unpack("N", $header);
                substr($header, 0, 4) = '';
            }
        }

        ### if delay is null, keep default ###
        $resp{'delay'} = $resp{'delay'} ? $resp{'delay'} : $timeout;

        ### check for control packet ###
        if( $resp{'current_packet'} == 0 || $resp{'seq_control'} ) {
            $resp{'got_control'} = 1;
        }
        else {
            $resp{'got_response'} = 1;
        }

    }

    if($ardp_debug) {
        print "<<<<<<<< ARDP_RECV:\n";
        foreach $key (sort keys %resp) {
            print "< $key: $resp{$key}\n";
        }
        print "< ", grep($_ = sprintf(" %2.2X ", $_), 
                         unpack("C*", $save_header)), "\n";
        print "< ", grep($_ = sprintf("%3.3d ", $_), 
                         unpack("C*", $save_header)), "\n";
        print "<<<<<<<<\n";
    }

    %resp;
}

### return true for require ###
1;
########################################################################
# end of file Archie.pm
########################################################################
