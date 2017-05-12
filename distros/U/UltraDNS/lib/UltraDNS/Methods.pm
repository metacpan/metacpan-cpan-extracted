package UltraDNS::Methods;

=head1 NAME

UltraDNS::Methods - Available UltraDNS Transaction Protocol Methods

=head1 SYNOPSIS

  use UltraDNS;

  $udns = UltraDNS->connect(...);

  $udns->...any of these methods...(...);
  $udns->...any of these methods...(...);
  $udns->...any of these methods...(...);

  $udns->commit;

  $udns->...any of these methods...(...);
  $udns->...any of these methods...(...);
  $udns->...any of these methods...(...);

  $udns->commit;

  # etc

=head1 DESCRIPTION

This module contains details of the UltraDNS methods defined by the UltraDNS
Transaction Protocol documentation.

Refer to L<UltraDNS> for more details.

=head1 METHODS

The methods can be called either with our without the C<UDNS_> prefix that
appears in the UltraDNS docs. They're shown here without the prefix because it
I prefer it that way.

=cut

use strict;
use warnings;

my $method_spec;

sub _method_spec {
    my ($self, $method_name) = @_;
    return $method_spec->{$method_name};
}

$method_spec = {
  "UDNS_AddMailForward" => {
    "arg_info" => [
      {
        "example" => "emailTo",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "forwardTo",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "domain.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_AddRestrictIPForAllZones" => {
    "arg_info" => [
      {
        "example" => "start_ip",
        "sigil" => "\$",
        "type" => "ip_address"
      },
      {
        "example" => "end_ip",
        "sigil" => "\$",
        "type" => "ip_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_AddRestrictIPForZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "start_ip",
        "sigil" => "\$",
        "type" => "ip_address"
      },
      {
        "example" => "end_ip",
        "sigil" => "\$",
        "type" => "ip_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_AddUserXInfo" => {
    "arg_info" => [
      {
        "example" => "Username",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "FieldName",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "Value",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_AddWebForward" => {
    "arg_info" => [
      {
        "example" => "requestTo",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "redirectTo",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "forwardType",
        "sigil" => "\$",
        "type" => "unsigned"
      },
      {
        "example" => "domain.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeAliasOfCNAMERecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "alias.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewAlias.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeContentOfTXTRecord " => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "OldContent",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "NewContent",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeEmailOfSOARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "user\@domain.com",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeExpireLimitOfSOARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => 86400,
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeHostOfAAAARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "IPAddress",
        "sigil" => "\$",
        "type" => "ipv6_address"
      },
      {
        "example" => "NewHostname.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeHostOfARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "1.1.1.1",
        "sigil" => "\$",
        "type" => "ip_address"
      },
      {
        "example" => "NewHost.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeHostOfCNAMERecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "alias.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewHost.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeHostOfPTRRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "1.1.1.1.in-addr.arpa.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewHost.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeHostOfTXTRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "Content",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "NewHostname.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeIPOfAAAARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "IPAddress",
        "sigil" => "\$",
        "type" => "ipv6_address"
      },
      {
        "example" => "New IP",
        "sigil" => "\$",
        "type" => "ipv6_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeIPOfARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "1.1.1.1",
        "sigil" => "\$",
        "type" => "ip_address"
      },
      {
        "example" => "1.1.2.2",
        "sigil" => "\$",
        "type" => "ip_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeIPOfPTRRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "1.1.1.1.in-addr.arpa.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "1.1.2.2.in-addr.arpa.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeMailServerOfMXRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "ServedZone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "MailServer.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewServer.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeMinimumCacheOfSOARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => 86400,
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeNameServerOfNSRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "ServedDomain.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "NameServer.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewNameServer.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeNameServerOfSOARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "NewNameServer.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangePriorityOfMXRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "ServedZone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "MailServer.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => 10,
        "sigil" => "\$",
        "type" => "unsigned_short"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeRefreshIntervalOfSOARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => 86400,
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeRetryIntervalOfSOARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => 86400,
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeSerialNumberOfSOARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Serial Number",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeServedDomainOfNSRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "ServedDomain.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "NameServer.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewDomain.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeServedZoneOfMXRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "ServedZone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "MailServer.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewZone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeTTLOfAAAARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "IPAddress",
        "sigil" => "\$",
        "type" => "ipv6_address"
      },
      {
        "example" => "NewTTL",
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeTTLOfARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "1.1.1.1",
        "sigil" => "\$",
        "type" => "ip_address"
      },
      {
        "example" => "NewTTL",
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeTTLOfCNAMERecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "alias.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewTTL",
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeTTLOfMXRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "ServedZone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "MailServer.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewTTL",
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeTTLOfNSRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "ServedDomain.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "NameServer.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewTTL",
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeTTLOfPTRRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "1.1.1.1.in-addr.arpa.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "NewTTL",
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeTTLOfSOARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "NewTTL",
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeTTLOfTXTRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "Content",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "NewTTL",
        "sigil" => "\$",
        "type" => "unsigned"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeUserEmail" => {
    "arg_info" => [
      {
        "example" => "UserName",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "NewEmail",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_ChangeUserPassword" => {
    "arg_info" => [
      {
        "example" => "UserName",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "OldPassword",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "NewPassword",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CloseConnection" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateAAAARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "IPAddress",
        "sigil" => "\$",
        "type" => "ipv6_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateARecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "HostName.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "ipAddr",
        "sigil" => "\$",
        "type" => "ip_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateCNAMERecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Alias.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "HostName.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateMXRecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "ServedZone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "MailServer.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "priority",
        "sigil" => "\$",
        "type" => "unsigned_short"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateNSRecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "SubDomain.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "NameServer.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreatePTRRecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "4.3.2.1.in-addr.arpa.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "HostName.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreatePrimaryZone" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateRPRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "user\@domain.com",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "data.",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateResourceRecord" => {
    "arg_info" => [
      {
        "example" => "0303372E01CBF764",
        "sigil" => "\$",
        "type" => "id"
      },
      {
        "example" => "www.example.biz.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => 1,
        "sigil" => "\$",
        "type" => "unsigned_short"
      },
      {
        "example" => 1025,
        "sigil" => "\$",
        "type" => "unsigned_short"
      },
      {
        "example" => 300,
        "sigil" => "\$",
        "type" => "unsigned_short"
      },
      {
        "example" => "982a1479b1273891273c81279831d",
        "sigil" => "\$",
        "type" => "hexint"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateSSHFPRecord" => {
    "arg_info" => [
      {
        "example" => "test.zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "sshfp2.test.zonel.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => 0,
        "sigil" => "\$",
        "type" => "unsigned_short"
      },
      {
        "example" => 1,
        "sigil" => "\$",
        "type" => "unsigned_short"
      },
      {
        "example" => "0123456789abcdef",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateSecondaryZone" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "PrimaryNameServer",
        "sigil" => "\$",
        "type" => "ip_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateTXTRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "Content",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_CreateUser" => {
    "arg_info" => [
      {
        "example" => "NewUserName",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "Password",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "Email",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "FirstInitial",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "LastInitial",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "ServicePkg",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "PricingPkg",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteAAAARecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "IPAddress",
        "sigil" => "\$",
        "type" => "ipv6_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteARecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "HostName.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "ipAddr",
        "sigil" => "\$",
        "type" => "ip_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteAllRecordsOfUser" => {
    "arg_info" => [
      {
        "example" => "UserName",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteCNAMERecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Alias.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteMXRecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "ServedZone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "MailServer.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteMailForward" => {
    "arg_info" => [
      {
        "example" => "guid",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "domain.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteNSRecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "SubDomain.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "NameServer.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeletePTRRecord" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "4.3.2.1.in-addr.arpa.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "HostName.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteRPRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Host.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "email",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteResourceRecord" => {
    "arg_info" => [
      {
        "example" => "0303372E01CBF764",
        "sigil" => "\$",
        "type" => "id"
      },
      {
        "example" => "0403372E01CBF99F",
        "sigil" => "\$",
        "type" => "id"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteSSHFPRecord" => {
    "arg_info" => [
      {
        "example" => "test.zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "sshfp.test.zone.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteTXTRecord" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteUser" => {
    "arg_info" => [
      {
        "example" => "UserName",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteUserXInfo" => {
    "arg_info" => [
      {
        "example" => "Username",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "FieldName",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteWebForward" => {
    "arg_info" => [
      {
        "example" => "guid",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "domain.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DeleteZone" => {
    "arg_info" => [
      {
        "example" => "ZoneName.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_DisableAutoSerialUpdate" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_Disconnect" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_EnableAutoSerialUpdate" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_FindResourceRecords" => {
    "arg_info" => [
      {
        "example" => "0123456789ABCDEF",
        "sigil" => "\$",
        "type" => "id"
      },
      {
        "example" => "hostname.myzone.com.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => 1,
        "sigil" => "\$",
        "type" => "unsigned_short"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetAAAARecordsOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetARecordsOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetASNForRecord" => {
    "arg_info" => [
      {
        "example" => "0123456789ABCDEF",
        "sigil" => "\$",
        "type" => "id"
      },
      {
        "example" => "123456789ABCDEF0",
        "sigil" => "\$",
        "type" => "id"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetASNList" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_GetAllRRsOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetAllZonesOfUser" => {
    "arg_info" => [
      {
        "example" => "UserName",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetAutoSerialUpdateState" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_GetCNAMERecordsOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetDirectionalMaskForRecord" => {
    "arg_info" => [
      {
        "example" => "0123456789ABCDEF",
        "sigil" => "\$",
        "type" => "id"
      },
      {
        "example" => "123456789ABCDEF0",
        "sigil" => "\$",
        "type" => "id"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetDirectionalServerList" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_GetMXRecordsOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetNSRecordsOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetPTRRecordsOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetPrimaryZonesOfUser" => {
    "arg_info" => [
      {
        "example" => "UserName",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetRPRecordsOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetRecordsOfDnameByType" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "Type",
        "sigil" => "\$",
        "type" => "int"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetSOARecordOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetSSHFPRecordsOfZone" => {
    "arg_info" => [
      {
        "example" => "test.zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetSecondaryZonesOfUser" => {
    "arg_info" => [
      {
        "example" => "UserName",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetServerStatus" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_GetTXTRecordsOfZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetUserXInfo" => {
    "arg_info" => [
      {
        "example" => "Username",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "FieldName",
        "sigil" => "\$",
        "type" => "string"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GetUsers" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_GetZoneInfo" => {
    "arg_info" => [
      {
        "example" => "test.zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GrantPermissionsToAccountZonesForUser" => {
    "arg_info" => [
      {
        "example" => "account",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "user",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "allowCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowDelete",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyDelete",
        "sigil" => "\$",
        "type" => "boolean"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GrantPermissionsToMailForwardForUser" => {
    "arg_info" => [
      {
        "example" => "user",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "mailforward",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "allowCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowDelete",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyDelete",
        "sigil" => "\$",
        "type" => "boolean"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GrantPermissionsToWebForwardForUser" => {
    "arg_info" => [
      {
        "example" => "user",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "webforward",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "allowCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowDelete",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyDelete",
        "sigil" => "\$",
        "type" => "boolean"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GrantPermissionsToZoneForUser" => {
    "arg_info" => [
      {
        "example" => "user",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "allowCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowDelete",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyDelete",
        "sigil" => "\$",
        "type" => "boolean"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GrantPermissionsToZoneMailForwardsForUser" => {
    "arg_info" => [
      {
        "example" => "user",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "allowCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowDelete",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyDelete",
        "sigil" => "\$",
        "type" => "boolean"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_GrantPermissionsToZoneWebForwardsForUser" => {
    "arg_info" => [
      {
        "example" => "user",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "allowCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "allowDelete",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyCreate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyRead",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyUpdate",
        "sigil" => "\$",
        "type" => "boolean"
      },
      {
        "example" => "denyDelete",
        "sigil" => "\$",
        "type" => "boolean"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_NoAutoCommit" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_OpenConnection" => {
    "arg_info" => [
      {
        "example" => "SponsorID",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "UserName",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "Password",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "3.0",
        "sigil" => "\$",
        "type" => "float"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_QueryMailForwards" => {
    "arg_info" => [
      {
        "example" => "domain.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_QueryWebForwards" => {
    "arg_info" => [
      {
        "example" => "domain.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_RemoveRestrictIPForAllZones" => {
    "arg_info" => [],
    "last_arg_repeats" => 0
  },
  "UDNS_RemoveRestrictIPForZone" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "start_ip",
        "sigil" => "\$",
        "type" => "ip_address"
      },
      {
        "example" => "end_ip",
        "sigil" => "\$",
        "type" => "ip_address"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_RequestZoneTransfer" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_SetASNForRecord" => {
    "arg_info" => [
      {
        "example" => "0123456789ABCDEF",
        "sigil" => "\$",
        "type" => "id"
      },
      {
        "example" => "123456789ABCDEF0",
        "sigil" => "\$",
        "type" => "id"
      },
      {
        "example" => 1,
        "sigil" => "\$",
        "type" => "integer"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_SetDirectionalMaskForRecord" => {
    "arg_info" => [
      {
        "example" => "0123456789ABCDEF",
        "sigil" => "\$",
        "type" => "id"
      },
      {
        "example" => "123456789ABCDEF0",
        "sigil" => "\$",
        "type" => "id"
      },
      {
        "elem_type" => "unsigned_int",
        "sigil" => "\\\@",
        "type" => "array"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_UpdateAAAARecords" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "IPAddress",
        "sigil" => "\@",
        "type" => "ipv6_address"
      }
    ],
    "last_arg_repeats" => 1
  },
  "UDNS_UpdateARecords" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "IP address",
        "sigil" => "\@",
        "type" => "ip_address"
      }
    ],
    "last_arg_repeats" => 1
  },
  "UDNS_UpdateCNAMERecords" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "CNAME.",
        "sigil" => "\$",
        "type" => "hostname"
      },
      {
        "example" => "Hostname.",
        "sigil" => "\@",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 1
  },
  "UDNS_UpdateMailForward" => {
    "arg_info" => [
      {
        "example" => "guid",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "forwardTo",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "domain.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  },
  "UDNS_UpdateNSRecords" => {
    "arg_info" => [
      {
        "example" => "Zone.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "Zone for NS.",
        "sigil" => "\$",
        "type" => "zonename"
      },
      {
        "example" => "NS hostname.",
        "sigil" => "\@",
        "type" => "hostname"
      }
    ],
    "last_arg_repeats" => 1
  },
  "UDNS_UpdateWebForward" => {
    "arg_info" => [
      {
        "example" => "guid",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "requestTo",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "redirectTo",
        "sigil" => "\$",
        "type" => "string"
      },
      {
        "example" => "forwardType",
        "sigil" => "\$",
        "type" => "unsigned"
      },
      {
        "example" => "domain.",
        "sigil" => "\$",
        "type" => "zonename"
      }
    ],
    "last_arg_repeats" => 0
  }
};


1;
=head2 AddMailForward

  $udns->AddMailForward($string, $string, $zonename);

  $string = emailTo
  $string = forwardTo
  $zonename = domain.

=head2 AddRestrictIPForAllZones

  $udns->AddRestrictIPForAllZones($ip_address, $ip_address);

  $ip_address = start_ip
  $ip_address = end_ip

=head2 AddRestrictIPForZone

  $udns->AddRestrictIPForZone($zonename, $ip_address, $ip_address);

  $zonename = Zone.
  $ip_address = start_ip
  $ip_address = end_ip

=head2 AddUserXInfo

  $udns->AddUserXInfo($string, $string, $string);

  $string = Username
  $string = FieldName
  $string = Value

=head2 AddWebForward

  $udns->AddWebForward($string, $string, $unsigned, $zonename);

  $string = requestTo
  $string = redirectTo
  $unsigned = forwardType
  $zonename = domain.

=head2 ChangeAliasOfCNAMERecord

  $udns->ChangeAliasOfCNAMERecord($zonename, $hostname, $hostname, $hostname);

  $zonename = Zone.
  $hostname = alias.
  $hostname = host.
  $hostname = NewAlias.

=head2 ChangeContentOfTXTRecord 

  $udns->ChangeContentOfTXTRecord ($zonename, $hostname, $string, $string);

  $zonename = Zone.
  $hostname = Hostname.
  $string = OldContent
  $string = NewContent

=head2 ChangeEmailOfSOARecord

  $udns->ChangeEmailOfSOARecord($zonename, $string);

  $zonename = Zone.
  $string = user@domain.com

=head2 ChangeExpireLimitOfSOARecord

  $udns->ChangeExpireLimitOfSOARecord($zonename, $unsigned);

  $zonename = Zone.
  $unsigned = 86400

=head2 ChangeHostOfAAAARecord

  $udns->ChangeHostOfAAAARecord($zonename, $hostname, $ipv6_address, $hostname);

  $zonename = Zone.
  $hostname = Hostname.
  $ipv6_address = IPAddress
  $hostname = NewHostname.

=head2 ChangeHostOfARecord

  $udns->ChangeHostOfARecord($zonename, $hostname, $ip_address, $hostname);

  $zonename = Zone.
  $hostname = host.
  $ip_address = 1.1.1.1
  $hostname = NewHost.

=head2 ChangeHostOfCNAMERecord

  $udns->ChangeHostOfCNAMERecord($zonename, $hostname, $hostname, $hostname);

  $zonename = Zone.
  $hostname = alias.
  $hostname = host.
  $hostname = NewHost.

=head2 ChangeHostOfPTRRecord

  $udns->ChangeHostOfPTRRecord($zonename, $hostname, $hostname, $hostname);

  $zonename = Zone.
  $hostname = 1.1.1.1.in-addr.arpa.
  $hostname = host.
  $hostname = NewHost.

=head2 ChangeHostOfTXTRecord

  $udns->ChangeHostOfTXTRecord($zonename, $hostname, $string, $hostname);

  $zonename = Zone.
  $hostname = Hostname.
  $string = Content
  $hostname = NewHostname.

=head2 ChangeIPOfAAAARecord

  $udns->ChangeIPOfAAAARecord($zonename, $hostname, $ipv6_address, $ipv6_address);

  $zonename = Zone.
  $hostname = Hostname.
  $ipv6_address = IPAddress
  $ipv6_address = New IP

=head2 ChangeIPOfARecord

  $udns->ChangeIPOfARecord($zonename, $hostname, $ip_address, $ip_address);

  $zonename = Zone.
  $hostname = host.
  $ip_address = 1.1.1.1
  $ip_address = 1.1.2.2

=head2 ChangeIPOfPTRRecord

  $udns->ChangeIPOfPTRRecord($zonename, $hostname, $hostname, $hostname);

  $zonename = Zone.
  $hostname = 1.1.1.1.in-addr.arpa.
  $hostname = host.
  $hostname = 1.1.2.2.in-addr.arpa.

=head2 ChangeMailServerOfMXRecord

  $udns->ChangeMailServerOfMXRecord($zonename, $zonename, $hostname, $hostname);

  $zonename = Zone.
  $zonename = ServedZone.
  $hostname = MailServer.
  $hostname = NewServer.

=head2 ChangeMinimumCacheOfSOARecord

  $udns->ChangeMinimumCacheOfSOARecord($zonename, $unsigned);

  $zonename = Zone.
  $unsigned = 86400

=head2 ChangeNameServerOfNSRecord

  $udns->ChangeNameServerOfNSRecord($zonename, $zonename, $hostname, $hostname);

  $zonename = Zone.
  $zonename = ServedDomain.
  $hostname = NameServer.
  $hostname = NewNameServer.

=head2 ChangeNameServerOfSOARecord

  $udns->ChangeNameServerOfSOARecord($zonename, $hostname);

  $zonename = Zone.
  $hostname = NewNameServer.

=head2 ChangePriorityOfMXRecord

  $udns->ChangePriorityOfMXRecord($zonename, $zonename, $hostname, $unsigned_short);

  $zonename = Zone.
  $zonename = ServedZone.
  $hostname = MailServer.
  $unsigned_short = 10

=head2 ChangeRefreshIntervalOfSOARecord

  $udns->ChangeRefreshIntervalOfSOARecord($zonename, $unsigned);

  $zonename = Zone.
  $unsigned = 86400

=head2 ChangeRetryIntervalOfSOARecord

  $udns->ChangeRetryIntervalOfSOARecord($zonename, $unsigned);

  $zonename = Zone.
  $unsigned = 86400

=head2 ChangeSerialNumberOfSOARecord

  $udns->ChangeSerialNumberOfSOARecord($zonename, $string);

  $zonename = Zone.
  $string = Serial Number

=head2 ChangeServedDomainOfNSRecord

  $udns->ChangeServedDomainOfNSRecord($zonename, $zonename, $hostname, $zonename);

  $zonename = Zone.
  $zonename = ServedDomain.
  $hostname = NameServer.
  $zonename = NewDomain.

=head2 ChangeServedZoneOfMXRecord

  $udns->ChangeServedZoneOfMXRecord($zonename, $zonename, $hostname, $zonename);

  $zonename = Zone.
  $zonename = ServedZone.
  $hostname = MailServer.
  $zonename = NewZone.

=head2 ChangeTTLOfAAAARecord

  $udns->ChangeTTLOfAAAARecord($zonename, $hostname, $ipv6_address, $unsigned);

  $zonename = Zone.
  $hostname = Hostname.
  $ipv6_address = IPAddress
  $unsigned = NewTTL

=head2 ChangeTTLOfARecord

  $udns->ChangeTTLOfARecord($zonename, $hostname, $ip_address, $unsigned);

  $zonename = Zone.
  $hostname = host.
  $ip_address = 1.1.1.1
  $unsigned = NewTTL

=head2 ChangeTTLOfCNAMERecord

  $udns->ChangeTTLOfCNAMERecord($zonename, $hostname, $hostname, $unsigned);

  $zonename = Zone.
  $hostname = alias.
  $hostname = host.
  $unsigned = NewTTL

=head2 ChangeTTLOfMXRecord

  $udns->ChangeTTLOfMXRecord($zonename, $zonename, $hostname, $unsigned);

  $zonename = Zone.
  $zonename = ServedZone.
  $hostname = MailServer.
  $unsigned = NewTTL

=head2 ChangeTTLOfNSRecord

  $udns->ChangeTTLOfNSRecord($zonename, $zonename, $hostname, $unsigned);

  $zonename = Zone.
  $zonename = ServedDomain.
  $hostname = NameServer.
  $unsigned = NewTTL

=head2 ChangeTTLOfPTRRecord

  $udns->ChangeTTLOfPTRRecord($zonename, $hostname, $hostname, $unsigned);

  $zonename = Zone.
  $hostname = 1.1.1.1.in-addr.arpa.
  $hostname = host.
  $unsigned = NewTTL

=head2 ChangeTTLOfSOARecord

  $udns->ChangeTTLOfSOARecord($zonename, $unsigned);

  $zonename = Zone.
  $unsigned = NewTTL

=head2 ChangeTTLOfTXTRecord

  $udns->ChangeTTLOfTXTRecord($zonename, $hostname, $string, $unsigned);

  $zonename = Zone.
  $hostname = Hostname.
  $string = Content
  $unsigned = NewTTL

=head2 ChangeUserEmail

  $udns->ChangeUserEmail($string, $string);

  $string = UserName
  $string = NewEmail

=head2 ChangeUserPassword

  $udns->ChangeUserPassword($string, $string, $string);

  $string = UserName
  $string = OldPassword
  $string = NewPassword

=head2 CloseConnection

  $udns->CloseConnection;

=head2 CreateAAAARecord

  $udns->CreateAAAARecord($zonename, $hostname, $ipv6_address);

  $zonename = Zone.
  $hostname = Hostname.
  $ipv6_address = IPAddress

=head2 CreateARecord

  $udns->CreateARecord($zonename, $hostname, $ip_address);

  $zonename = ZoneName.
  $hostname = HostName.
  $ip_address = ipAddr

=head2 CreateCNAMERecord

  $udns->CreateCNAMERecord($zonename, $hostname, $hostname);

  $zonename = ZoneName.
  $hostname = Alias.
  $hostname = HostName.

=head2 CreateMXRecord

  $udns->CreateMXRecord($zonename, $zonename, $hostname, $unsigned_short);

  $zonename = ZoneName.
  $zonename = ServedZone.
  $hostname = MailServer.
  $unsigned_short = priority

=head2 CreateNSRecord

  $udns->CreateNSRecord($zonename, $zonename, $hostname);

  $zonename = ZoneName.
  $zonename = SubDomain.
  $hostname = NameServer.

=head2 CreatePTRRecord

  $udns->CreatePTRRecord($zonename, $hostname, $hostname);

  $zonename = ZoneName.
  $hostname = 4.3.2.1.in-addr.arpa.
  $hostname = HostName.

=head2 CreatePrimaryZone

  $udns->CreatePrimaryZone($zonename);

  $zonename = ZoneName.

=head2 CreateRPRecord

  $udns->CreateRPRecord($zonename, $hostname, $string, $string);

  $zonename = Zone.
  $hostname = Host.
  $string = user@domain.com
  $string = data.

=head2 CreateResourceRecord

  $udns->CreateResourceRecord($id, $hostname, $unsigned_short, $unsigned_short, $unsigned_short, $hexint);

  $id = 0303372E01CBF764
  $hostname = www.example.biz.
  $unsigned_short = 1
  $unsigned_short = 1025
  $unsigned_short = 300
  $hexint = 982a1479b1273891273c81279831d

=head2 CreateSSHFPRecord

  $udns->CreateSSHFPRecord($zonename, $hostname, $unsigned_short, $unsigned_short, $string);

  $zonename = test.zone.
  $hostname = sshfp2.test.zonel.
  $unsigned_short = 0
  $unsigned_short = 1
  $string = 0123456789abcdef

=head2 CreateSecondaryZone

  $udns->CreateSecondaryZone($zonename, $ip_address);

  $zonename = ZoneName.
  $ip_address = PrimaryNameServer

=head2 CreateTXTRecord

  $udns->CreateTXTRecord($zonename, $hostname, $string);

  $zonename = Zone.
  $hostname = Hostname.
  $string = Content

=head2 CreateUser

  $udns->CreateUser($string, $string, $string, $string, $string, $string, $string);

  $string = NewUserName
  $string = Password
  $string = Email
  $string = FirstInitial
  $string = LastInitial
  $string = ServicePkg
  $string = PricingPkg

=head2 DeleteAAAARecord

  $udns->DeleteAAAARecord($zonename, $hostname, $ipv6_address);

  $zonename = Zone.
  $hostname = Hostname.
  $ipv6_address = IPAddress

=head2 DeleteARecord

  $udns->DeleteARecord($zonename, $hostname, $ip_address);

  $zonename = ZoneName.
  $hostname = HostName.
  $ip_address = ipAddr

=head2 DeleteAllRecordsOfUser

  $udns->DeleteAllRecordsOfUser($string);

  $string = UserName

=head2 DeleteCNAMERecord

  $udns->DeleteCNAMERecord($zonename, $hostname);

  $zonename = ZoneName.
  $hostname = Alias.

=head2 DeleteMXRecord

  $udns->DeleteMXRecord($zonename, $zonename, $hostname);

  $zonename = ZoneName.
  $zonename = ServedZone.
  $hostname = MailServer.

=head2 DeleteMailForward

  $udns->DeleteMailForward($string, $zonename);

  $string = guid
  $zonename = domain.

=head2 DeleteNSRecord

  $udns->DeleteNSRecord($zonename, $zonename, $hostname);

  $zonename = ZoneName.
  $zonename = SubDomain.
  $hostname = NameServer.

=head2 DeletePTRRecord

  $udns->DeletePTRRecord($zonename, $hostname, $hostname);

  $zonename = ZoneName.
  $hostname = 4.3.2.1.in-addr.arpa.
  $hostname = HostName.

=head2 DeleteRPRecord

  $udns->DeleteRPRecord($zonename, $hostname, $string);

  $zonename = Zone.
  $hostname = Host.
  $string = email

=head2 DeleteResourceRecord

  $udns->DeleteResourceRecord($id, $id);

  $id = 0303372E01CBF764
  $id = 0403372E01CBF99F

=head2 DeleteSSHFPRecord

  $udns->DeleteSSHFPRecord($zonename, $hostname);

  $zonename = test.zone.
  $hostname = sshfp.test.zone.

=head2 DeleteTXTRecord

  $udns->DeleteTXTRecord($zonename, $hostname);

  $zonename = Zone.
  $hostname = Hostname.

=head2 DeleteUser

  $udns->DeleteUser($string);

  $string = UserName

=head2 DeleteUserXInfo

  $udns->DeleteUserXInfo($string, $string);

  $string = Username
  $string = FieldName

=head2 DeleteWebForward

  $udns->DeleteWebForward($string, $zonename);

  $string = guid
  $zonename = domain.

=head2 DeleteZone

  $udns->DeleteZone($zonename);

  $zonename = ZoneName.

=head2 DisableAutoSerialUpdate

  $udns->DisableAutoSerialUpdate;

=head2 Disconnect

  $udns->Disconnect;

=head2 EnableAutoSerialUpdate

  $udns->EnableAutoSerialUpdate;

=head2 FindResourceRecords

  $udns->FindResourceRecords($id, $hostname, $unsigned_short);

  $id = 0123456789ABCDEF
  $hostname = hostname.myzone.com.
  $unsigned_short = 1

=head2 GetAAAARecordsOfZone

  $udns->GetAAAARecordsOfZone($zonename);

  $zonename = Zone.

=head2 GetARecordsOfZone

  $udns->GetARecordsOfZone($zonename);

  $zonename = Zone.

=head2 GetASNForRecord

  $udns->GetASNForRecord($id, $id);

  $id = 0123456789ABCDEF
  $id = 123456789ABCDEF0

=head2 GetASNList

  $udns->GetASNList;

=head2 GetAllRRsOfZone

  $udns->GetAllRRsOfZone($zonename);

  $zonename = Zone.

=head2 GetAllZonesOfUser

  $udns->GetAllZonesOfUser($string);

  $string = UserName

=head2 GetAutoSerialUpdateState

  $udns->GetAutoSerialUpdateState;

=head2 GetCNAMERecordsOfZone

  $udns->GetCNAMERecordsOfZone($zonename);

  $zonename = Zone.

=head2 GetDirectionalMaskForRecord

  $udns->GetDirectionalMaskForRecord($id, $id);

  $id = 0123456789ABCDEF
  $id = 123456789ABCDEF0

=head2 GetDirectionalServerList

  $udns->GetDirectionalServerList;

=head2 GetMXRecordsOfZone

  $udns->GetMXRecordsOfZone($zonename);

  $zonename = Zone.

=head2 GetNSRecordsOfZone

  $udns->GetNSRecordsOfZone($zonename);

  $zonename = Zone.

=head2 GetPTRRecordsOfZone

  $udns->GetPTRRecordsOfZone($zonename);

  $zonename = Zone.

=head2 GetPrimaryZonesOfUser

  $udns->GetPrimaryZonesOfUser($string);

  $string = UserName

=head2 GetRPRecordsOfZone

  $udns->GetRPRecordsOfZone($zonename);

  $zonename = Zone.

=head2 GetRecordsOfDnameByType

  $udns->GetRecordsOfDnameByType($zonename, $hostname, $int);

  $zonename = Zone.
  $hostname = Hostname.
  $int = Type

=head2 GetSOARecordOfZone

  $udns->GetSOARecordOfZone($zonename);

  $zonename = Zone.

=head2 GetSSHFPRecordsOfZone

  $udns->GetSSHFPRecordsOfZone($zonename);

  $zonename = test.zone.

=head2 GetSecondaryZonesOfUser

  $udns->GetSecondaryZonesOfUser($string);

  $string = UserName

=head2 GetServerStatus

  $udns->GetServerStatus;

=head2 GetTXTRecordsOfZone

  $udns->GetTXTRecordsOfZone($zonename);

  $zonename = Zone.

=head2 GetUserXInfo

  $udns->GetUserXInfo($string, $string);

  $string = Username
  $string = FieldName

=head2 GetUsers

  $udns->GetUsers;

=head2 GetZoneInfo

  $udns->GetZoneInfo($zonename);

  $zonename = test.zone.

=head2 GrantPermissionsToAccountZonesForUser

  $udns->GrantPermissionsToAccountZonesForUser($string, $string, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean);

  $string = account
  $string = user
  $boolean = allowCreate
  $boolean = allowRead
  $boolean = allowUpdate
  $boolean = allowDelete
  $boolean = denyCreate
  $boolean = denyRead
  $boolean = denyUpdate
  $boolean = denyDelete

=head2 GrantPermissionsToMailForwardForUser

  $udns->GrantPermissionsToMailForwardForUser($string, $string, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean);

  $string = user
  $string = mailforward
  $boolean = allowCreate
  $boolean = allowRead
  $boolean = allowUpdate
  $boolean = allowDelete
  $boolean = denyCreate
  $boolean = denyRead
  $boolean = denyUpdate
  $boolean = denyDelete

=head2 GrantPermissionsToWebForwardForUser

  $udns->GrantPermissionsToWebForwardForUser($string, $string, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean);

  $string = user
  $string = webforward
  $boolean = allowCreate
  $boolean = allowRead
  $boolean = allowUpdate
  $boolean = allowDelete
  $boolean = denyCreate
  $boolean = denyRead
  $boolean = denyUpdate
  $boolean = denyDelete

=head2 GrantPermissionsToZoneForUser

  $udns->GrantPermissionsToZoneForUser($string, $zonename, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean);

  $string = user
  $zonename = Zone.
  $boolean = allowCreate
  $boolean = allowRead
  $boolean = allowUpdate
  $boolean = allowDelete
  $boolean = denyCreate
  $boolean = denyRead
  $boolean = denyUpdate
  $boolean = denyDelete

=head2 GrantPermissionsToZoneMailForwardsForUser

  $udns->GrantPermissionsToZoneMailForwardsForUser($string, $zonename, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean);

  $string = user
  $zonename = Zone.
  $boolean = allowCreate
  $boolean = allowRead
  $boolean = allowUpdate
  $boolean = allowDelete
  $boolean = denyCreate
  $boolean = denyRead
  $boolean = denyUpdate
  $boolean = denyDelete

=head2 GrantPermissionsToZoneWebForwardsForUser

  $udns->GrantPermissionsToZoneWebForwardsForUser($string, $zonename, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean, $boolean);

  $string = user
  $zonename = Zone.
  $boolean = allowCreate
  $boolean = allowRead
  $boolean = allowUpdate
  $boolean = allowDelete
  $boolean = denyCreate
  $boolean = denyRead
  $boolean = denyUpdate
  $boolean = denyDelete

=head2 QueryMailForwards

  $udns->QueryMailForwards($zonename);

  $zonename = domain.

=head2 QueryWebForwards

  $udns->QueryWebForwards($zonename);

  $zonename = domain.

=head2 RemoveRestrictIPForAllZones

  $udns->RemoveRestrictIPForAllZones;

=head2 RemoveRestrictIPForZone

  $udns->RemoveRestrictIPForZone($zonename, $ip_address, $ip_address);

  $zonename = Zone.
  $ip_address = start_ip
  $ip_address = end_ip

=head2 RequestZoneTransfer

  $udns->RequestZoneTransfer($zonename);

  $zonename = Zone.

=head2 SetASNForRecord

  $udns->SetASNForRecord($id, $id, $integer);

  $id = 0123456789ABCDEF
  $id = 123456789ABCDEF0
  $integer = 1

=head2 SetDirectionalMaskForRecord

  $udns->SetDirectionalMaskForRecord($id, $id, \@array);

  $id = 0123456789ABCDEF
  $id = 123456789ABCDEF0
  \@array = [ $unsigned_int, ... ]

=head2 UpdateAAAARecords

  $udns->UpdateAAAARecords($zonename, $hostname, @ipv6_address);

  $zonename = Zone.
  $hostname = Hostname.
  @ipv6_address = (IPAddress, ...)

=head2 UpdateARecords

  $udns->UpdateARecords($zonename, $hostname, @ip_address);

  $zonename = Zone.
  $hostname = Hostname.
  @ip_address = (IP address, ...)

=head2 UpdateCNAMERecords

  $udns->UpdateCNAMERecords($zonename, $hostname, @hostname);

  $zonename = Zone.
  $hostname = CNAME.
  @hostname = (Hostname., ...)

=head2 UpdateMailForward

  $udns->UpdateMailForward($string, $string, $zonename);

  $string = guid
  $string = forwardTo
  $zonename = domain.

=head2 UpdateNSRecords

  $udns->UpdateNSRecords($zonename, $zonename, @hostname);

  $zonename = Zone.
  $zonename = Zone for NS.
  @hostname = (NS hostname., ...)

=head2 UpdateWebForward

  $udns->UpdateWebForward($string, $string, $string, $unsigned, $zonename);

  $string = guid
  $string = requestTo
  $string = redirectTo
  $unsigned = forwardType
  $zonename = domain.


=cut
