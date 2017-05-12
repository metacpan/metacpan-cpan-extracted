# v 0.1

package NmapParser::Host::Script; 
use base NmapParser::Host;

my @ISA = "Host";
  
use vars qw($AUTOLOAD);


sub new {
    my $pkg = shift;
    my $self = bless {}, $pkg;
    $self->initialize(@_);
    return $self;
}

sub initialize {
    my $self = shift;
    $self->SUPER::initialize(shift, shift);
    $self->{HOST} = shift;
}

sub all {
	
	my ($self) = @_;
	my @names;
	foreach ( @{$self->{stem}{osmatch}} ) { push(@names,$_->{name});}	
	return @names;		 

}

sub name { 

	my ($self,$port) = @_;
	my $returnValue = "unknown"; 
	if ( defined($self->{stem}{id}) ) { $returnValue = $self->{stem}{id}; }
	return $returnValue;
} 

sub elements { 

	my ($self,$port) = @_;
	my %returnValue; 
	if ( defined($self->{stem}{elem}) ) {
		foreach ( keys %{$self->{stem}{elem}} ) { $returnValue{$_} = $self->{stem}{elem}{$_};}
	}
	return \%returnValue;
}

sub output { 

	my ($self,$port) = @_;
	my $returnValue = "unknown"; 
	if ( defined($self->{stem}{output}) ) { $returnValue = $self->{stem}{output}; }
	return $returnValue;	
	
}

#<hostscript><script id="smb-os-discovery" output="&#xa;  OS: Windows Server 2003 3790 Service Pack 2 (Windows Server 2003 5.2)&#xa;  OS CPE: cpe:/o:microsoft:windows_server_2003::sp2&#xa;  Computer name: VHAMACDHCPSMC&#xa;  NetBIOS computer name: VHAMACDHCPSMC&#xa;  Domain name: v21.med.va.gov&#xa;  Forest name: va.gov&#xa;  FQDN: VHAMACDHCPSMC.v21.med.va.gov&#xa;  System time: 2014-06-13T11:35:23-07:00&#xa;"><elem key="os">Windows Server 2003 3790 Service Pack 2</elem>
#<elem key="lanmanager">Windows Server 2003 5.2</elem>
#<elem key="server">VHAMACDHCPSMC\x00</elem>
#<elem key="date">2014-06-13T11:35:23-07:00</elem>
#<elem key="fqdn">VHAMACDHCPSMC.v21.med.va.gov</elem>
#<elem key="domain_dns">v21.med.va.gov</elem>
#<elem key="forest_dns">va.gov</elem>
#<elem key="workgroup">VHA21\x00</elem>
#<elem key="cpe">cpe:/o:microsoft:windows_server_2003::sp2</elem>
#</script></hostscript>

#
# PORT 
#<script id="ssl-cert" output="Subject: commonName=R01MACHSM07.r01.med.va.gov/organizationName=VA/stateOrProvinceName=Mather/countryName=US/emailAddress=R01Storage@va.gov/localityName=California/organizationalUnitName=OI&amp;T&#xa;Issuer: commonName=R01MACHSM07.r01.med.va.gov/organizationName=VA/stateOrProvinceName=Mather/countryName=US/emailAddress=R01Storage@va.gov/localityName=California/organizationalUnitName=OI&amp;T&#xa;Public Key type: rsa&#xa;Public Key bits: 512&#xa;Not valid before: 2011-09-15T14:29:11+00:00&#xa;Not valid after:  2026-09-11T14:29:11+00:00&#xa;MD5:   a5da a1d4 c8ad 9ee7 cae5 801e 7eff 86c7&#xa;SHA-1: 4906 cf8a 058e 32de 8e45 8106 efe4 240f fbbe 18ac&#xa;-&#45;&#45;&#45;&#45;BEGIN CERTIFICATE-&#45;&#45;&#45;&#45;&#xa;MIICLzCCAdmgAwIBAgIBADANBgkqhkiG9w0BAQQFADCBljEjMCEGA1UEAxMaUjAx&#xa;TUFDSFNNMDcucjAxLm1lZC52YS5nb3YxCzAJBgNVBAYTAlVTMQ8wDQYDVQQIEwZN&#xa;YXRoZXIxEzARBgNVBAcTCkNhbGlmb3JuaWExCzAJBgNVBAoTAlZBMQ0wCwYDVQQL&#xa;FARPSSZUMSAwHgYJKoZIhvcNAQkBFhFSMDFTdG9yYWdlQHZhLmdvdjAeFw0xMTA5&#xa;MTUxNTI5MTFaFw0yNjA5MTExNTI5MTFaMIGWMSMwIQYDVQQDExpSMDFNQUNIU00w&#xa;Ny5yMDEubWVkLnZhLmdvdjELMAkGA1UEBhMCVVMxDzANBgNVBAgTBk1hdGhlcjET&#xa;MBEGA1UEBxMKQ2FsaWZvcm5pYTELMAkGA1UEChMCVkExDTALBgNVBAsUBE9JJlQx&#xa;IDAeBgkqhkiG9w0BCQEWEVIwMVN0b3JhZ2VAdmEuZ292MFwwDQYJKoZIhvcNAQEB&#xa;BQADSwAwSAJBALgoLtWAugxd42ApqIOhEG5Q3EOcwmOXHy3CFrUO9UmFtmVds9qn&#xa;yTUOduxl2wnBD+llNmKKLV6PyAzOTD4k3BcCAwEAAaMQMA4wDAYDVR0TBAUwAwEB&#xa;/zANBgkqhkiG9w0BAQQFAANBAGxpDoAFDW7HtPqVhpLeMwMoQgKlOfCFlKb6XSoD&#xa;cEluWvW+UIbl4SjQivYPDzt0gYXwy6dieI53/9uiSdfXKwM=&#xa;-&#45;&#45;&#45;&#45;END CERTIFICATE-&#45;&#45;&#45;&#45;&#xa;"><table key="subject">
#<elem key="emailAddress">R01Storage@va.gov</elem>
#<elem key="countryName">US</elem>
#<elem key="stateOrProvinceName">Mather</elem>
#<elem key="localityName">California</elem>
#<elem key="commonName">R01MACHSM07.r01.med.va.gov</elem>
#<elem key="organizationName">VA</elem>
#<elem key="organizationalUnitName">OI&amp;T</elem>
#</table>
#<table key="issuer">
#<elem key="emailAddress">R01Storage@va.gov</elem>
#<elem key="countryName">US</elem>
#<elem key="stateOrProvinceName">Mather</elem>
#<elem key="localityName">California</elem>
#<elem key="commonName">R01MACHSM07.r01.med.va.gov</elem>
#<elem key="organizationName">VA</elem>
#<elem key="organizationalUnitName">OI&amp;T</elem>
#</table>
#<table key="pubkey">
#<elem key="type">rsa</elem>
#<elem key="bits">512</elem>
#</table>
#<table key="validity">
#<elem key="notAfter">2026-09-11T14:29:11+00:00</elem>
#<elem key="notBefore">2011-09-15T14:29:11+00:00</elem>
#</table>
#<elem key="md5">a5daa1d4c8ad9ee7cae5801e7eff86c7</elem>
#<elem key="sha1">4906cf8a058e32de8e458106efe4240ffbbe18ac</elem>
#<elem key="pem">-&#45;&#45;&#45;&#45;BEGIN CERTIFICATE-&#45;&#45;&#45;&#45;&#xa;MIICLzCCAdmgAwIBAgIBADANBgkqhkiG9w0BAQQFADCBljEjMCEGA1UEAxMaUjAx&#xa;TUFDSFNNMDcucjAxLm1lZC52YS5nb3YxCzAJBgNVBAYTAlVTMQ8wDQYDVQQIEwZN&#xa;YXRoZXIxEzARBgNVBAcTCkNhbGlmb3JuaWExCzAJBgNVBAoTAlZBMQ0wCwYDVQQL&#xa;FARPSSZUMSAwHgYJKoZIhvcNAQkBFhFSMDFTdG9yYWdlQHZhLmdvdjAeFw0xMTA5&#xa;MTUxNTI5MTFaFw0yNjA5MTExNTI5MTFaMIGWMSMwIQYDVQQDExpSMDFNQUNIU00w&#xa;Ny5yMDEubWVkLnZhLmdvdjELMAkGA1UEBhMCVVMxDzANBgNVBAgTBk1hdGhlcjET&#xa;MBEGA1UEBxMKQ2FsaWZvcm5pYTELMAkGA1UEChMCVkExDTALBgNVBAsUBE9JJlQx&#xa;IDAeBgkqhkiG9w0BCQEWEVIwMVN0b3JhZ2VAdmEuZ292MFwwDQYJKoZIhvcNAQEB&#xa;BQADSwAwSAJBALgoLtWAugxd42ApqIOhEG5Q3EOcwmOXHy3CFrUO9UmFtmVds9qn&#xa;yTUOduxl2wnBD+llNmKKLV6PyAzOTD4k3BcCAwEAAaMQMA4wDAYDVR0TBAUwAwEB&#xa;/zANBgkqhkiG9w0BAQQFAANBAGxpDoAFDW7HtPqVhpLeMwMoQgKlOfCFlKb6XSoD&#xa;cEluWvW+UIbl4SjQivYPDzt0gYXwy6dieI53/9uiSdfXKwM=&#xa;-&#45;&#45;&#45;&#45;END CERTIFICATE-&#45;&#45;&#45;&#45;&#xa;</elem>
#</script></port>