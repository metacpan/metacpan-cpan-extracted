package XML::IODEF::PhraudReport;
use base qw(XML::IODEF);

use strict;
use warnings;

our $VERSION = '0.01';

# If you're reading the source, this is a VERY rough first cut, please feel free to send me any bugs to improve this.
# Based on the examples I have available it does most things according to the RFC, but should be TESTED before being put into production
# This code SHOULD BE CONSIDERED ALPHA CODE until this warning is removed******** YOU HAVE BEEN WARNED! :-)

use constant ANY	=> "ANY";
use constant PCDATA	=> "PCDATA";
use constant EMPTY	=> "EMPTY";

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = XML::IODEF->new(@_);
	bless($self,$class);
	
	my $ext_dtd = {
		"AdditionalData" => {
			ATTRIBUTES  	=> {  	
				"restriction"	=> ["public", "need-to-know", "private", "default"], 
				"type"			=> ["string", "boolean", "byte", "character", "date-time",
									"integer", "ntpstamp", "portlist", "real", "xml"],
			 	"meaning"		=> [],
		  	},
			CONTENT     	=> ANY,
			CHILDREN	=> [ "?PhraudReport" ],
		},
		"PhraudReport"	=> {
			ATTRIBUTES	=> {
				"Version" 	=> ["string"],
				"FraudType"	=> [ "phishemail", "recruitemail", "malwareemail", "fraudsite", "dnsspoof",
								 "keylogger", "ole", "im", "cve", "archive" ],
			},
			CHILDREN	=> [ "?PhishNameRef", "?PhishNameLocalRef", "?FraudParameter", "*FraudedBrandName",
							 "+LureSource", "+OriginatingSensor", "?EmailRecord", "*DCSite", "*TakeDownInfo",
							 "*ArchivedData", "*RelatedData", "*CorrelatedData", "?PRComments" ],
		},
		"FraudParameter" => {
			ATTRIBUTES	=> { "type" => ["MLStringType"], },
			CONTENT		=> PCDATA,
		},
		"PhishNameRef"	=> {
			ATTRIBUTES	=> { "type" => ["string"] },
			CONTENT		=> PCDATA,
		},	
		"PhishNameLocalRef" => {
			ATTRIBUTES	=> { "type" => ["string"] },
			CONTENT		=> PCDATA,
		},
		"FraudedBrandName" => {
			ATTRIBUTES	=> { "type" => ["string"] },
			CONTENT		=> PCDATA,
		},
		"LureSource" => {
			CHILDREN	=> ["+System", "*DomainData", "?IncludedMalware", "?FilesDownloaded", "?RegistryKeysModified"],
		},
		"OriginatingSensor" => {
			ATTRIBUTES	=> { "OriginatingSensorType"	=> ["Web", "WebGateway", "MailGateway", "Browser", "ISPsensor",
															"Human", "Honeypot", "Other"],
			},
			CHILDREN	=> ["1DateFirstSeen", "+System"],
		},
		"EmailRecord"	=> {
			CHILDREN	=> ["1EmailCount", "?Email", "?Message", "?ARPText", "?EmailComments"],
		},
		"DCSite"		=> {
			ATTRIBUTES	=> { "DCSite"	=> ["web", "email", "keylogger", "automation", "unspecified"] },
			CHILDREN	=> ["?SiteURL", "?Domain", "?EmailSite","?System","?Unknown","?DomainData", "?Assessment"],
			
		},
		"TakeDownInfo"	=> {
			CHILDREN	=> ["?TakeDownDate", "*TakeDownAgency", "*TakeDownComments"],
		},
		"ArchivedData"	=> {
			ATTRIBUTES	=> { "type" => ["collectionsite", "basecamp", "sendersite", "credentialInfo", "unspecified"] },
			CHILDREN	=> ["?ArchivedDataURL", "?ArchivedDataComments", "?ArchivedData"],
		},
		"RelatedData"	=> { CONTENT	=> PCDATA }, 
		"CorrelatedData" => { CONTENT	=> PCDATA },
		"PRComments"	=> { CONTENT	=> PCDATA },
		
		# LureSource
		"DomainData" => {
			ATTRIBUTES	=> {
				"SystemStatus"	=> ["spoofed", "fradulent", "innocent-hakced", "innocent-hijacked", "unknown"],
				"DomainStatus" 	=> ["reservedDelegation", "assignedAndActive", "assignedAndInactive", "assignedAndOnHold",
				"revoked", "transferPending", "registryLock", "registrarLock"],
			},
			CHILDREN	=> ["1Name", "?DateDomainWasChecked", "?RegistrationDate", "?ExpirationDate", "*Nameservers", 
			"*DNSRecord", "*DomainContacts"],
		},
		
		# IncludedMalware
		"IncludedMalware"	=> {
			CHILDREN	=> [ "+Name", "?Hashvalue", "?Data" ],
		},
		"FilesDownloaded"	=> { CONTENT => PCDATA },
		"RegistryKeysModified"	=> {
			CHILDREN	=> ["+Key"],
		},
		
		# DomainData
		"Server"	=> {
			ATTRIBUTES	=> { "type" => ["MLString"] },
			CONTENT		=> PCDATA,
		},
		
		"DateDomainWasChecked" => {
			ATTRIBUTES	=> { "type" => ["date-time"] },
			CONTENT		=> PCDATA,
		},
		"RegistrationDate" => {
			ATTRIBUTES	=> { "type" => ["date-time"] },
			CONTENT		=> PCDATA,
		},
		"ExpirationDate" => {
			ATTRIBUTES	=> { "type" => ["date-time"] },
			CONTENT		=> PCDATA,
		},
		"Nameservers" => {
			CHILDREN	=> ["?Server", "+Address"],
		},
		"DNSRecord" => {
			CHILDREN	=> ["1owner", "1type", "?class", "?ttl", "1rdata"],
		},
		"DomainContacts" => {
			CHILDREN	=> ["?SameDomainContact", "+DomainContact"],
		},
		"SameDomainContact" => {
			ATTRIBUTES	=> { "type" => ["DNSNAME"] },
			CONTENT		=> PCDATA,
		},
		"DomainContact" => {
			ATTRIBUTES => { "restriction"	=> [ "public", "need-to-know", "private", "default" ],
				"Role"			=> [ "registrant", "registrar", "billing", "technical", "administrative", 
				"legal", "zone", "abuse", "security", "domainOwner", 
				"ipAddressOwner", "hostingProvider", "other" ],
				"Confidence"	=> [ "known-fradulent", "looks-fradulent", "known-real", "looks-real", "unknown" ],
				"type"			=> [ "person", "organization" ],
			},
			CHILDREN   => [ "?name", "*Description", "*RegistryHandle", "?PostalAddress",
			"*Email", "*Telephone", "?Fax", "?Timezone", "*Contact" ],
		},
		
		# IncludedMalware
		"Hashvalue"		=> {
			ATTRIBUTES	=> { "Algorithm" => ["SHA1"] },
			CONTENT		=> PCDATA,
		},
		"Data"	=> {
			ATTRIBUTES	=> { "XORPattern" => [] },
			CHILDREN	=> [ "?StringData", "?BinaryData" ],
		},
		
		# RegistryKeysModified
		"Key"	=> {
			CHILDREN	=> ["?Name", "?Value"], # FIXME?
		},
		
		# DNSRecord
		"owner"	=> { ATTRIBUTES	=> { "type" => ["string"] }, CONTENT	=> PCDATA },
		"type"	=> { CONTENTS	=> PCDATA },
		"class"	=> { CONTENTS	=> PCDATA },
		"ttl"	=> { ATTRIBUTES => { "type" => ["integer"] }, CONTENT	=> PCDATA },
		"rdata"	=> { CONTENT	=> PCDATA },
		
		# IncludedMalwareData
		"StringData"	=> { CONTENT	=> PCDATA },
		"BinaryData"	=> { CONTENT	=> ANY },
		
		# OriginalSensor
		"DateFirstSeen"	=> {
			ATTRIBUTES	=> { "type" => ["date-time"] },
			CONTENT		=> PCDATA,
		},
		
		## EmailRecord
		"EmailCount"	=> {
			ATTRIBUTES	=> { "type"	=> ["integer"], },
			CONTENT		=> PCDATA,			
		},
		"Email"			=> {
			CHILDREN	=> ["1EmailHeader", "?EmailBody"],
		},
		"Message"		=> {
			ATTRIBUTES	=> { "type" => ["MLStringType"]},
			CONTENT		=> PCDATA,
		},
		"ARPText"		=> {
			ATTRIBUTES	=> { "type" => ["string"] },
			CONTENT		=> PCDATA,
		},
		"EmailComments"	=> {
			ATTRIBUTES	=> { "type" => ["string"] },
			CONTENT		=> PCDATA,
		},
		
		## Email
		"EmailHeader"	=> {
			ATTRIBUTES	=> { "type" => ["string"] },
			CHILDREN	=> ["+Header"],
		},
		"EmailBody"		=> {
			ATTRIBUTES	=> { "type" => ["MLStringType"] },
			CONTENT		=> PCDATA,
		},
		
		## EmailHeader
		"Header"		=> {
			ATTRIBUTES	=> { "type" => ["MLStringType"] },
			CONTENT		=> PCDATA,
		},
		
		## DCSite
		"SiteURL"	=> { CONTENT	=> PCDATA	},
		"Domain"	=> { CONTENT	=> PCDATA	},
		"EmailSite"	=> { CONTENT	=> PCDATA	},
		"Unknown"	=> { CONTENT	=> PCDATA	},
		
		## TakeDownInfo
		"TakeDownDate"		=> { ATTRIBUTES	=> { "type" => ["date-time"] }, CONTENT => PCDATA },
		"TakeDownAgency"	=> { CONTENT	=> PCDATA },
		"TakeDownComments"	=> { CONTENT	=> PCDATA },
		
		## ArchivedData
		"ArchivedDataURL"		=> { CONTENT	=> PCDATA },
		"ArchivedDataComments"	=> { CONTENT	=> PCDATA },
		"ArchivedData"			=> { CONTENT	=> PCDATA },
		
		#
		# Simple Elements with no attributes
		#
		"Name"	=> { CONTENT => PCDATA },
		"Value"	=> { CONTENT => PCDATA },
	};
	XML::IODEF::extend_dtd($ext_dtd,'IODEF-Document');
	return($self);
}

1;

__END__

=head1 NAME

XML::IODEF::PhraudReport - Perl extension for Extending XML::IODEF to use with Phishing Extensions

=head1 SYNOPSIS

 use XML::IODEF::PhraudReport;
 my $report = XML::IODEF::PhraudReport->new();
 my $root = 'IncidentIncidentDataEventDataAddionalDataPhraudReport';
 $report->add($root.'FraudType','phishingemail');
 $report->out();
 
 see the 'examples' dir for more examples, XML::IODEF for more doc

=head1 DESCRIPTION

This is the July 30, 2008 implementation of:
 
 Extensions to the IODEF-Document Class for Reporting Phishing, Fraud, and Other Crimeware. 
 
=head2 EXPORT

None by default.

=head1 SEE ALSO

 XML::IODEF
 
 http://www.ietf.org/internet-drafts/draft-cain-post-inch-phishingextns-05.txt

=head1 AUTHOR

claimid.com/wesyoung, E<lt>saxjazman@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Wes Young (saxjazman@cpan.org)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
