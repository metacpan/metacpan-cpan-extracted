#
# 

package NessusParser::Host::Plugins; 
use base NessusParser::Host;
my @ISA = "Host";  
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

#sub get_ { 
#	my ($self,$name) = shift;
#	my $returnValue = "-1";
#	
#	if ( defined($self->{stem}{'HostProperties'}{'HOST_END'})) { 
#		$returnValue = $self->{stem}{HostProperties}{'HOST_END'}; 
#	}
#	
#	return $returnValue;	
#}

sub get_ics_alert { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'ics-alert'})) {
		$returnValue = $self->{stem}->{'ics-alert'};
	}
	return $returnValue;
}


sub get_cvss_base_score { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cvss_base_score'})) {
		$returnValue = $self->{stem}->{'cvss_base_score'};
	}
	return $returnValue;
}
sub get_cvss_temporal_score { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cvss_temporal_score'})) {
		$returnValue = $self->{stem}->{'cvss_temporal_score'};
	}
	return $returnValue;
}
sub get_cvss_temporal_vector { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cvss_temporal_vector'})) {
		$returnValue = $self->{stem}->{'cvss_temporal_vector'};
	}
	return $returnValue;
}
sub get_cvss_vector { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cvss_vector'})) {
		$returnValue = $self->{stem}->{'cvss_vector'};
	}
	return $returnValue;
}
sub get_description { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'description'})) {
		$returnValue = $self->{stem}->{'description'};
	}
	return $returnValue;
}
sub get_exploitability_ease { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'exploitability_ease'})) {
		$returnValue = $self->{stem}->{'exploitability_ease'};
	}
	return $returnValue;
}
sub get_exploit_available { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'exploit_available'})) {
		$returnValue = $self->{stem}->{'exploit_available'};
	}
	return $returnValue;
}
sub get_exploit_framework_canvas { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'exploit_framework_canvas'})) {
		$returnValue = $self->{stem}->{'exploit_framework_canvas'};
	}
	return $returnValue;
}
sub get_exploit_framework_core { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'exploit_framework_core'})) {
		$returnValue = $self->{stem}->{'exploit_framework_core'};
	}
	return $returnValue;
}
sub get_exploit_framework_exploithub { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'exploit_framework_exploithub'})) {
		$returnValue = $self->{stem}->{'exploit_framework_exploithub'};
	}
	return $returnValue;
}
sub get_exploit_framework_metasploit { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'exploit_framework_metasploit'})) {
		$returnValue = $self->{stem}->{'exploit_framework_metasploit'};
	}
	return $returnValue;
}
sub get_exploithub_sku { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'exploithub_sku'})) {
		$returnValue = $self->{stem}->{'exploithub_sku'};
	}
	return $returnValue;
}
sub get_fname { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'fname'})) {
		$returnValue = $self->{stem}->{'fname'};
	}
	return $returnValue;
}
sub get_iavt { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'iavt'})) {
		$returnValue = $self->{stem}->{'iavt'};
	}
	return $returnValue;
}


sub get_metasploit_name { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'metasploit_name'})) {
		$returnValue = $self->{stem}->{'metasploit_name'};
	}
	return $returnValue;
}
sub get_msft { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'msft'})) {
		$returnValue = $self->{stem}->{'msft'};
	}
	return $returnValue;
}
sub get_osvdb { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'osvdb'})) {
		$returnValue = $self->{stem}->{'osvdb'};
	}
	return $returnValue;
}
sub get_patch_publication_date { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'patch_publication_date'})) {
		$returnValue = $self->{stem}->{'patch_publication_date'};
	}
	return $returnValue;
}
sub get_plugin_modification_date { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'plugin_modification_date'})) {
		$returnValue = $self->{stem}->{'plugin_modification_date'};
	}
	return $returnValue;
}
sub get_plugin_output { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'plugin_output'})) {
		$returnValue = $self->{stem}->{'plugin_output'};
	}
	return $returnValue;
}

sub get_plugin_publication_date { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'plugin_publication_date'})) {
		$returnValue = $self->{stem}->{'plugin_publication_date'};
	}
	return $returnValue;
}
sub get_plugin_type { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'plugin_type'})) {
		$returnValue = $self->{stem}->{'plugin_type'};
	}
	return $returnValue;
}
sub get_plugin_version { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'plugin_version'})) {
		$returnValue = $self->{stem}->{'plugin_version'};
	}
	return $returnValue;
}
sub get_risk_factor { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'risk_factor'})) {
		$returnValue = $self->{stem}->{'risk_factor'};
	}
	return $returnValue;
}
sub get_secunia { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'secunia'})) {
		$returnValue = $self->{stem}->{'secunia'};
	}
	return $returnValue;
}
sub get_see_also { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'see_also'})) {
		$returnValue = $self->{stem}->{'see_also'};
	}
	return $returnValue;
}
sub get_severity { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'severity'})) {
		$returnValue = $self->{stem}->{'severity'};
	}
	return $returnValue;
}
sub get_solution { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'solution'})) {
		$returnValue = $self->{stem}->{'solution'};
	}
	return $returnValue;
}
sub get_stig_severity { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'stig_severity'})) {
		$returnValue = $self->{stem}->{'stig_severity'};
	}
	return $returnValue;
}
sub get_synopsis { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'synopsis'})) {
		$returnValue = $self->{stem}->{'synopsis'};
	}
	return $returnValue;
}
sub get_vuln_publication_date { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'vuln_publication_date'})) {
		$returnValue = $self->{stem}->{'vuln_publication_date'};
	}
	return $returnValue;
}
sub get_xref { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'xref'})) {
		$returnValue = $self->{stem}->{'xref'};
	}
	return $returnValue;
}
sub get_script_version { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'script_version'})) {
		$returnValue = $self->{stem}->{'script_version'};
	}
	return $returnValue;
}
sub get_apple_sa { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'apple-sa'})) {
		$returnValue = $self->{stem}->{'apple-sa'};
	}
	return $returnValue;
}
sub get_canvas_package { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'canvas_package'})) {
		$returnValue = $self->{stem}->{'canvas_package'};
	}
	return $returnValue;
}
sub get_exploited_by_malware { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'exploited_by_malware'})) {
		$returnValue = $self->{stem}->{'exploited_by_malware'};
	}
	return $returnValue;
}
sub get_icsa { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'icsa'})) {
		$returnValue = $self->{stem}->{'icsa'};
	}
	return $returnValue;
}
sub get_plugin_name { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'plugin_name'})) {
		$returnValue = $self->{stem}->{'plugin_name'};
	}
	return $returnValue;
}
sub get_attachment { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'attachment'})) {
		$returnValue = $self->{stem}->{'attachment'};
	}
	return $returnValue;
}
sub get_d2_elliot_name { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'d2_elliot_name'})) {
		$returnValue = $self->{stem}->{'d2_elliot_name'};
	}
	return $returnValue;
}
sub get_exploit_framework_d2_elliot { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'exploit_framework_d2_elliot'})) {
		$returnValue = $self->{stem}->{'exploit_framework_d2_elliot'};
	}
	return $returnValue;
}
sub get_cert_cc { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cert-cc'})) {
		$returnValue = $self->{stem}->{'cert-cc'};
	}
	return $returnValue;
}
sub get_hp { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'hp'})) {
		$returnValue = $self->{stem}->{'hp'};
	}
	return $returnValue;
}
sub get_vmsa { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'vmsa'})) {
		$returnValue = $self->{stem}->{'vmsa'};
	}
	return $returnValue;
}
sub get_glsa { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'glsa'})) {
		$returnValue = $self->{stem}->{'glsa'};
	}
	return $returnValue;
}
sub get_msvr { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'msvr'})) {
		$returnValue = $self->{stem}->{'msvr'};
	}
	return $returnValue;
}
sub get_cisco_bug_id { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cisco-bug-id'})) {
		$returnValue = $self->{stem}->{'cisco-bug-id'};
	}
	return $returnValue;
}
sub get_cisco_sa { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cisco-sa'})) {
		$returnValue = $self->{stem}->{'cisco-sa'};
	}
	return $returnValue;
}
sub get_rhsa { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'rhsa'})) {
		$returnValue = $self->{stem}->{'rhsa'};
	}
	return $returnValue;
}
sub get_suse { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'suse'})) {
		$returnValue = $self->{stem}->{'suse'};
	}
	return $returnValue;
}
sub get_cpe { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cpe'})) {
		$returnValue = $self->{stem}->{'cpe'};
	}
	return $returnValue;
}
sub get_owasp { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'owasp'})) {
		$returnValue = $self->{stem}->{'owasp'};
	}
	return $returnValue;
}
sub get_cisco_sr { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cisco-sr'})) {
		$returnValue = $self->{stem}->{'cisco-sr'};
	}
	return $returnValue;
}
sub get_bid { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'bid'})) {
		$returnValue = $self->{stem}->{'bid'};
	}
	return $returnValue;
}
sub get_cert { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cert'})) {
		$returnValue = $self->{stem}->{'cert'};
	}
	return $returnValue;
}
sub get_cwe { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cwe'})) {
		$returnValue = $self->{stem}->{'cwe'};
	}
	return $returnValue;
}
sub get_edb_id { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'edb-id'})) {
		$returnValue = $self->{stem}->{'edb-id'};
	}
	return $returnValue;
}
sub get_cve { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cve'})) {
		$returnValue = $self->{stem}->{'cve'};
	}
	return $returnValue;
}
sub get_iava { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'iava'})) {
		$returnValue = $self->{stem}->{'iava'};
	}
	return $returnValue;
}
sub get_iavb { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'iavb'})) {
		$returnValue = $self->{stem}->{'iavb'};
	}
	return $returnValue;
}
sub get_nid { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'nid'})) {
		$returnValue = $self->{stem}->{'nid'};
	}
	return $returnValue;
}
sub get_dsa { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'dsa'})) {
		$returnValue = $self->{stem}->{'dsa'};
	}
	return $returnValue;
}
sub get_always_run { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'always_run'})) {
		$returnValue = $self->{stem}->{'always_run'};
	}
	return $returnValue;
}
sub get_freebsd { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'freebsd'})) {
		$returnValue = $self->{stem}->{'freebsd'};
	}
	return $returnValue;
}
sub get_patch_modification_date { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'patch_modification_date'})) {
		$returnValue = $self->{stem}->{'patch_modification_date'};
	}
	return $returnValue;
}
sub get_cm_compliance_actual_value { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-actual-value'})) {
		$returnValue = $self->{stem}->{'cm:compliance-actual-value'};
	}
	return $returnValue;
}
sub get_cm_compliance_audit_file { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-audit-file'})) {
		$returnValue = $self->{stem}->{'cm:compliance-audit-file'};
	}
	return $returnValue;
}
sub get_cm_compliance_check_id { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-check-id'})) {
		$returnValue = $self->{stem}->{'cm:compliance-check-id'};
	}
	return $returnValue;
}
sub get_cm_compliance_check_name { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-check-name'})) {
		$returnValue = $self->{stem}->{'cm:compliance-check-name'};
	}
	return $returnValue;
}
sub get_cm_compliance_info { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-info'})) {
		$returnValue = $self->{stem}->{'cm:compliance-info'};
	}
	return $returnValue;
}
sub get_cm_compliance_policy_value { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-policy-value'})) {
		$returnValue = $self->{stem}->{'cm:compliance-policy-value'};
	}
	return $returnValue;
}
sub get_cm_compliance_result { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-result'})) {
		$returnValue = $self->{stem}->{'cm:compliance-result'};
	}
	return $returnValue;
}
sub get_compliance { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'compliance'})) {
		$returnValue = $self->{stem}->{'compliance'};
	}
	return $returnValue;
}
sub get_cm_compliance_output { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-output'})) {
		$returnValue = $self->{stem}->{'cm:compliance-output'};
	}
	return $returnValue;
}
sub get_cm_compliance_file { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-file'})) {
		$returnValue = $self->{stem}->{'cm:compliance-file'};
	}
	return $returnValue;
}
sub get_cm_compliance_see_also { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-see-also'})) {
		$returnValue = $self->{stem}->{'cm:compliance-see-also'};
	}
	return $returnValue;
}
sub get_cm_compliance_solution { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'cm:compliance-solution'})) {
		$returnValue = $self->{stem}->{'cm:compliance-solution'};
	}
	return $returnValue;
}
sub get_potential_vulnerability { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'potential_vulnerability'})) {
		$returnValue = $self->{stem}->{'potential_vulnerability'};
	}
	return $returnValue;
}
sub get_agent { 
	my ($self) = @_;
	my $returnValue = -1;
	if ( defined($self->{stem}->{'agent'})) {
		$returnValue = $self->{stem}->{'agent'};
	}
	return $returnValue;
}


sub get_pluginName { 
        my ($self) = @_;
        my $returnValue = -1;
        if ( defined($self->{stem}->{'pluginName'})) {
                $returnValue = $self->{stem}->{'pluginName'};
        }
        return $returnValue;
}
sub get_pluginID { 
        my ($self) = @_;
        my $returnValue = -1;
        if ( defined($self->{stem}->{'pluginID'})) {
                $returnValue = $self->{stem}->{'pluginID'};
        }
        return $returnValue;
}
sub get_svc_name { 
        my ($self) = @_;
        my $returnValue = -1;
        if ( defined($self->{stem}->{'svc_name'})) {
                $returnValue = $self->{stem}->{'svc_name'};
        }
        return $returnValue;
}
sub get_port { 
        my ($self) = @_;
        my $returnValue = -1;
        if ( defined($self->{stem}->{'port'})) {
                $returnValue = $self->{stem}->{'port'};
        }
        return $returnValue;
}
sub get_protocol { 
        my ($self) = @_;
        my $returnValue = -1;
        if ( defined($self->{stem}->{'protocol'})) {
                $returnValue = $self->{stem}->{'protocol'};
        }
        return $returnValue;
}
sub get_pluginFamily { 
        my ($self) = @_;
        my $returnValue = -1;
        if ( defined($self->{stem}->{'pluginFamily'})) {
                $returnValue = $self->{stem}->{'pluginFamily'};
        }
        return $returnValue;
}
sub get_severity { 
        my ($self) = @_;
        my $returnValue = -1;
        if ( defined($self->{stem}->{'severity'})) {
                $returnValue = $self->{stem}->{'severity'};
        }
        return $returnValue;
}


