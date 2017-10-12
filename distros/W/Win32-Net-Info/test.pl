#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker qw(prompt);

use Win32::Net::Info;

#########################

print <<STOP;

  Win32::Net::Info will attempt to collect and output 
  all current interface information.  To continue 
  *without* running the test simply press 'Enter'.


STOP

my $go = prompt("Continue with tests [y/n] : ", 'n');

if ($go !~ /^y$/i) {
    exit
}

print "\n";
#########################

my @interfaces = Win32::Net::Info->interfaces();

for my $if (@interfaces) {
    my $interface = Win32::Net::Info->new($if);

    if (!defined($interface)) {
        print Win32::Net::Info->error . "\n"
    } else {
        print "\n";
        printf "Name:             %s\n", $interface->name                 if $interface->name;
        printf "Description:      %s\n", $interface->description          if $interface->description;
        printf "Adapter:          %s\n", $interface->adaptername          if $interface->adaptername;
        printf "Device:           %s\n", $interface->device               if $interface->device;
        printf "ifIndex:          %s\n", $interface->ifindex              if $interface->ifindex;
        printf "MAC:              %s\n", $interface->mac                  if $interface->mac;
        printf "IPv4:             %s\n", $interface->ipv4                 if $interface->ipv4;
        printf "IPv4 netmask:     %s\n", $interface->ipv4_netmask         if $interface->ipv4_netmask;
        printf "IPv4 gateway:     %s\n", $interface->ipv4_default_gateway if $interface->ipv4_default_gateway;
        printf "IPv4 gateway MAC: %s\n", $interface->ipv4_gateway_mac     if $interface->ipv4_gateway_mac;
        printf "IPv4 MTU:         %s\n", $interface->ipv4_mtu             if $interface->ipv4_mtu;
        printf "IPv6:             %s\n", $interface->ipv6                 if $interface->ipv6;
        printf "IPv6 link-local:  %s\n", $interface->ipv6_link_local      if $interface->ipv6_link_local;
        # printf "IPv6 DHCPv6 IAID: %s\n", $interface->dhcpv6_iaid          if $interface->dhcpv6_iaid;
        # printf "IPv6 DHCPv6 DUID: %s\n", $interface->dhcpv6_duid          if $interface->dhcpv6_duid;
        printf "IPv6 gateway:     %s\n", $interface->ipv6_default_gateway if $interface->ipv6_default_gateway;
        printf "IPv6 gateway MAC: %s\n", $interface->ipv6_gateway_mac     if $interface->ipv6_gateway_mac;
        printf "IPv6 MTU:         %s\n", $interface->ipv6_mtu             if $interface->ipv6_mtu;
        printf "MTU:              %s\n", $interface->mtu                  if $interface->mtu;
        printf "DNS Server        %s\n", $interface->dnsserver            if $interface->dnsserver;
        print "\n";
        print $interface->dump;
        printf "\nDONE - %s\n", $interface->name if $interface->name;
    }

    my $cont = prompt("Continue with tests [y/n] : ", 'y');

    if ($cont !~ /^y$/i) {
        exit
    }

}
