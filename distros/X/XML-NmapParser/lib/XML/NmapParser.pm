package NmapParser; 

use strict;
use warnings;

use XML::NmapParser::Host; 
use XML::NmapParser::Host::Service;
use XML::NmapParser::Host::OS;
use XML::NmapParser::Host::Script;
use XML::NmapParser::Host::TraceHop;

use Exporter qw(import);

our $VERSION = "0.1";  
our @EXPORT_OK = qw(new parse livehosts RecursiveXMLtags);


sub new {
    my $pkg = shift;
    my $self = bless {}, $pkg;
    $self->initialize(@_);
    $self;
}

sub initialize {
    my $self = shift;
    $self->{stem} = shift;
    $self->{english} = shift;
}
  
 
sub parse {
	
	my ($self,$filename) = @_;
	
	$self->{parsed} = {};
	 
	my $parser = XML::LibXML->new();
	my $nmapXML = $parser->parse_file($filename); 
	
	foreach ( $nmapXML->findnodes('/nmaprun') ) {
		if ( $_->hasAttributes() ) { 
			for my $attribute ( $_->attributes() ) { $self->{parsed}{nmaprun}{$attribute->name} = $attribute->getValue;} 
		}
	} 
	foreach ( $nmapXML->findnodes('/nmaprun/scaninfo') ) {
		if ( $_->hasAttributes() ) { 
			for my $attribute ( $_->attributes() ) {$self->{parsed}{scaninfo}{$attribute->name} = $attribute->getValue;} 
		}
	}
	
	foreach ( $nmapXML->findnodes('/nmaprun/runstats')) {
		if ( $_->hasAttributes() ) { 
			for my $attribute ( $_->attributes() ) { $self->{parsed}{runstats}{$attribute->name} = $attribute->getValue; } 
		}
		if ( $_->nonBlankChildNodes() ) {
			for my $child ( $_->nonBlankChildNodes() ) {
				my $name = $child->nodeName;
				if ( $child->hasAttributes() ) { 
					for my $attribute ( $child->attributes() ) { $self->{parsed}{runstats}{$name}{$attribute->name} = $attribute->getValue;}   
				}
			} 
		} 
	}
	
	#  need to add logic to get Verbose and debugging data.....
	# 
		
	#----------------------------------------------------------------------------------------------------------------------------------------
	# room for cleaner code below.....
	my @Hosts; 
	
	for my $HOST ( $nmapXML->findnodes('/nmaprun/host') ) {
		my %host;
		if ( $HOST->hasAttributes() ) { 
			for my $attribute ( $HOST->attributes() ) { $host{$attribute->name} = $attribute->getValue; }
		}
		foreach ($HOST->nonBlankChildNodes()) {
			my $name = $_->nodeName;
			
			if ( $_->hasAttributes() ) {
				if ( defined($host{$name})) { 
					my %hash;
					my @current;
					push(@current, {%{$host{$name}}});
					
					for my $attribute ( $_->attributes() ) {
						$hash{$attribute->name} = $attribute->getValue;
					} 
					push(@current, {%hash});
					$host{$name} = [@current]; 
				} else { 
					for my $attribute ( $_->attributes() ) {
						$host{$name}{$attribute->name} = $attribute->getValue;
					}				
				}  
			}
			if ( $name eq "ports") {
				my @ports;
				if ( $_->hasChildNodes() ) {
					for my $node ($_->nonBlankChildNodes()) {
						my %port; 
						my %extraports;
						my @cpe; 
						
						if ( $node->nodeName() eq "extraports") { 
							if ( $node->hasAttributes() ) {
								for my $attribute ( $node->attributes() ) {$extraports{$attribute->name} = $attribute->getValue;} 
							}
							if ($node->hasChildNodes()) {
								for my $n2 ($node->nonBlankChildNodes()) {
									for my $attribute ( $n2->attributes() ) {$extraports{reasons}{$attribute->name} = $attribute->getValue;}
								} 
							}
							push(@{$host{extraports}}, { %extraports } );
							next; 
						}
						elsif ( $node->nodeName() eq "port") { 
							my @scripts; 
							if ( $node->hasAttributes() ) {for my $attribute ( $node->attributes() ) {$port{$attribute->name} = $attribute->getValue;} }
							if ($node->hasChildNodes()) { 
								for my $n2 ($node->nonBlankChildNodes()) {
									my $child = $n2->nodeName(); 
									if ($child eq "script") {
										my %script;  
										if ( $n2->hasAttributes() ) {for my $attribute ( $n2->attributes() ) {
											$script{$attribute->name} = $attribute->getValue;}
										}
										if ( $n2->hasChildNodes()) { 
											for my $n3 ( $n2->nonBlankChildNodes()) {
												my $elemKey = 0;
												if (  $n3->hasAttributes() ) {
													for my $attribute ( $n3->attributes() ) { 
														$elemKey = $attribute->getValue;
														if ( defined($elemKey)) { $script{elem}{$elemKey} = $n3->textContent; }
													}
												}
											}
										}
										push(@scripts, {%script}); 
										
									} else { 
										if ( $n2->hasAttributes() ) {for my $attribute ( $n2->attributes() ) {$port{$child}{$attribute->name} = $attribute->getValue;}}
										if ( $n2->hasChildNodes()) { 
											for my $n3 ( $n2->nonBlankChildNodes()) {
												if (  $n3->nodeName() eq "cpe" ) { 
													if ( $n3->hasAttributes() ) {
														for my $attribute ( $n3->attributes() ) {
															$attribute->name = $attribute->getValue;
															push (@cpe, $attribute->getValue );
														}
													} else { push (@cpe,$n3->textContent); }
												} else {
													if ( $n3->hasAttributes() ) {for my $attribute ( $n3->attributes() ) {$port{$n3->nodeName()}{$attribute->name} = $attribute->getValue;}} 
												}
											}
										}										
									}
									if ( $#cpe > -1 ) { $port{service}{cpe} = [ @cpe ];}
									if ( $#scripts > -1 ) { $port{scripts} = [ @scripts]; }
								}
							}
#							print " "; 
							push(@{$host{ports}}, { %port } );							
							
						}						
					}
				}
			}  elsif ( $name eq "os") {
				my %os; 
				if ( $_->hasChildNodes() ) {
					my @portsused;  
					my @OSmatch;
					for my $node ($_->nonBlankChildNodes()) {
						my @cpe; 
						my $name1 = $node->nodeName();
						if ( $name1 eq "portused") { 
							my %hash; 
							if ( $node->hasAttributes() ) {
								for my $attribute ( $node->attributes() ) { $hash{$attribute->name} = $attribute->getValue; } 
							} 
							push(@portsused,{%hash});
						} elsif ( $name1 eq "osmatch") {
							my @match; 
							my %OSmatch;   
							if ( $node->hasAttributes() ) {for my $attribute ( $node->attributes() ) {$OSmatch{$attribute->name} = $attribute->getValue;} }
							if ($node->hasChildNodes()) {
								my @osclass;
								for my $n2 ($node->nonBlankChildNodes()) {
									if ( $n2->nodeName() eq "osclass" ) {
										my @cpe; 
										my %hash; 
										if ( $n2->hasAttributes() ) {for my $attribute ( $n2->attributes() ) {$hash{$attribute->name} = $attribute->getValue;}}
										if ( $n2->hasChildNodes()) {
											for my $n3 ( $n2->nonBlankChildNodes()) {
												if (  $n3->nodeName() eq "cpe" ) { 
													if ( $n3->hasAttributes() ) {
														for my $attribute ( $n3->attributes() ) {
															$attribute->name = $attribute->getValue;
															push (@cpe, $attribute->getValue );
														}
													} else { push (@cpe,$n3->textContent); }
												}
											}
										}
										if ( $#cpe > -1 ) { $hash{cpe} = [ @cpe]; } 
										push(@osclass, { %hash } );
									}
								}
								if ( $#osclass > "-1" ) { $OSmatch{osclass}  = [ @osclass]; } 
							}
							push( @OSmatch, { %OSmatch });  
						} elsif ( $name1 eq "osfingerprint") { 
							if ( $node->hasAttributes() ) {for my $attribute ( $node->attributes() ) {$os{$name1}{$attribute->name} = $attribute->getValue;} }
						}						

					}
					if ( $#portsused > "-1") { $os{portsused} = [ @portsused ]; }
					if ( $#OSmatch > "-1" ) { $os{osmatch}  = [ @OSmatch ]; }
					
 					$host{os} = { %os };
					
				}
			} elsif ( $name eq "hostnames") {
				my %hostname; 
				if ( $_->hasChildNodes() ) {
					for my $node ($_->nonBlankChildNodes()) {
						if ( $node->hasAttributes() ) {for my $attribute ( $node->attributes() ) {$hostname{$attribute->name} = $attribute->getValue;} }
						if ($node->hasChildNodes()) { 
							for my $n2 ($node->nonBlankChildNodes()) {
								if ( $n2->hasAttributes() ) { for my $attribute ( $n2->attributes() ) {$hostname{$attribute->name} = $attribute->getValue;} }
							}
						}
						push(@{$host{hostname}},{%hostname});
					}
				}
			} elsif ( $name eq "trace") {					
				if ( $_->hasAttributes() ) {
					for my $attribute ( $_->attributes() ) {
							$host{traceroute}{$attribute->name} = $attribute->getValue;
						}
				} 
				for my $T ( $_->nonBlankChildNodes() ) {
					my %hop;
					if ( $T->hasAttributes() ) {
						for my $attribute ( $T->attributes() ) {
							$hop{$attribute->name} = $attribute->getValue;
						} 
					}
					push(@{$host{traceroute}{hop}}, {%hop} );
				}
				# next;
			} elsif ( $name eq "hostscript" ) {
				my @hostscripts; 				
				if ( $_->hasAttributes() ) {
					for my $attribute ( $_->attributes() ) { $host{hostscript}{$attribute->name} = $attribute->getValue; }
				} 
				if ( $_->hasChildNodes() ) {
					for my $node ($_->nonBlankChildNodes()) { 
						my %script; 
						if ( $node->nodeName() eq "script" ) { 
							if ( $node->hasAttributes() ) {
								for my $attribute ( $node->attributes() ) { $script{$attribute->name} = $attribute->getValue; }
								if ( $node->hasChildNodes() ) {
									for my $n2 ( $node->nonBlankChildNodes() ) {
										my $elemKey;
										for my $attribute ( $n2->attributes() ) { $elemKey = $attribute->getValue; }
										$script{elem}{$elemKey} = $n2->textContent;
									}
								}
							} 
						}
						push(@hostscripts, {%script} );
					}
				}
				$host{hostscript}{scripts} = [ @hostscripts ];
			} 
		} 

		push(@Hosts,{%host})
	}
	$self->{parsed}{hosts} = [ @Hosts ] ;		
	undef $nmapXML;
	return 0;
}
 

sub nmap_version { 
	my ($self) = @_;
	return $self->{parsed}{nmaprun}{version};	
}
sub numservices { 
	my ($self) = @_;
	return $self->{parsed}{scaninfo}{numservices};	
}

sub scan_args {
	my ($self) = @_;
	return $self->{parsed}{nmaprun}{args};
}

sub scan_type_proto { 
	my ($self) = @_;
	return $self->{parsed}{scaninfo}{protocol};	
}

sub scan_types { 
	my ($self) = @_;
	return $self->{parsed}{scaninfo}{type};		
}


sub start_str { 
	my ($self) = @_;
	return $self->{parsed}{nmaprun}{startstr};	
}

sub start_time { 
	my ($self) = @_;
	return $self->{parsed}{nmaprun}{start};	
}

sub finished_str {
	my ($self) = @_;
	return $self->{parsed}{runstats}{finished}{timestr};
} 
sub finished_time {
	my ($self) = @_;
	return $self->{parsed}{runstats}{finished}{time}; 	
} 	
sub time_str {
	my ($self) = @_;
	return $self->{parsed}{runstats}{finished}{timestr}; 
}

sub xml_version { 
	my ($self) = @_;
	return $self->{parsed}{nmaprun}{xmloutputversion};
}

sub live {	
	my ($self) = @_;
	return $self->{parsed}{runstats}{hosts}{up}; 
}

sub down {	
	my ($self) = @_;
	return $self->{parsed}{runstats}{hosts}{down}; 
}


sub scanned {	
	my ($self) = @_;
	return $self->{parsed}{runstats}{hosts}{total}; 
}

sub get_address { 
	my ($self,$state,$type) = @_;
	my @list;
	foreach ( @{$self->{parsed}{hosts}}) {
		if ((defined($state)) && ($_->{status}{state} ne $state) ) { 
			next; 
		} else { 
			if ( ref($_->{address}) eq "HASH" ) { 
				if ( $_->{address}{addrtype} eq $type) { 
					push(@list, $_->{address}{addr}); 
				}
			} else {
				for my $A ( @{$_->{address}}) { 
					if ( $A->{addrtype} eq $type ) { 
						push(@list, $A->{addr});
					}
				}
			} 			
		}
	} 
	return @list; 
}

sub get_ips {
	my ($self,$state,$type) = @_;
	if ( ! defined($type)) { $type = "ipv4"; }
	my @iplist =  get_address($self,$state,$type); 

	return @iplist;
}

sub get_host {
	 
	my ($self,$hostIP) = @_;
	my $host; 	
	foreach ( @{$self->{parsed}{hosts}}) {
		if (ref($_->{address}) eq "HASH" ) { 
			$host = $_ if ( $_->{address}{addr} eq $hostIP );
		} elsif (ref($_->{address}) eq "ARRAY") {
			for my $element ( @{$_->{address}}) { 
				$host = $_ if ( $element->{addr} eq $hostIP );
			} 
		}
	}
 
	my $HOST = NmapParser::Host->new($host);
	return $HOST; 
		
}



__END__

=pod

=head1 NAME

NmapParser - parse nmap scan data with perl

=head1 SYNOPSIS

  use XML::NmapParser;
  my $parser = NmapParser->new();
  
  my $parsedFile = $parser->parse(<NMAP XML file>);
  
  my $ScannedIPs = $parser->scanned();
  my $LiveHosts = $parser->live();
  
  my @IPs = $parser->get_ips();
  
  my $host = $parser->get_host($ip);
    # NmapParser::Host object

  my @HostScripts = $host->hostscripts(); 
        # returns an array of NmapParser::Host::Script objects
   
  my $service = $host->tcp_service(<PORT>);
    # NmapParser::Host::Service object
    
  my @PortScripts = $host_portscripts(<PORT>);   
    # returns an array of NmapParser::Host::Script objects
    
  my @OS = $host->os_sig();
    # returns an array of NmapParser::Host::OS objects 
 

I<For a full listing of methods see the documentation corresponding to each object.>

=head1 DESCRIPTION

A perl module to JUST parse nmap XML data output. 

It is a fork of the Nmap-Parser minus the ability to do any scannings. It 
maintains all the calls of the other module along with adding some additional 
calls. It also adds a new method for accessing both host script and port 
script results. It also removes the Nmap::Parser::Session object in favor 
of making those default methods fpr the parsed object. 

current code can be found at L<http://github.com/littleurl/XML-NmapParser/>

=head1 OVERVIEW

This module has an internal framework to make it easy to retrieve the desired information of a scan.
Every nmap scan is based on two main sections of informations: the scan session, and the scan information of all hosts.
The session information will be stored as a Nmap::Parser::Session object. This object will contain its own methods
to obtain the desired information. The same is true for any hosts that were scanned using the Nmap::Parser::Host object.
There are two sub objects under Nmap::Parser::Host. One is the Nmap::Parser::Host::Service object which will be used to obtain
information of a given service running on a given port. The second is the Nmap::Parser::Host::OS object which contains the
operating system signature information (OS guessed names, classes, osfamily..etc).

  Nmap::Parser                         -- Core parser
     |  
     +--Nmap::Parser::Host             -- General host information
     |  |
     |  |-Nmap::Parser::Host::Service  -- Port service information
     |  |
     |  |-Nmap::Parser::Host::OS       -- Operating system signature information
     |  |
     |  |-Nmap::Parser::Host::Service  -- Port service information
     |  |
     |  |-Nmap::Parser::Host::Script   -- any NSE script data for host or port based scripts
     |  |
     |  |-Nmap::Parser::Host::TraceHop -- any traceroute data for hosts scanned 


=head1 METHODS

=head2 NmapParser

The main idea behind the core module is, you will first parse the information
and then extract data. Therefore, all parse*() methods should be executed before
any get_*() methods.

=over 4

=item B<parse($xml_file)>

Parses the nmap scan data in $xml_file. This file can be generated from an nmap
scan by using the '-oX filename.xml' option with nmap. If you get an error or your program dies due to parsing, please check that the
xml information is compliant. The file is closed no matter how C<parsefile()> returns.

=item B<get_host($ip_addr)>

Obtains the Nmap::Parser::Host object for the given $ip_addr.

=item B<get_ips()>

=item B<get_ips($status,$type)>

Returns the list of IP addresses that were scanned in this nmap session. They are
sorted using addr_sort. If the optional status is given, it will only return
those IP addresses that match that status. The status can be any of the
following: C<(up|down|unknown|skipped)>. And the type can be either C<(ipv4|ipv6)>.


=item B<live()>

Returns the number of hosts identified as live by the scan

=item B<down()>

Returns the number of hosts identified as down by the scan

=item B<scanned()>

Returns the number of hosts scanned

=item B<get_address()>


=item B<get_host()>


=item B<finish_time()>

Returns the numeric time that the nmap scan finished.

=item B<nmap_version()>

Returns the version of nmap used for the scan.

=item B<numservices()>

=item B<numservices($type)>

If numservices is called without argument, it returns the total number of services
that were scanned for all types. If $type is given, it returns the number of services
for that given scan type. See scan_types() for more info.

=item B<scan_args()>

Returns a string which contains the nmap executed command line used to run the
scan.

=item B<scan_type_proto($type)>

Returns the protocol type of the given scan type (provided by $type). See scan_types() for
more info.

=item B<scan_types()>

Returns the list of scan types that were performed. It can be any of the following:
C<(syn|ack|bounce|connect|null|xmas|window|maimon|fin|udp|ipproto)>.

=item B<start_str()>

Returns the human readable format of the start time.

=item B<start_time()>

Returns the numeric form of the time the nmap scan started.

=item B<time_str()>

Returns the human readable format of the finish time.

=item B<xml_version()>

Returns the version of nmap xml file.

=back

=head2 Nmap::Parser::Host

This object represents the information collected from a scanned host.


=over 4

=item B<status()>

Returns the state of the host. It is usually one of these
C<(up|down|unknown|skipped)>.

=item B<addr()>

Returns the main IP address of the host. This is usually the IPv4 address. If
there is no IPv4 address, the IPv6 is returned (hopefully there is one).

=item B<addrtype()>

Returns the address type of the address given by addr() .

=item B<all_hostnames()>

Returns a list of all hostnames found for the given host.

=item B<extraports_count()>

Returns the number of extraports found.

=item B<extraports_state()>

Returns the state of all the extraports found.

=item B<hostname()>

=item B<hostname($index)>

As a basic call, hostname() returns the first hostname obtained for the given
host. If there exists more than one hostname, you can provide a number, which
is used as the location in the array. The index starts at 0;

 #in the case that there are only 2 hostnames
 hostname() eq hostname(0);
 hostname(1); #second hostname found
 hostname(400) eq hostname(1) #nothing at 400; return the name at the last index
 

=item B<ipv4_addr()>

Explicitly return the IPv4 address.

=item B<ipv6_addr()>

Explicitly return the IPv6 address.

=item B<mac_addr()>

Explicitly return the MAC address.

=item B<mac_vendor()>

Return the vendor information of the MAC.

=item B<distance()>

Return the distance (in hops) of the target machine from the machine that performed the scan.

=item B<trace_error()>

Returns a true value (usually a meaningful error message) if the traceroute was
performed but could not reach the destination. In this case C<all_trace_hops()>
contains only the part of the path that could be determined.

=item B<all_trace_hops()>

Returns an array of Nmap::Parser::Host::TraceHop objects representing the path
to the target host. This array may be empty if Nmap did not perform the
traceroute for some reason (same network, for example).

Some hops may be missing if Nmap could not figure out information about them.
In this case there is a gap between the C<ttl()> values of consecutive returned
hops. See also C<trace_error()>.

=item B<trace_proto()>

Returns the name of the protocol used to perform the traceroute.

=item B<trace_port()>

Returns the port used to perform the traceroute.

=item B<os_sig()>

Returns an Nmap::Parser::Host::OS object that can be used to obtain all the
Operating System signature (fingerprint) information. See Nmap::Parser::Host::OS
for more details.

 $os = $host->os_sig;
 $os->name;
 $os->osfamily;

=item B<tcpsequence_class()>

=item B<tcpsequence_index()>

=item B<tcpsequence_values()>

Returns the class, index and values information respectively of the tcp sequence.

=item B<ipidsequence_class()>

=item B<ipidsequence_values()>

Returns the class and values information respectively of the ipid sequence.

=item B<tcptssequence_class()>

=item B<tcptssequence_values()>

Returns the class and values information respectively of the tcpts sequence.

=item B<uptime_lastboot()>

Returns the human readable format of the timestamp of when the host had last
rebooted.

=item B<uptime_seconds()>

Returns the number of seconds that have passed since the host's last boot from
when the scan was performed.

=item B<hostscripts()>

=item B<hostscripts($name)>

A basic call to hostscripts() returns a list of the names of the host scripts
run. If C<$name> is given, it returns the text output of the
a reference to a hash with "output" and "content" keys for the
script with that name, or undef if that script was not run.
The value of the "output" key is the text output of the script. The value of the
"content" key is a data structure based on the XML output of the NSE script.

=item B<tcp_ports()>

=item B<udp_ports()>

Returns the sorted list of TCP|UDP ports respectively that were scanned on this host. Optionally
a string argument can be given to these functions to filter the list.

 $host->tcp_ports('open') #returns all only 'open' ports (even 'open|filtered')
 $host->udp_ports('open|filtered'); #matches exactly ports with 'open|filtered'
 
I<Note that if a port state is set to 'open|filtered' (or any combination), it will
be counted as an 'open' port as well as a 'filtered' one.>

=item B<tcp_port_count()>

=item B<udp_port_count()>

Returns the total of TCP|UDP ports scanned respectively.

=item B<tcp_del_ports($portid, [$portid, ...])>

=item B<udp_del_ports($portid, [ $portid, ...])>

Deletes the current $portid from the list of ports for given protocol.

=item B<tcp_port_state($portid)>

=item B<udp_port_state($portid)>

Returns the state of the given port, provided by the port number in $portid.

=item B<tcp_open_ports()>

=item B<udp_open_ports()>

Returns the list of open TCP|UDP ports respectively. Note that if a port state is
for example, 'open|filtered', it will appear on this list as well. 

=item B<tcp_filtered_ports()>

=item B<udp_filtered_ports()>

Returns the list of filtered TCP|UDP ports respectively. Note that if a port state is
for example, 'open|filtered', it will appear on this list as well. 

=item B<tcp_closed_ports()>

=item B<udp_closed_ports()>

Returns the list of closed TCP|UDP ports respectively. Note that if a port state is
for example, 'closed|filtered', it will appear on this list as well. 

=item B<tcp_service($portid)>

=item B<udp_service($portid)>

Returns the Nmap::Parser::Host::Service object of a given service running on port,
provided by $portid. See Nmap::Parser::Host::Service for more info. 

 $svc = $host->tcp_service(80);
 $svc->name;
 $svc->proto;
 

=back

=head3 Nmap::Parser::Host::Service

This object represents the service running on a given port in a given host. This
object is obtained by using the tcp_service($portid) or udp_service($portid) method from the
Nmap::Parser::Host object. If a portid is given that does not exist on the given
host, these functions will still return an object (so your script doesn't die).
Its good to use tcp_ports() or udp_ports() to see what ports were collected.

=over 4


=item B<confidence()>

Returns the confidence level in service detection.

=item B<extrainfo()>

Returns any additional information nmap knows about the service.

=item B<method()>

Returns the detection method.

=item B<name()>

Returns the service name.

=item B<owner()>

Returns the process owner of the given service. (If available)

=item B<port()>

Returns the port number where the service is running on.

=item B<product()>

Returns the product information of the service.

=item B<proto()>

Returns the protocol type of the service.

=item B<rpcnum()>

Returns the RPC number.

=item B<tunnel()>

Returns the tunnel value. (If available)

=item B<fingerprint()>

Returns the service fingerprint. (If available)
 
=item B<version()>

Returns the version of the given product of the running service.

=item B<scripts()>

=item B<scripts($name)>

A basic call to scripts() returns a list of the names of the NSE scripts
run for this port. If C<$name> is given, it returns
a reference to a hash with "output" and "content" keys for the
script with that name, or undef if that script was not run.
The value of the "output" key is the text output of the script. The value of the
"content" key is a data structure based on the XML output of the NSE script.

=back

=head3 Nmap::Parser::Host::OS

This object represents the Operating System signature (fingerprint) information
of the given host. This object is obtained from an Nmap::Parser::Host object
using the C<os_sig()> method. One important thing to note is that the order of OS
names and classes are sorted by B<DECREASING ACCURACY>. This is more important than
alphabetical ordering. Therefore, a basic call
to any of these functions will return the record with the highest accuracy.
(Which is probably the one you want anyways).

=over 4

=item B<all_names()>

Returns the list of all the guessed OS names for the given host.

=item B<class_accuracy()>

=item B<class_accuracy($index)>

A basic call to class_accuracy() returns the osclass accuracy of the first record.
If C<$index> is given, it returns the osclass accuracy for the given record. The
index starts at 0.

=item B<class_count()>

Returns the total number of OS class records obtained from the nmap scan.

=item B<name()>

=item B<name($index)>

=item B<names()>

=item B<names($index)>

A basic call to name() returns the OS name of the first record which is the name
with the highest accuracy. If C<$index> is given, it returns the name for the given record. The
index starts at 0.

=item B<name_accuracy()>

=item B<name_accuracy($index)>

A basic call to name_accuracy() returns the OS name accuracy of the first record. If C<$index> is given, it returns the name for the given record. The
index starts at 0.

=item B<name_count()>

Returns the total number of OS names (records) for the given host.

=item B<osfamily()>

=item B<osfamily($index)>

A basic call to osfamily() returns the OS family information of the first record.
If C<$index> is given, it returns the OS family information for the given record. The
index starts at 0.

=item B<osgen()>

=item B<osgen($index)>

A basic call to osgen() returns the OS generation information of the first record.
If C<$index> is given, it returns the OS generation information for the given record. The
index starts at 0.

=item B<portused_closed()>

Returns the closed port number used to help identify the OS signatures. This might not
be available for all hosts.

=item B<portused_open()>

Returns the open port number used to help identify the OS signatures. This might
not be available for all hosts.

=item B<os_fingerprint()>

Returns the OS fingerprint used to help identify the OS signatures. This might not be available for all hosts.

=item B<type()>

=item B<type($index)>

A basic call to type() returns the OS type information of the first record.
If C<$index> is given, it returns the OS type information for the given record. The
index starts at 0.

=item B<vendor()>

=item B<vendor($index)>

A basic call to vendor() returns the OS vendor information of the first record.
If C<$index> is given, it returns the OS vendor information for the given record. The
index starts at 0.

=back

=head3 Nmap::Parser::Host::TraceHop

This object represents a router on the IP path towards the destination or the
destination itself. This is similar to what the C<traceroute> command outputs.

Nmap::Parser::Host::TraceHop objects are obtained through the
C<all_trace_hops()> and C<trace_hop()> Nmap::Parser::Host methods.

=over 4

=item B<ttl()>

The Time To Live is the network distance of this hop.

=item B<rtt()>

The Round Trip Time is roughly equivalent to the "ping" time towards this hop.
It is not always available (in which case it will be undef).

=item B<ipaddr()>

The known IP address of this hop.

=item B<host()>

The host name of this hop, if known.

=back

=head1 EXAMPLES

 use Nmap::Parser;

 my $np = new Nmap::Parser;
 my @hosts = @ARGV; #get hosts from cmd line


=head1 SUPPORT

=head2 Discussion Forum

If you have questions about how to use the module please contact the author below.

=head2 Bug Reports, Enhancements, Merge Requests

Please submit any bugs or feature requests to:
L<https://github.com/littleurl/XML-NmapParser/issues>


=head1 SEE ALSO

nmap, XML::LibXML 

The nmap security scanner homepage can be found at: L<http://www.insecure.org/nmap/>.

=head1 AUTHORS

Paul M Johnson <pjohnson21211@gmail.com>
but credit to the original author of Nmap-Parser is Anthony Persaud L <http://modernistik.com>


=head1 COPYRIGHT

1; 