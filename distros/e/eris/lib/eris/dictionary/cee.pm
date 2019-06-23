package eris::dictionary::cee;
# ABSTRACT: Contains fields in the Common Event Expression syntax

use Moo;
use JSON::MaybeXS;
use namespace::autoclean;
with qw(
    eris::role::dictionary::hash
);

our $VERSION = '0.008'; # VERSION


my $_hash=undef;
sub hash {
    my $self = shift;
    return $_hash if defined $_hash;
    my %data;
    while(<DATA>) {
        chomp;
        my ($field,$def) = $self->expand_line($_);
        next unless $field;
        $data{$field} = $def;
    }
    $_hash = \%data;
}
1;

=pod

=encoding UTF-8

=head1 NAME

eris::dictionary::cee - Contains fields in the Common Event Expression syntax

=head1 VERSION

version 0.008

=head1 SYNOPSIS

This dictionary contains all the fields as specified by the "Common Event Expression" format.

=head1 SEE ALSO

L<eris::dictionary>, L<eris::role::dictionary>

=for Pod::Coverage hash

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

__DATA__
acct Account Username
acct_domain Account Domain
acct_fullname Account Fullname
acct_id Account User ID
boot_id Producer Boot ID
dev Device Name
dev_links Device Node Links
dev_node Device Node
driver System Kernel Driver Name
dst Destination Hostname
{ "name": "dst_ip", "type": "ip", "description": "Destination IP Address" }
dst_mac Destination MAC Address
{ "name": "dst_port", "type": "integer", "description": "Destination Port Nummber" }
dst_prefix_len Destination IP Address Prefix Length
exe Binary process exe path
file File Name
{ "name": "in_bytes", "type": "double", "description": "Inbound (Ingress) Bytes" }
{ "name": "in_pkts", "type": "double", "description": "Inbound (Ingress) Packet Count" }
{ "name": "out_bytes", "type": "double", "description": "Outbound (Egress) Bytes" }
{ "name": "out_pkts", "type": "double", "description": "Outbound (Egress) Packet Count" }
{ "name": "p_ip", "type": "ip", "description": "Producer IP address" }
p_mac Producer MAC address
proc Process Name
{ "name": "proc_egid", "type": "integer", "description": "Process Effective Group ID" }
{ "name": "proc_euid", "type": "integer", "description": "Process Effectice User ID" }
{ "name": "proc_gid", "type": "integer", "description": "Process Group ID" }
{ "name": "proc_uid", "type": "integer", "description": "Process User ID" }
{ "name": "proc_id", "type": "integer", "description": "Process ID" }
prod Product Name
proto_app Network Application Protocol Name
{ "name": "rcv_time", "type": "date", "description": "Event Record Receive Time" }
rec_id Event Record ID
{ "name": "rec_time", "type": "date", "description": "Event Record Time" }
sess User Session ID
src Source Hostname
{ "name": "src_ip", "type": "ip", "description": "Source IP Address" }
src_mac Source MAC Address
{ "name": "src_port", "type": "integer", "description": " Source Port Nummber" }
src_prefix_len Source IP Address Prefix Length
subsystem System Kernel Subsystem
action Primary action taken
crit Event Criticality
domain Environment or domain
id Event ID
object Type of object
p_app  Producing application
p_proc Producing process
{ "name": "p_proc_id", "type": "integer", "description": "Producing Process ID" }
p_sys Producing system
pri Priority of the Event
schema Schema covered by event
schema_ver Version of the Schema
service Service involved
status Result of the action
subject type of object initiated
tags Freeform tags for the event
{ "name": "time", "type": "date", "description": "Time of the event" }
