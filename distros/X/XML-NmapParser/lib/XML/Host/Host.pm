#
#
# 

package NmapParser::Host; 
use base "NmapParser";


my @ISA = "NmapParser";
  
  
use vars qw($AUTOLOAD);

## passed
sub new {
    my $pkg = shift;
    my $self = bless {}, $pkg;
    $self->initialize(@_);
    return $self;
}

# passed
sub initialize {
    my $self = shift;
    $self->SUPER::initialize(shift, shift);
    $self->{HOST} = shift;
}



# passed
sub hostname { 
	my ($self,$index) = @_;
	if (! defined($index)) { $index=0; }
	return ( ${$self->{stem}{hostname}}[$index]{name} );		
}

#passed
sub uptime_lastboot { 
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{uptime}{lastboot})) { $returnValue = $self->{stem}{uptime}{lastboot}; } 
	return $returnValue;	
}

#passed
sub uptime_seconds { 
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{uptime}{seconds})) { $returnValue = $self->{stem}{uptime}{seconds}; } 
	return $returnValue;	
}



#passed
sub all_hostnames { 
	my ($self) = @_;
	my @names;
	foreach ( @{$self->{stem}{hostname}}) { 
		push(@names,$_->{name});
	}	
	return @names; 
}


#passed
sub extraports_count {	
	my ($self,$state) = @_;
	my $count = 0;
	foreach ( @{$self->{stem}{extraports}}) {
		if ( ! defined($state)) {
			$count += $_->{count}; 
		} 	
	}	
	return $count; 
}

sub extraports_state { 
	my ($self,$index) = @_;
	my $returnValue = "-1";
	if (defined($index)) { $returnValue = $self->{stem}{extraports}[$index]{state};
	} else { $returnValue = $self->{stem}{extraports}[0]{state}; }
	return $returnValue;	
}


sub trace_port { }
sub trace_error { }
#sub all_trace_hops { }
sub all_trace_hops { 
	my ($self) = @_;
	my @hops; 
	if ( defined($self->{stem}{traceroute})) {
		if ( ref($self->{stem}{traceroute}{hop}) eq "ARRAY") { 
			foreach ( @{$self->{stem}{traceroute}{hop}}) { 
				push(@hops,$_);
			}
		} elsif ( ref($self->{stem}{traceroute}{hop}) eq "HASH") { 
			push(@hops,$self->{stem}{traceroute}{hop});
		} else { 
			die "WTF!!!! \n";
		}
		 
	}  
	
	return @hops; 
}

sub os_sig  { 
	my ($self) = @_;
	my $OS = NmapParser::Host::OS->new($self->{stem}{os});
	
	return $OS; 
}

sub portscripts { 
	my ($self,$port) = @_;
	my @returnValue;
  
	foreach ( @{$self->{stem}{ports}}) {
		if ( $_->{portid} eq $port ) {
			if ( $_->{scripts} ) {
				for my $script ( @{$_->{scripts}}) {
					my $SCRIPT = NmapParser::Host::Script->new($script);
					push(@returnValue, $SCRIPT); 
				}
			} 
		}
	}
		
	return @returnValue;
	
	
}

# passed
sub hostscripts { 
	my ($self,$name) = @_;
	my @returnValue;
	my $SCRIPT;  
	foreach ( @{$self->{stem}{hostscript}{scripts}} ) { 
		if ( defined($name)) { 
			if ( $name eq $_->{id} ) { 
				push(@returnValue,$_->{output});
			}
			push(@returnValue, { %{$_->{elem}}});
		} else {
			my $SCRIPT = NmapParser::Host::Script->new($_);
			push(@returnValue,$SCRIPT);
			# push(@returnValue,$_->{id});
		}	
	}
	return @returnValue;
}




sub trace_proto { 
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{trace}{proto})) { $returnValue = $self->{stem}{trace}{proto}; } 
	return $returnValue;		
}


sub tcp_service {	 
	my ($self,$port) = @_;
	my $service = "-1";
	foreach ( @{$self->{stem}{ports}}) { 
		if ( ($_->{portid} eq $port) && ($_->{protocol} eq "tcp" ) ) { $service = $_; }
	}
		
	my $SERVICE = NmapParser::Host::Service->new($service); 
	return $SERVICE; 
}

sub udp_service { 
	my ($self,$port) = @_;
	my $service = "-1";
	foreach ( @{$self->{stem}{ports}}) { 
		if ( ($_->{portid} eq $port) && ($_->{protocol} eq "udp" ) ) { $service = Service->new($_); }
	}
	return $service; 

}



sub mac_vendor { 
	my ($self) = @_;
	my  $macVendor = "-1";
	
	if ( ref($self->{stem}{address}) eq "ARRAY") {
		foreach (@{$self->{stem}{address}}) { if ( $_->{addrtype} eq "mac" ) { $macVendor = $_->{vendor}; } } 
	} elsif (ref($self->{stem}{address}) eq "hash") {
		if ( $self->{stem}{address}{addrtype} eq "mac" ) { $macVendor = $self->{stem}{address}{vendor}} 
	} 
	return $macVendor;
}

sub mac_addr { 
	my ($self) = @_;
	my  $MAC = getAddrValue($self,'mac'); 	
	return $MAC;	
}

sub ipv4_addr { 
	my ($self) = @_;
	my  $IPv4 = getAddrValue($self,'ipv4'); 	
	return $IPv4;
}

sub ipv6_addr { 
	my ($self) = @_;
	my  $IPv6 = getAddrValue($self,'ipv6'); 
	return $IPv6;
}

sub getAddrValue { 
	
	my ($self,$type) = @_;
	my  $returnValue = "-1"; 
	if ( ref($self->{stem}{address}) eq "ARRAY") {
		foreach (@{$self->{stem}{address}}) { if ( $_->{addrtype} eq $type ) { $returnValue = $_->{addr}; } } 
	} elsif (ref($self->{stem}{address}) eq "HASH") {
		if ( $self->{stem}{address}{addrtype} eq $type ) { $returnValue = $self->{stem}{address}{addr}} 
	} 
	return $returnValue;
}

#passed
sub tcp_port_count { 
	my ($self) = @_;
	my @ports = getPortdata($self,"tcp"); 
	return ($#ports + 1);	
}

#passed
sub udp_port_count { 
	my ($self) = @_;
	my @ports = getPortdata($self,"udp"); 
	return ($#ports + 1);		
}

#passed
sub tcp_ports { 
	my ($self,$state) = @_;
	my @ports = getPortdata($self,"tcp",$state); 
	return @ports;	
}

#passed
sub udp_ports {
	my ($self,$state) = @_;
	my @ports = getPortdata($self,"udp",$state); 
	return @ports;	
}

#passed
sub tcp_open_ports {
	my ($self,$state) = @_;
	my @ports = getPortdata($self,"tcp","open"); 
	return @ports;	 
}

#passed
sub udp_open_ports { 
	my ($self,$state) = @_;
	my @ports = getPortdata($self,"udp","open"); 
	return @ports;	 
}

#passed
sub tcp_filtered_ports { 
	my ($self,$state) = @_;
	my @ports = getPortdata($self,"tcp","filtered"); 
	return @ports;	 
}

#passed
sub udp_filtered_ports { 
	my ($self,$state) = @_;
	my @ports = getPortdata($self,"udp","filtered"); 
	return @ports;	
}

#passed
sub tcp_closed_ports {
	my ($self,$state) = @_;
	my @ports = getPortdata($self,"tcp","closed"); 
	return @ports;	 
	
}

#passed
sub udp_closed_ports {
	my ($self,$state) = @_;
	my @ports = getPortdata($self,"udp","closed"); 
	return @ports;	
}

sub getPortdata { 

	my ($self,$type,$state) = @_;
	my @ports; 
	
	if ( ref($self->{stem}{ports}) eq "ARRAY" ) { 
		foreach ( @{$self->{stem}{ports}}) { 
			if ( $_->{protocol} eq $type) {
				if (defined($state)) {
					if ( $_->{state}{state} eq $state) { 
						push(@ports,$_->{portid});
					} 
				} else { 
					push(@ports,$_->{portid});
				}  
				
			}
		}
	} 
#	else { 
#		die "no open ports error condition\n" 
#	}
	
	return @ports;	

}

#passed
sub status {
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{status}{state})) { $returnValue = $self->{stem}{status}{state}; } 
	return $returnValue;	
}

	 	 
sub addr { 
	my ($self) = @_;
	
	my $addrValue; 
	if ( ref($self->{stem}{address}) eq "HASH") { 
		$addrValue = $self->{stem}{address}{addr};
	} elsif ( ref($self->{stem}{address}) eq "ARRAY" ){
		foreach ( @{$self->{stem}{address}}) { 
			if ( $_->{addrtype} eq "ipv4") { 
				$addrValue = $_->{addr};
				last;  
			}
		} 
	} else {
		printf "ref: %s\n", ref($self->{stem}{address});  
		die "unknown type! \n"; 
	}
	
	return $addrValue;
	
}

#passed
sub addrtype {
	 
	my ($self,$address) = @_;
	my $addrValue; 
	if ( ref($self->{stem}{address}) eq "HASH") { 
		$addrValue = $self->{stem}{address}{addrtype};
	} elsif ( ref($self->{stem}{address}) eq "ARRAY" ){
		foreach ( @{$self->{stem}{address}}) {
			if ( $_->{addr} eq $address) { 
				$addrValue = $_->{addrtype};
			} 
		} 
	} else {
		printf "ref: %s\n", ref($self->{stem}{address});  
		die "unknown type! \n"; 
	}
	return $addrValue;	
}

sub distance {
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{distance}{value})) { $returnValue = $self->{stem}{distance}{value}; } 
	return $returnValue;		
}

#passed
sub ipidsequence_class {
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{ipidsequence}{class})) { $returnValue = $self->{stem}{ipidsequence}{class}; } 
	return $returnValue;	
}

#passed
sub ipidsequence_values { 
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{ipidsequence}{values})) { $returnValue = $self->{stem}{ipidsequence}{values}; } 
	return $returnValue;				
}

#passed
sub tcpsequence_values {
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{tcpsequence}{values})) { $returnValue = $self->{stem}{tcpsequence}{values}; } 
	return $returnValue;				
}

#passed	
sub tcpsequence_index { 
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{tcpsequence}{index})) { $returnValue = $self->{stem}{tcpsequence}{index}; } 
	return $returnValue;		
}

sub tcpsequence_difficulty { 	
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{tcpsequence}{difficulty})) { $returnValue = $self->{stem}{tcpsequence}{difficulty}; } 
	return $returnValue;		
}

#passed
sub tcptssequence_class {
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{tcptssequence}{class})) { $returnValue = $self->{stem}{tcptssequence}{class}; } 
	return $returnValue;		
}

#passed
sub tcptssequence_values {
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{tcptssequence}{values})) { $returnValue = $self->{stem}{tcptssequence}{values}; } 
	return $returnValue;		
}

sub starttime { 
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{starttime})) { $returnValue = $self->{stem}{starttime}; } 
	return $returnValue;	
}

sub endtime { 
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{endtime})) { $returnValue = $self->{stem}{endtime}; } 
	return $returnValue;	
}
		
sub latency { 
	my ($self) = @_;
	my $returnValue = "-1";
	if ( defined($self->{stem}{times}{srtt})) { $returnValue = $self->{stem}{times}{srtt}; } 
	return $returnValue;	
}
		
1;
