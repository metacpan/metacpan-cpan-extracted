
package XML::SRS::Types;
BEGIN {
  $XML::SRS::Types::VERSION = '0.09';
}

use 5.010;
use strict;
use warnings;

use Moose::Util::TypeConstraints;
use PRANG::XMLSchema::Types;
use Regexp::Common qw(net);

our $PKG = "XML::SRS";
subtype "${PKG}::Number"
	=> as "PRANG::XMLSchema::nonNegativeInteger";
subtype "${PKG}::RegistrarId"
	=> as "PRANG::XMLSchema::positiveInteger";
subtype "${PKG}::Term"
	=> as "PRANG::XMLSchema::positiveInteger";
subtype "${PKG}::token_OTHERS"
	=> as "Str",
	=> where { $_ eq "OTHERS" };
subtype "${PKG}::RegistrarIdOrOTHERS"
	=> as "${PKG}::RegistrarId|${PKG}::token_OTHERS";

subtype "${PKG}::Dollars"
	=> as "PRANG::XMLSchema::decimal"
	=> where {
	($_ - sprintf("%.2f",$_)) < 0.0000001;
	};
subtype "${PKG}::UID"
	=> as "Str"; # XXX - any other constraints on ActionIDs?

# a non-IDN domain name
our $RR_re = qr/[a-zA-Z0-9](:?[a-zA-Z0-9\-]*[a-zA-Z0-9])?/;
our $DNS_name_re = qr/(?:$RR_re\.)+$RR_re/;
subtype "${PKG}::DomainName"
	=> as "Str"
	=> where {
	m{\A$DNS_name_re\Z};
	};

subtype "${PKG}::UDAI"
	=> as "Str"
	=> where {
	$_ =~
m{ \A [abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789]{8} \z }xms;
	};

subtype "${PKG}::HandleId"
	=> as "PRANG::XMLSchema::token"
	=> where {

	# this is a subset of the EPP handle ID specification,
	# which allows for 3-16 characters.  Here we just
	# restrict it to "word" characters, which still allows
	# a whole bunch of Unicode characters.  And hyphens.
	m{\A[\p{IsWord}\- ]{3,16}\Z};
	};

subtype "${PKG}::Email"
	=> as "Str"
	=> where {

	# kept as-is for historical reasons
	m{\A(?:[^@\s]+|".*")\@$DNS_name_re\Z};
	};

subtype "${PKG}::IPv4"
	=> as "Str"
	=> where {
	$_ =~ m{ \A $RE{net}{IPv4} \z }xms;
	};

# IPv6 : from Regexp::IPv6
# http://search.cpan.org/~salva/Regexp-IPv6-0.02/lib/Regexp/IPv6.pm
# http://cpansearch.perl.org/src/SALVA/Regexp-IPv6-0.02/lib/Regexp/IPv6.pm
my $IPv4 =
"(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))";
my $G = "[\\da-f]{1,4}";
my @tail =
	( ":", ":(?:$G)?", "(?:(?::$G){1,2}|:$IPv4?)",
	"(?::$G)?(?:(?::$G){1,2}|:$IPv4?)",
	"(?::$G){0,2}(?:(?::$G){1,2}|:$IPv4?)",
	"(?::$G){0,3}(?:(?::$G){1,2}|:$IPv4?)",
	"(?::$G){0,4}(?:(?::$G){1,2}|:$IPv4?)" );
my $IPv6_re = $G;
$IPv6_re = "$G:(?:$IPv6_re|$_)" for @tail;
$IPv6_re = qr/:(?::$G){0,5}(?:(?::$G){1,2}|:$IPv4)|$IPv6_re/i;

subtype "${PKG}::IPv6"
	=> as "Str"
	=> where {
	$_ =~ m{ \A $IPv6_re \z }xms;
	};

our @Boolean = qw(0 1);
subtype "${PKG}::Boolean"
	=> as "Bool"
	=> where {
	$_ ~~ @Boolean;
	};
coerce "${PKG}::Boolean"
	=> from "Bool"
	=> via { $_ ? 1 : 0 };
coerce "${PKG}::Dollars"
	=> from "PRANG::XMLSchema::decimal"
	=> via {
	sprintf("%.2f",$_);
	};

our @AccountingAction = qw(Credit Debit);
subtype "${PKG}::token_OTHERS"
	=> as "Str",
	=> where { $_ ~~ @AccountingAction };

enum "${PKG}::DomainWriteAction" =>
	qw(DomainCreate DomainUpdate);

enum "${PKG}::DomainQueryAction" =>
	qw(Whois DomainDetailsQry ActionDetailsQry UDAIValidQry);

enum "${PKG}::HandleWriteAction" =>
	qw(HandleCreate HandleUpdate);

subtype "${PKG}::HandleQueryAction"
	=> as "Str",
	=> where {
	$_ eq qw(HandleDetailsQry);
	};

enum "${PKG}::RegistrarWriteAction" =>
	qw(RegistrarCreate  RegistrarUpdate AckMessage);

enum "${PKG}::RegistrarQueryAction" =>
	qw(RegistrarDetailsQry  RegistrarAccountQry  GetMessages);

enum "${PKG}::RegistryAction" =>
	qw(SysParamsUpdate SysParamsQry RunLogCreate RunLogQry
	ScheduleCreate ScheduleCancel ScheduleQry ScheduleUpdate
	BillingExtract SetBillingAmount BillingAmountQry
	DeferredIncomeSummaryQry DeferredIncomeDetailQry
	BilledUntilAdjustment BuildDnsZoneFiles GenerateDomainReport
	AdjustRegistrarAccount AccessControlListQry
	AccessControlListAdd AccessControlListRemove);

subtype "${PKG}::ActionName" =>
	as join(
	"|",
	map {"${PKG}::$_"}
		qw(DomainWriteAction DomainQueryAction
		HandleWriteAction HandleQueryAction
		RegistrarWriteAction RegistrarQueryAction
		RegistryAction)
	);

enum "${PKG}::ActionEtcExtra" =>
	qw(UnknownTransaction  DomainTransfer);

enum "${PKG}::RegDomainStatus" =>
	qw(Active PendingRelease);
enum "${PKG}::DomainStatus" =>
	qw(Active PendingRelease Available);

subtype "${PKG}::ActionEtc"
	=> as "${PKG}::ActionName|${PKG}::ActionEtcExtra";

enum "${PKG}::RoleName" =>
	qw( Registrar Registry Whois Query CreateDomain UpdateDomain
	TransferDomain CancelDomain UncancelDomain UpdateRegistrar
	Administer Supervisor Connect ReleaseDomain QueryACL
	UpdateACL QueryRegACL);

# Domain Statuses
enum "${PKG}::RegDomainStatus" =>
	qw(Active PendingRelease);

enum "${PKG}::DomainStatus" =>
	qw(Active PendingRelease Available);

enum "${PKG}::BillStatus" =>
	qw(PendingConfirmation Confirmed);

1;
