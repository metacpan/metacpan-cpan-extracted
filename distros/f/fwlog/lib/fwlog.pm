package fwlog;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&Auto &Summary &Protocol &Service);
@EXPORT_OK = qw(&Auto &Summary &Protocol &Service);
1;

$VERSION="1.3";

# Set some common regex's.
my $ipAddress = qr/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/;


# Attempt to auto detect the log type
#
sub Auto {

	my $logline = shift;

	if ($logline) {

		#################################################################
		# Netscreen logs - not sure which version
		#
        	if ($logline =~ /NetScreen device_id/ && $logline =~ /action=/) {
			return &NetScreen($logline);


		#################################################################
		# Checkpoint <= R55 fw log -ftn logs
		#
		} elsif ($logline =~
			/ 

			# This should also work for syslog formatted CP logs
			# which is why there's no start of line anchor "^".

			\d\d?:\d\d?:\d\d?\s			# HH:MM:SS
			(accept|drop|reject|encrypt|decrypt)\s	# action

			/x) {

			return &Checkpoint($logline);


		#################################################################
		# Cisco Pix logs v6.x and possibly others
		#
		} elsif ($logline =~ /%(PIX|FWSM)-\d+-\d+:/) {
			return &Pix($logline);


		#################################################################
		# IPCHAINS
		} elsif ($logline =~ /Packet log:/) {
			return &Ipchains($logline);


		#################################################################
		# IPTABLES with FWBuilder
		#
		} elsif ($logline =~ /kernel:\sRULE\s\d+\s--/) {
			return &Fwbuilder($logline);


		#################################################################
		# ipf
		#
		} elsif ($logline =~ /ipmon\[\d+\]:\s/) {
			return &Ipfilter($logline);


		#################################################################
		# pfSense
		#
		} elsif ($logline =~ /\spf:\s/) {
			return &pfSense($logline);


		#################################################################
		# Unable to auto detect this line
		#
		} else {
			return undef;
		}
	}
}


# Allow Summary function for backwards compatibility
#
sub Summary {
	&Auto(shift);
}


# Return protocol from /etc/protocols file
#
sub Protocol {

        my @protocolLine = ();
        my %protocol = ();

        if (open (PROTOCOLS, "/etc/protocols")) {
                while (<PROTOCOLS>) {
                        unless (/^#/)  {
                                chomp;
                                @protocolLine = split;
                                $protocol{$protocolLine[1]} = $protocolLine[0];
                        }
                }
                close PROTOCOLS;

        } else {
                warn "Error: could not open /etc/protocols\n";
                return undef;
        }

        return $protocol{$_[0]};
}


# Return service from /etc/services file
#
sub Service {

        my @servicesLine = ();
        my %services = ();

        if (open (SERVICES, "</etc/services")) {
                while (<SERVICES>) {
                        unless (/^#/)  {
                                chomp;
                                @servicesLine = split;
                                $services{$servicesLine[1]} = $servicesLine[0];
                        }
                }
                close SERVICES;

        } else {
                warn "Error: could not open /etc/services\n";
                return undef;
        }
	
        return $services{lc($_[0])};

}


# pfSense log parser
#
sub pfSense {

	my $logline = shift;
	my $action = "";
	my $source="";
	my $destination="";
	my $protocol="";
	my $port="";

	if ( $logline =~ /tcp|mss|win \d+$/ ) {
       		$protocol = "tcp";

		$logline =~ /\s((pass)|(block))\s/;
		$action = $1;
		$action =~ s/pass/accept/;
		$action =~ s/block/drop/;

		$logline =~ /($ipAddress)\.\d+\s\>\s($ipAddress)\.(\d+)/;
		$source = $1;
		$destination = $2;
		$port = $3;

		return "$action|$source|$destination|$protocol|$port";
	} 

	if (   $logline =~ /\[\|domain\]$/
	    || $logline =~ /\[\|isakmp\]$/
	    || $logline =~ / NTPv\d, /
	    || $logline =~ / SYSLOG /
	    || $logline =~ / UDP, /
	    || $logline =~ / SIP, /
	    || $logline =~ / NBT UDP PACKET/ ) {
       		$protocol = "udp";

		$logline =~ /\s((pass)|(block))\s/;
		$action = $1;
		$action =~ s/pass/accept/;
		$action =~ s/block/drop/;

		$logline =~ /($ipAddress)\.\d+\s\>\s($ipAddress)\.(\d+)/;
		$source = $1;
		$destination = $2;
		$port = $3;

		return "$action|$source|$destination|$protocol|$port";
	} 

	if (   $logline =~ / ICMP (.+), /) {
		$port = $1;
       		$protocol = "icmp";

		$logline =~ /\s((pass)|(block))\s/;
		$action = $1;
		$action =~ s/pass/accept/;
		$action =~ s/block/drop/;

		$logline =~ /($ipAddress)\s\>\s($ipAddress)/;
		$source = $1;
		$destination = $2;

		return "$action|$source|$destination|$protocol|$port";
	} 
}

sub NetScreen {

	my $logline = $_[0];
	my $action = "";
	my $source="";
	my $destination="";
	my $protocol="";
	my $port="";

	$logline =~ /\sproto=(\d+)\s/;
       	$protocol = &Protocol($1);

       	if ($protocol eq "icmp") {
       		$logline =~ /icmp\stype=(\d+)/;
       		$port = "type-$1";

       	} else {
       		$logline =~ /dst_port=(\d+)/;
       		$port = $1;
       	}

       	$logline =~ /.*action=(\w+)\s/;
       	$action = $1;

       	$logline =~ /.*src=($ipAddress)\s/;
       	$source = $1;

       	$logline =~ /.*dst=($ipAddress)\s/;
       	$destination = $1;

	return "$action|$source|$destination|$protocol|$port";
}


sub Checkpoint {

	my $logline = $_[0];
	my $action = "";
	my $source="";
	my $destination="";
	my $protocol="";
	my $port="";

	$logline =~ s/src:/src/g;
	$logline =~ s/dst:/dst/g;
	$logline =~ s/proto:/proto/g;
	$logline =~ s/service:/service/g;
	$logline =~ s/icmp-type:/icmp-type/g;
	$logline =~ s/icmp-code:/icmp-code/g;
	$logline =~ s/;//g;
	$logline =~ s/^[\s\t]+//g;

	$logline =~ /\sproto\s(\w+)/;
       	$protocol = lc($1);

	if ($protocol eq "icmp") {
		my $icmpType = "unknown";
		my $icmpCode = "unknown";

		if ($logline =~ / icmp-type /) {
			$logline =~ /icmp-type\s(\d+)/;
			$icmpType = $1;
		}

		if  ($logline =~ / icmp-code /) {
			$logline =~ /icmp-code\s(\d+)/;
			$icmpCode = $1;
		}
       
		$port = "(type-$icmpType,code-$icmpCode)";

       	} else {
			$logline =~ /service\s([\d\w\-_]+)/;
			$port = $1;
       	}

	$logline =~ /^[0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}\s(\w+)\s/;
       	$action = $1;

       	$logline =~ /.*src\s($ipAddress)\s/;
       	$source = $1;

       	$logline =~ /.*dst\s($ipAddress)\s/;
       	$destination = $1;

	return "$action|$source|$destination|$protocol|$port";
}


sub Pix {

	my $logline = $_[0];
	my $action = "";
	my $source="";
	my $destination="";
	my $protocol="";
	my $port="";

	# 6-302013 and 6-302015
	if ($logline =~ /

		%PIX-6-30201[35]:\s
		Built\s(in|out)bound\s([\d\w]+)\sconnection\s\d+\s
		for\s.+:(.+)\/(\d+)(?:\s\(.+\))?\s
		to\s.+:(.+)\/(\d+)\s.*

		/x) {

		$action="accept";
		$source=$3;
		$destination=$5;
		$protocol=lc($2);

		if ($1 eq "in") {
			$port=$6;
		} else {
			$port=$4;
		}
	}

	# 5-304001
	if ($logline =~ /

		%PIX-5-304001:\s
		(.+)
		\sAccessed\sURL\s
		(.+):

		/x) {

		$action="accept";
		$source=$1;
		$destination=$2;
		$protocol="tcp";
		$port="80";	# assumed
	}

	# 6-106015
	if ($logline =~ /

		%PIX-6-106015:\sDeny\s
		(\w+)\s\(.+\)\s
		from\s(.+)\/\d+\s
		to\s(.+)\/(\d+)\s

		/x) {

		$action="drop";
		$source=$2;
		$destination=$3;
		$protocol=lc($1);
		$port=$4;
	}

	# 3-305005
	if ($logline =~ /

		#%PIX-3-305005:\sNo\stranslation\sgroup\sfound\sfor\s
		#(\w+)\ssrc\s.+:
		#(.+)\/\d+\sdst\s.+:
		#(.+)\/(\d+)

		%PIX-3-305005:\sNo\stranslation\sgroup\sfound\sfor\s
		(\w+)\ssrc\s.+:
		([-._\d\w]+)(?:\/\d+)?\sdst\s.+:
		([-._\d\w]+)(?:\/(\d+)|\s\((.+)\))

		/x) {

		$action="drop";
		$source=$2;
		$destination=$3;
		$protocol=lc($1);
		$port="$4$5";

		# make ICMP format the fwlog standard
		$port =~ s/,\s/,/g;
		$port =~ s/\s/-/g;
	}

	# 3-106011
	if ($logline =~ /
		%PIX-3-106011:\sDeny\sinbound\s\(No\sxlate\)\s
		(\w+)\ssrc\s.+:
		([-._\d\w]+)(?:\/\d+)?\sdst\s.+:
		([-._\d\w]+)(?:\/(\d+)|\s\((.+)\))

		/x) {

		$action="drop";
		$source=$2;
		$destination=$3;
		$protocol=lc($1);
		$port="$4$5";

		# make ICMP format the fwlog standard
		$port =~ s/,\s/,/g;
		$port =~ s/\s/-/g;
	}

	if ($action && $source && $destination && $protocol && $port) {
		return "$action|$source|$destination|$protocol|$port";
	} else {
		return undef;
	}
}


sub Fwbuilder {

        my $logline = $_[0];
        my $source="";
        my $destination="";
        my $protocol="";
        my $port="";

	$logline =~ /kernel:\sRULE\s\d+\s\-\-\s(\w+)\s/;
	$action = lc($1);
	$action =~ s/deny/drop/;

	$logline =~ /\sSRC=($ipAddress)\s/;
	$source = $1;

	$logline =~ /\sDST=($ipAddress)\s/;
	$destination = $1;

	$logline =~ /\sDPT=(\d+)\s/;
	$port = $1;

	$logline =~ /\sPROTO=([\d\w]+)\s/;
	$protocol = lc($1);

        return "$action|$source|$destination|$protocol|$port";
}


sub Ipfilter {

        my $logline = $_[0];
        my $source="";
        my $destination="";
        my $protocol="";
        my $port="";

        $logline =~ /ipmon\[\d+\]:.*@\d+:\d+\s(\w)\s/;
        $action = lc($1);
	if ($action eq "p") {
		$action="accept";
	} elsif ($action eq "b") {
		$action="drop";
	} 

        $logline =~ /\sPR\s([\d\w]+)\s/;
        $protocol = $1;

	if ($protocol eq "icmp") {

        	$logline =~ /\s($ipAddress)\s\-\>\s([$ipAddress)\s.*\sicmp\s([\d\w]+\/[\d\w])\s+/;
        	$source = $1;
		$destination =$2;
		$port=$3;

	} else {

        	$logline =~ /\s($ipAddress),(\d+)\s\-\>\s($ipAddress),(\d+)\s/;
        	$source = $1;
		my $sourcePort=$2;
		$destination =$3;
		$port=$4;

		if ($sourcePort < 1024) {
			if ($port > 1023) {
				$port=$sourcePort;
			}
		}

		# test
		if ($sourcePort < $port) {
			$port=$sourcePort;
		}
	}

        return "$action|$source|$destination|$protocol|$port";
}


sub Ipchains {

        my $logline = $_[0];
        my $source="";
        my $destination="";
        my $protocol="";
        my $port="";

        $logline =~ s/[ ]+/ /g;

        $logline =~ /Packet\slog:\s\w+\s([\w\d\-_]+)/;
        $protocol = $1;

        $logline =~ /\sPROTO=(\d+)/;
        $protocol = &Protocol($1);

        if ($protocol eq "icmp") {
                my $icmpType = "unknown";
                my $icmpCode = "unknown";

        	$logline =~ /\s$ipAddress:(\d)+\s$ipAddress:(\d+)\s/;
                $icmpType = $1;
                $icmpCode = $2;
                $port = "(type-$icmpType,code-$icmpCode)";
        } else {
        	$logline =~ /\s$ipAddress:\d+\s$ipAddress:(\d+)\s/;
                $port = $1;
        }

	if ($logline =~ /REDIRECT/) {
		$logline =~ /\sPacket\slog:\s\w+\s([\w+\d+\-_]+\s[\d\w\-_])/;
		$action = $1;

	} else {
		$logline =~ /\sPacket\slog:\s\w+\s([\w+\d+\-_]+)\s/;
		$action = $1;
	}

        $logline =~ /\sPROTO\=\d+\s($ipAddress):\d+\s($ipAddress):\d+\s/;
        $source = $1;
        $destination = $2;

	# Smoothwall logs drops as a hyphen "-"
	if ($action == "-") {
		$action="drop";
	}

        return "$action|$source|$destination|$protocol|$port";
}



################ Documentation ################

=head1 NAME

fwlog	- extract connection data from firewall logs


=head1 SYNOPSIS

  use fwlog
  $result = fwlog::Auto(...one line of firewall logs...);
  $result = fwlog::Protocol(protocol number);
  $result = fwlog::Service(port number/protocol number);


=head1 DESCRIPTION

B<fwlog::Auto> extracts the following data from firewall logs.

	- Action
	- Source
	- Destination
	- Protocol
	- Port

Data is returned seperated by vertical bars "|".  For example
"drop|10.1.1.1|192.168.1.1|tcp|25".

B<fwlog::Protocol> resolves IP Protocol numbers to names using your /etc/protocols file

B<fwlog::Services> resolves service numbers to names using your /etc/services file and IP protocol number

Note:  to use fwlog::Service for ICMP types and codes as per RFC-792 add the following to your /etc/services

  # fwlog services
  ping-request            (type-8,code-0)/icmp                    
  ping-reply              (type-0,code-0)/icmp                    
  network-unreachable     (type-3,code-0)/icmp                    
  host-unreachable        (type-3,code-1)/icmp                    
  protocol-unreachable    (type-3,code-2)/icmp                    
  port-unreachable        (type-3,code-3)/icmp                    
  frag-needed-but-DF-set  (type-3,code-4)/icmp                    
  src-route-failed        (type-3,code-5)/icmp                    
  source-quench           (type-4,code-0)/icmp                    
  parameter-problem       (type-12,code-0)/icmp                   
  ttl-excd-in-tran        (type-11,code-0)/icmp                   
  frag-reass-time-excd    (type-11,code-1)/icmp                   
  redir-net               (type-5,code-0)/icmp                    
  redir-host              (type-5,code-1)/icmp                    
  redir-ToS-and-net       (type-5,code-2)/icmp                    
  redir-ToS-and-host      (type-5,code-3)/icmp                    
  timestamp-request       (type-13,code-0)/icmp                   
  timestamp-reply         (type-14,code-0)/icmp                   
  info-request            (type-15,code-0)/icmp                   
  info-reply              (type-16,code-0)/icmp                   


=head1 CURRENT SUPPORTED LOG TYPES

	- Checkpoint Firewall-1
		- accept
		- drop
		- reject

	- NetScreen
		- Permit
		- Deny

	- CISCO Pix (IOS v6.1 and v6.2 and maybe others)
		- PIX-6-302013
		- PIX-5-304001
		- PIX-6-106015
		- PIX-3-305005
		- PIX-3-106011

	- Smoothwall (v0.9)
		- only chain logged is by Smoothwall is a hyphen "-". 

	- IPCHAINS
		- drops
		- rejects
		- redirects
		- custom chains

	- IPTABLES (using fwbuilder)
		- drops
		- accepts

	- ipf
		- pass
		- block

	- pfSense
		- pass
		- block

=head1 EXAMPLES


=item B<fwlog::Auto>

  use fwlog;

  while (<>) {
        chomp;
        my $data  = &fwlog::Auto($_);
        if ($data eq undef) {
                $unknownLines{$_}++;
                next;
        } else {
                $events{$data}++;
        }
  }

  print "\n\nConnections:\n";
  foreach my $event (sort {$events{$b} <=> $events{$a}} keys %events) {
        print "\t$events{$event}: $event\n";
  }

  print "\n\nLines not processed as connection data:\n";
  foreach my $unknown (sort {$unknownLines{$b} <=> $unknownLines{$a}} keys %unknownLines) {
        print "\t$unknownLines{$unknown}: $unknown\n";
  }

=item B<fwlog::Protocol>

  use fwlog;
  my $protocol =  &fwlog::Protocol("6");
  print "$protocol\n";


=item B<fwlog::Service>

  use fwlog;
  my $protocol =  &fwlog::Protocol("6");
  my $service  =  &fwlog::Service("25/$protocol");
  print "$protocol, $service\n";
  my $protocol =  &fwlog::Protocol("1");
  my $service  =  &fwlog::Service("(type-13,code-0)/$protocol");
  print "$protocol, $service\n";



=head1 AUTHOR

Ed Blanchfield <Ed@E-Things.Org>


=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2000 by Ed Blanchfield.

This program is free software; you can redistribute it and/or
modify it under the terms of the Perl Artistic License or the
GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

If you do not have a copy of the GNU General Public License write to
the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
MA 02139, USA.

=cut

# Local Variables:
# eval: (load-file "pod.en")
# End:

