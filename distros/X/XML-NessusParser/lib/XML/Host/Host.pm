#
#
# 

package NessusParser::Host; 

use strict;
use warnings;

use base "NessusParser";

my @ISA = "NessusParser";
  
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

sub get_ip {
	my ($self,$ip) = shift;
	my $returnValue = "-1";
	if ( $ip eq $self->{stem}{HostProperties}{'host-ip'}) { 
		if ( defined($self->{stem}{HostProperties}{'host-ip'})) { 
			$returnValue = $self->{stem}{HostProperties}{'host-ip'}; 
		}		
	}
	 
	return $returnValue;		
}

sub get_credentialed {
	my ($self,$ip) = shift;
	my $returnValue = "-1";
	if ( $ip eq $self->{stem}{HostProperties}{'host-ip'}) { 
		if ( defined($self->{stem}{HostProperties}{'Credentialed_Scan'})) { 
			$returnValue = $self->{stem}{HostProperties}{'Credentialed_Scan'}; 
		}
	} 
	
	 
	return $returnValue;
}

sub get_policy {
	my ($self,$ip) = shift;
	my $returnValue = "-1";
	if ( $ip eq $self->{stem}{HostProperties}{'host-ip'}) { 
		if ( defined($self->{stem}{HostProperties}{'policy-used'})) { 
			$returnValue = $self->{stem}{HostProperties}{'policy-used'}; 
		}
	}
	 
	return $returnValue;
}

sub get_HostStart {
	my ($self) = shift;
	my $returnValue = "-1";
	
	if ( defined($self->{stem}{'HostProperties'}{'HOST_START'})) { 
		$returnValue = $self->{stem}{'HOST_START'}; 
	}
	 
	return $returnValue;
}

sub get_HostEnd {
	my ($self,$ip) = shift;
	my $returnValue = "-1";
	if ( $ip eq $self->{stem}{HostProperties}{'host-ip'}) { 
		if ( defined($self->{stem}{'HostProperties'}{'HOST_END'})) { 
			$returnValue = $self->{stem}{HostProperties}{'HOST_END'}; 
		}
	}
	 
	return $returnValue;
}

sub get_lastAuthScan {
	my ($self,$ip) = shift;
	my $returnValue = "-1";
	if ( $ip eq $self->{stem}{HostProperties}{'host-ip'}) {
		if ( defined($self->{stem}{'HostProperties'}{LastUnauthenticatedResults})) { 
			$returnValue = $self->{stem}{HostProperties}{LastUnauthenticatedResults}; 
		}
	} 
	return $returnValue;
}


#hostname
#Credentialed_Scan
#policy-used
#patch-summary-total-cves
#os
#host-fqdn
#smb-login-used
#local-checks-proto
#netbios-name
#system-type
#operating-system
#mac-address
#mcafee-epo-guid
#bios-uuid
#
#
#traceroute-hop-0


sub get_cpe { 
	
	
	
}
#<tag name="cpe-8">cpe:/a:oracle:jre:1.8.0:update51</tag>
#<tag name="cpe-7">cpe:/a:mozilla:firefox:39.0.0</tag>
#<tag name="cpe-6">cpe:/a:microsoft:ie:11.0.9600.17914</tag>
#<tag name="cpe-5">cpe:/a:adobe:flash_player:18.0.0.209</tag>
#<tag name="cpe-4">cpe:/a:adobe:flash_player:18.0.0.209</tag>
#<tag name="cpe-3">cpe:/a:adobe:acrobat:11.0.12</tag>
#<tag name="cpe-2">cpe:/a:adobe:acrobat_reader:11.0.12</tag>
#<tag name="cpe-1">cpe:/a:wireshark:wireshark:1.12.6</tag>
#<tag name="cpe-0">cpe:/o:microsoft:windows_7::sp1:x64-enterprise</tag>
#<tag name="cpe">cpe:/o:microsoft:windows</tag>
#





sub get_plugins {
	 
	my ($self,$ip) = @_;
	my @PLUGINS;
	if ( $ip eq $self->{stem}{HostProperties}{'host-ip'}) {
		if ( defined($self->{stem}{ReportItems}) ) {
			if ( ref($self->{stem}{ReportItems}) eq "ARRAY" ) {
				for my $plugin ( @{$self->{stem}{ReportItems}} ) { 
					my $PLUGIN = NessusParser::Host::Plugins->new($plugin); 
					push(@PLUGINS, $PLUGIN)
				}
			} elsif ( ref($self->{stem}{ReportItems}) eq "HASH" ) {
				my $PLUGIN = NessusParser::Host::Plugins->new($self->{stem}{ReportItems}); 
				push(@PLUGINS, $PLUGIN)
			} else { die "ack!!!\n"; }
		}
	} 
	 
	return @PLUGINS;
}
sub get_hostname { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'hostname'})) {
		$returnValue = $self->{stem}{HostProperties}{'hostname'};
	}
	return $returnValue;	
}

sub get_Credentialed_Scan { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'Credentialed_Scan'})) {
		$returnValue = $self->{stem}{HostProperties}{'Credentialed_Scan'};
	}
	return $returnValue;	
}

sub get_policy_used { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'policy-used'})) {
		$returnValue = $self->{stem}{HostProperties}{'policy-used'};
	}
	return $returnValue;	
}

sub get_patch_summary_total_cves { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'patch-summary-total-cves'})) {
		$returnValue = $self->{stem}{HostProperties}{'patch-summary-total-cves'};
	}
	return $returnValue;	
}

sub get_os { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'os'})) {
		$returnValue = $self->{stem}{HostProperties}{'os'};
	}
	return $returnValue;	
}

sub get_host_fqdn { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'host-fqdn'})) {
		$returnValue = $self->{stem}{HostProperties}{'host-fqdn'};
	}
	return $returnValue;	
}

sub get_smb_login_used { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'smb-login-used'})) {
		$returnValue = $self->{stem}{HostProperties}{'smb-login-used'};
	}
	return $returnValue;	
}

sub get_local_checks_proto { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'local-checks-proto'})) {
		$returnValue = $self->{stem}{HostProperties}{'local-checks-proto'};
	}
	return $returnValue;	
}

sub get_netbios_name { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'netbios-name'})) {
		$returnValue = $self->{stem}{HostProperties}{'netbios-name'};
	}
	return $returnValue;	
}

sub get_system_type { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'system-type'})) {
		$returnValue = $self->{stem}{HostProperties}{'system-type'};
	}
	return $returnValue;	
}

sub get_operating_system { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'operating-system'})) {
		$returnValue = $self->{stem}{HostProperties}{'operating-system'};
	}
	return $returnValue;	
}

sub get_mac_address { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'mac-address'})) {
		$returnValue = $self->{stem}{HostProperties}{'mac-address'};
	}
	return $returnValue;	
}

sub get_mcafee_epo_guid { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'mcafee-epo-guid'})) {
		$returnValue = $self->{stem}{HostProperties}{'mcafee-epo-guid'};
	}
	return $returnValue;	
}

sub get_bios_uuid { 
	my ($self,$name) = shift;
	my $returnValue = -1;
	if ( defined($self->{stem}{'HostProperties'}{'bios-uuid'})) {
		$returnValue = $self->{stem}{HostProperties}{'bios-uuid'};
	}
	return $returnValue;	
}

