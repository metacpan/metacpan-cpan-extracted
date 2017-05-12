
package XML::SRS::Error;
BEGIN {
  $XML::SRS::Error::VERSION = '0.09';
}

use Moose;
use PRANG::Graph;
use Moose::Util::TypeConstraints;

sub root_element {"Error"}

has_attr "error_id" =>
	is => "ro",
	isa => "Str",
	required => 1,
	xml_name => "ErrorId",
	;

enum "XML::SRS::Error::Severity" =>
	qw( alert crit err );

has_attr "severity" =>
	is => "ro",
	isa => "XML::SRS::Error::Severity",
	required => 1,
	xml_name => "Severity",
	;

has_attr "hint" =>
	is => "ro",
	isa => "Str",
	required => 1,
	xml_name => "Hint",
	;

has_element "desc" =>
	is => "ro",
	isa => "Str",
	xml_nodeName => "Description",
	;

has_element "details" =>
	is => "ro",
	isa => "ArrayRef[Str]",
	xml_min => 0,
	xml_nodeName => "ErrorDetails",
	auto_deref => 1,
	;

with 'XML::SRS::ActionResponse';

use constant ERROR_DETAILS_NAMES => {
	map {
		if ( my ($error_id, $fields) = m{(\w+)\t(\S.*)} ) {
			my @fields = split /[;,]\s*/, $fields;
			($error_id => \@fields)
		}
		else {
			();
		}
		} split /\n/,
	<<ERRORS };
CONFLICTING_RESULTS_PARAMETERS	
DELETE_FLAG_WITH_OTHER_FIELDS	
DOMAIN_CANCEL_AND_RENEW	
INVALID_FIELDSET	
MISSING_MANDATORY_FIELD	fieldName; ?elementName; ?FieldName; ?FieldName
PUBLIC_KEY_INVALID	
SIG_INVALID	
SIG_VERIFY_FAILED	
UNKNOWN_REGISTRAR	registrarId
DOMAIN_ASSIGNED_TO_NON_REGISTRAR	registrarId
LOCK_ATTEMPT	
MODERATED_DOMAIN_VIOLATION	operation, ?domainName
NOT_PERMITTED_TO_FILTER_REGISTRAR_BY_NAME	
PERMISSION_DENIED	missingPermission
UDAI_DOMAIN_MISMATCH	domainName
ALREADY_ACKED_MESSAGE	originatingRegistrarId; actionId
DOMAIN_ALREADY_EXISTS	domainName
HANDLE_ALREADY_EXISTS	
JOB_ALREADY_EXISTS	jobName, firstRunTime, ?parameters
LIST_ENTRY_ALREADY_EXISTS	
EFFECTIVE_REGISTRAR_DOES_NOT_EXIST	effecitveRegistrarId
HANDLE_DOES_NOT_EXIST	
JOB_UNKNOWN	jobName, ?parameters
ALLOWED_2LD_FOR_REGISTRAR	registrarId
CANCELLED_TRANSFER_WITH_UPDATE	domainName
DOMAIN_INACTIVE	domainName
DOMAIN_IS_NOT_CANCELLED	domainName
DOMAIN_LOCKED	domainName
DOMAIN_WITH_BILL_DAY	
OWNERSHIP_RESTRICTION	?domainName
RENEW_NOT_REQUIRED	domainName
TRANSFER_WITHIN_GRACE_PERIOD	domainName
HANDLE_IN_USE	
REMOVING_REGISTRAR_ROLE	
ACTION_ID_ALREADY_USED	actionId
BILLED_UNTIL_IN_PAST	
BILLED_UNTIL_TOO_FAR_IN_FUTURE	
FINAL_RUNTIME_BEFORE_FIRST_RUNTIME	
FIRST_RUNTIME_PAST	
FREQUENCY_TOO_SMALL	
HANDLE_ID_WITH_CONTACT_FIELDS	
IDN_DOMAINNAME_MISMATCH	domain, domainnameunicode, domainnamepunycode
IDN_INVALID_CHARACTER	domain, domainnameunicode
IDN_INVALID_DOMAINNAME	domain, domainnameunicode
IDN_INVALID_UNICODE	domain, domainnameunicode
IDN_MALFORMED_DOMAINNAME	domain, domainnameunicode
IDN_UNDEFINED_UNICODE	domain, domainnameunicode
IDN_UNICODE_MISMATCH	domain, domainnameunicode, domainnameunicode
INSUFFICIENT_TERM_FOR_RENEW	domainName
INVALID_ADDRESS	
INVALID_ADDRESS_FILTER	
INVALID_CCTLD	domainName
INVALID_DATE_RANGE	fieldName; ?fieldName; ?fieldName
INVALID_EFFECTIVE_REGISTRAR_ID_IN_CreateRegistrar	effectiveRegistrarId; ?requestedRegistrarId
INVALID_EXPLICIT_REGISTRAR_ID	requestedRegistrarId
INVALID_PASSWORD	EPPAuth
INVALID_REGISTRAR_ID_FILTER	
INVALID_WILDCARD_IN_DOMAINNAMEFILTER	
IP4ADDR_NOT_ALLOWED	IP4Addr; FQDN; domainName
IP6ADDR_NOT_ALLOWED	IP6Addr; FQDN; domainName
MULTIPLE_VALUE_IN_FIELD	fieldName; ?fieldName; ?fieldName; ?fieldName
NAMESERVERS_EXCEEDED_MAX	maxnameServers
NAME_SERVER_DUPLICATION	duplicateNameServer; ?domainName
NUMBER_OF_FILTERS_EXCEEDS_MAX	numberOfFilters; fieldName; maxFilterValues
PAST_EFFECTIVE_DATE	
RENEWAL_EXCEEDS_MAX	expectedBilledUntilDate; maxBillingTermInMonths; domainName
RENEW_REQUIRES_TERM	domainName
RUNLOG_QRY_PARAM_WITHOUT_PROCESS	
SELF_SERVING_DNS_VIOLATION	domainName, ?nameServer
TERM_EXCEEDS_MAX	maxRegistrationPeriod
UNDEFINED_VALUE	fieldName; ?fieldName; ?fieldName; ?fieldName
ZERO_TERM_RENEW	
DOMAIN_BLOCKED	domainName
DOUBLE_CANCEL_ATTEMPT	domainName
HANDLE_ID_ON_REGISTRAR_CREATE	
IDN_NOT_ALLOWED	domain
MULTIPLE_DOMAIN_TRANSFER	
REGISTRY_MUST_BE_EFFECTIVE_REGISTRAR	
REGISTRY_MUST_NOT_BE_EFFECTIVE_REGISTRAR	
INVALID_RESPONSE_RECEIVED_FROM_SERVER	response
INVALID_SIGNATURE_RECEIVED_FROM_SERVER	response; signature; pgpError
MISSING_REQUEST_OBJECT	
MISSING_SIGNATURE_RECEIVED_FROM_SERVER	response
REQUEST_COULD_NOT_BE_SIGNED	
CONSENT_ERROR	extraInfo
INCORRECT_EFFECTIVE_REGISTRAR	
INSECURE_UPDATE	
INVALID_EFFECTIVE_REGISTRAR	
INVALID_FIELD	value; fieldName; ?fieldName; ?fieldName; ?fieldName
LOCK_ERROR	details
MESSAGE_TOO_LARGE	sizeLimit; messageSize
NO_ACTION	
NO_MESSAGE_FILTER_VALUES	
REQUEST_TOO_LONG	requestSize, maxSize
UNEXPECTED_FIELD	fieldName; ?fieldName; ?fieldName
UNKNOWN_TRANSACTION_TYPE	transactionType
CLIENT_SYSTEM_ERROR	?systemMessage
RESPONSE_TRANSACTION_NUMBER_MISMATCH	transactions; responses
MALFORMED_TRANSACTION_RESPONSE	fieldName; ?fieldName; ?fieldName; ?fieldName
NO_RESPONSE_RECEIVED_FROM_SERVER	
CONCURRENT_ACK	
EXTRA_POST_PARAMETERS	parameterName, ?parameterName, ?parameterName, ?parameterName, ?parameterName
INTERNAL_ERROR	
MISSING_POST_PARAMETERS	parameterName, ?parameterName, ?parameterName, ?parameterName, ?parameterName
SYSTEM_ERROR	?systemMessage
SYSTEM_MAINTENANCE	
SYSTEM_MIGRATION	
SYSTEM_OFFLINE	
SYSTEM_READONLY	
UNDETERMINED_RESULT	
VERMAJOR_TOO_HIGH	VerMajor
WRONG_MIME_TYPE	expected; received
XML_PARSE_ERROR	xmlErrorString
ERRORS

sub named_details {
	my $self = shift;
	my @named_details;
	my $names = ERROR_DETAILS_NAMES->{$self->error_id} || [];
	my @details = $self->details;
	my @names = map { $names->[$_] } 0..$#details;
	return () unless @details;
	if (@details % 2
		or grep { ($names[$_*2+1]||"") ne "fieldName" }
		0..($#details>>1)
		)
	{
		while (@details) {
			my $name = shift @names;
			push @named_details, (
				$name
				? "error detail '".($name)."'"
				: "(unknown error detail)"
			);
			push @named_details, shift @details;
		}
	}
	else {
		@names = reverse @names;
		@details = reverse @details;
		while (@details) {
			push @named_details, "value of '".(shift @details)."'";
			push @named_details, shift @details;
		}
	}
	@named_details;
}

1;
