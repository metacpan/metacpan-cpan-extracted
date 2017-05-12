
package XML::SRS::Action;
BEGIN {
  $XML::SRS::Action::VERSION = '0.09';
}

use Moose::Role;
use PRANG::Graph;
use XML::SRS::Types;
use MooseX::Aliases;
use MooseX::Aliases::Meta::Trait::Attribute;

# DomainCreate, DomainUpdate RegistrarCreate RegistrarUpdate
# BillingAmountUpdate SysParamsUpdate RunLogCreate ScheduleCreate
# ScheduleCancel ScheduleUpdate BilledUntilAdjustment
# BuildDnsZoneFiles GenerateDomainReport AdjustRegistrarAccount
# AccessControlListRemove AccessControlListAdd

has_attr 'action_id' =>
	is => "rw",
	isa => "XML::SRS::UID",
	xml_name => 'ActionId',
	required => 1,
	traits => [qw(Aliased)],	
	alias => 'unique_id',
	;

with 'XML::SRS::Node', "PRANG::Graph";

1;
