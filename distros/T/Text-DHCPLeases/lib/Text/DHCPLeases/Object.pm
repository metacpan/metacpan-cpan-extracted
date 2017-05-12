package Text::DHCPLeases::Object;

use warnings;
use strict;
use Carp;
use Class::Struct;
use vars qw($VERSION);
$VERSION = '1.0';

# IPv4 regular expression
my $IPV4  = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

# weekday year/month/day hour:minute:second
my $DATE  = '\d+ \d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}';

=head1 NAME

Text::DHCPLeases::Object - Leases Object Class

=head1 SYNOPSIS

my $obj = Text::DHCPLeases::Object->parse($string);

or 

my $obj = Text::DHCPLeases::Object->new(%lease_data);

print $obj->name;
print $obj->type;
print $obj->binding_state;

=head1 DESCRIPTION

DHCPLeases object class.  Lease objects can be one of the following types:

    lease
    host
    group
    subgroup
    failover-state

=cut

struct (
'type'                    => '$',
'name'                    => '$',
'ip_address'              => '$',
'fixed_address'           => '$',
'starts'                  => '$',
'ends'                    => '$',
'tstp'                    => '$',
'tsfp'                    => '$',
'atsfp'                   => '$',
'cltt'                    => '$',
'next_binding_state'      => '$',
'binding_state'           => '$',
'uid'                     => '$',
'client_hostname'         => '$',
'abandoned'               => '$',
'deleted'                 => '$',
'dynamic_bootp'           => '$',
'dynamic'                 => '$',
'option_agent_circuit_id' => '$',
'option_agent_remote_id'  => '$',
'hardware_type'           => '$',
'mac_address'             => '$',
'set'                     => '%',
'on'                      => '%',
'bootp'                   => '$',
'reserved'                => '$',
'my_state'                => '$',
'my_state_date'           => '$',
'partner_state'           => '$',
'partner_state_date'      => '$',
'mclt'                    => '$',
'ddns_rev_name'           => '$',
'ddns_fwd_name'           => '$',
'ddns_txt'                => '$'
);

=head1 CLASS METHODS

=head2 new - Constructor

  Arguments:
    type                       one of (lease|host|group|subgroup|failover-state)
    name                       identification string (address, host name, group name, etc)
    ip_address
    fixed_address
    starts                     
    ends
    tstp
    tsfp
    atsfp
    cltt
    next_binding_state
    binding_state
    uid
    client_hostname
    abandoned                 (flag)
    deleted                   (flag)
    dynamic_bootp             (flag)
    dynamic                   (flag)
    option_agent_circuit_id
    option_agent_remote_id
    hardware_type
    mac_address
    set                       (hash)
    on                        (hash)
    bootp                     (flag)
    reserved                  (flag)
    my_state
    my_state_date
    partner_state
    partner_state_date
    mclt
    dns_rev_name
    ddns_fwd_name
    ddns_txt
  Returns:
    New Text::DHCPLeases::Object object
  Examples:

    my $lease = Text::DHCPLeases::Object->new(type       => 'lease',
                                              ip_address => '192.168.1.10',
                                              starts     => '3 2007/08/15 11:34:58',
                                              ends       => '3 2007/08/15 11:44:58');
   
=cut

############################################################
=head2 parse - Parse object declaration

Arguments:
   Array ref with declaration lines
Returns:
   Hash reference.  
  Examples:

    my $text = '
lease 192.168.254.55 {
  starts 3 2007/08/15 11:34:58;
  ends 3 2007/08/15 11:44:58;
  tstp 3 2007/08/15 11:49:58;
  tsfp 2 2007/08/14 21:24:19;
  cltt 3 2007/08/15 11:34:58;
  binding state active;
  next binding state expired;
  hardware ethernet 00:11:85:5d:4e:11;
  uid "\001\000\021\205]Nh";
  client-hostname "blah";
}';

my $lease_data = Text::DHCPLeases::Lease->parse($text);
=cut
sub parse{
    my ($self, $lines) = @_;
    my %obj;
    for ( @$lines ){
	$_ =~ s/^\s+//o;
	$_ =~ s/\s+$//o;
	next if ( /^#|^$|\}$/o );
	if ( /^lease ($IPV4) /o ){
	    $obj{type} = 'lease';
	    $obj{name} = $1;
	    $obj{'ip_address'} = $1;
	}elsif ( /^(host|group|subgroup) (.*) /o ){
	    $obj{type} = $1;
	    $obj{name} = $2;	
	}elsif ( /^failover peer (.*) state/o ){
	    $obj{type} = 'failover-state';
	    $obj{name} = $1;	
	}elsif ( /starts ($DATE);/o ){
	    $obj{starts} = $1;
	}elsif ( /ends ($DATE|never);/o ){
	    $obj{ends} = $1;
	}elsif ( /tstp ($DATE|never);/o ){
	    $obj{tstp} = $1;
	}elsif ( /atsfp ($DATE|never);/o ){
	    $obj{atsfp} = $1;
	}elsif ( /tsfp ($DATE|never);/o ){
	    $obj{tsfp} = $1;
	}elsif ( /cltt ($DATE);/o ){
	    $obj{cltt} = $1;
	}elsif ( /^next binding state (\w+);/o ){
	    $obj{'next_binding_state'} = $1;
	}elsif ( /^binding state (\w+);/o ){
	    $obj{'binding_state'} = $1;
	}elsif ( /^rewind binding state (\w+);/o ){
	    $obj{'rewind_binding_state'} = $1;	
	}elsif ( /uid (\".*\");/o ){
	    $obj{uid} = $1;
	}elsif ( /client-hostname \"(.*)\";/o ){
	    $obj{'client_hostname'} = $1;
	}elsif ( /abandoned;/o ){
	    $obj{abandoned} = 1;
	}elsif ( /deleted;/o ){
	    $obj{deleted} = 1;
	}elsif ( /dynamic-bootp;/o ){
	    $obj{dynamic_bootp} = 1;
	}elsif ( /dynamic;/o ){
	    $obj{dynamic} = 1;
	}elsif ( /hardware (.+) (.*);/o ){
	    $obj{'hardware_type'} = $1;
	    $obj{'mac_address'}   = $2;
	}elsif ( /fixed-address (.*);/o ){
	    $obj{'fixed_address'} = $1;
	}elsif ( /option agent\.circuit-id (.*);/o ){
	    $obj{'option_agent_circuit_id'} = $1;
	}elsif ( /option agent\.remote-id (.*);/o ){
	    $obj{'option_agent_remote_id'} = $1;
	}elsif ( /set (\w+) = (.*);/o ){
	    $obj{set}{$1} = $2;
	}elsif ( /on (.*) \{(.*)\};/o ){
	    my $events     = $1;
	    my @events = split /\|/, $events;
	    my $statements = $2;
	    my @statements = split /\n;/, $statements;
	    $obj{on}{events}     = @events;
	    $obj{on}{statements} = @statements;
	}elsif ( /bootp;/o ){
	    $obj{bootp} = 1;
	}elsif ( /reserved;/o ){
	    $obj{reserved} = 1;
	}elsif ( /failover peer \"(.*)\" state/o ){
	    $obj{name} = $1;
	}elsif ( /my state (.*) at ($DATE);/o ){
	    $obj{my_state} = $1;
	    $obj{my_state_date} = $2;
	}elsif (/partner state (.*) at ($DATE);/o ){
	    $obj{partner_state} = $1;
	    $obj{partner_state_date} = $2;
	}elsif (/mclt (\w+);/o ){
	    $obj{mclt} = $1;
	}elsif (/set ddns-rev-name = \"(.*)\";/o){
	    $obj{ddns_rev_name} = $1;
	}elsif (/set ddns-fwd-name = \"(.*)\";/o){
	    $obj{ddns_fwd_name} = $1;
	}elsif (/set ddns-txt = \"(.*)\";/o){
	    $obj{ddns_txt} = $1;
	}else{
	    carp "Text::DHCPLeases::Object::parse Error: Statement not recognized: '$_'\n";
	}
    }
    return \%obj;
}

=head1 INSTANCE METHODS
=cut

############################################################
=head2 print - Print formatted string with lease contents

  Arguments:
    None
  Returns:
    Formatted String
  Examples:
    print $obj->print;
=cut
sub print{
    my ($self) = @_;
    my $out = "";
    if ( $self->type eq 'lease' ){
	$out .= sprintf("lease %s {\n", $self->ip_address);	
    }elsif ( $self->type eq 'failover-state' ){
	# These are printed with an extra carriage return in 3.1.0
	$out .= sprintf("\nfailover peer %s state {\n", $self->name);	
    }else{
	$out .= sprintf("%s %s {\n", $self->type, $self->name);
    }
    $out .= sprintf("  starts %s;\n", $self->starts) if $self->starts;
    $out .= sprintf("  ends %s;\n",   $self->ends)   if $self->ends;
    $out .= sprintf("  tstp %s;\n",   $self->tstp)   if $self->tstp;
    $out .= sprintf("  tsfp %s;\n",   $self->tsfp)   if $self->tsfp;
    $out .= sprintf("  atsfp %s;\n",  $self->atsfp)  if $self->atsfp;
    $out .= sprintf("  cltt %s;\n",   $self->cltt)   if $self->cltt;
    $out .= sprintf("  binding state %s;\n",   $self->binding_state)   
	if $self->binding_state;
    $out .= sprintf("  next binding state %s;\n",   $self->next_binding_state)
	if $self->next_binding_state;
    $out .= sprintf("  dynamic-bootp;\n") if $self->dynamic_bootp;
    $out .= sprintf("  dynamic;\n") if $self->dynamic;
    $out .= sprintf("  hardware %s %s;\n", $self->hardware_type, $self->mac_address) 
	if ( $self->hardware_type && $self->mac_address );
    $out .= sprintf("  uid %s;\n", $self->uid) if $self->uid;
    $out .= sprintf("  set ddns-rev-name = \"%s\";\n", $self->ddns_rev_name) if $self->ddns_rev_name;
    $out .= sprintf("  set ddns-txt = \"%s\";\n", $self->ddns_txt) if $self->ddns_txt;
    $out .= sprintf("  set ddns-fwd-name = \"%s\";\n", $self->ddns_fwd_name) if $self->ddns_fwd_name;
    $out .= sprintf("  fixed-address %s;\n", $self->fixed_address) if $self->fixed_address;
    $out .= sprintf("  abandoned;\n") if $self->abandoned;
    $out .= sprintf("  deleted;\n") if $self->abandoned;
    $out .= sprintf("  option agent.circuit-id %s;\n", $self->option_agent_circuit_id) 
	if $self->option_agent_circuit_id;
    $out .= sprintf("  option agent.remote-id %s;\n", $self->option_agent_remote_id) 
	if $self->option_agent_remote_id;
    if ( defined $self->set ){
	foreach my $var ( keys %{ $self->set } ){
	    $out .= sprintf("  set %s = %s;\n", $var, $self->set->{$var});
	}
    }
    if ( $self->on && $self->on->{events} && $self->on->{statements} ){
	my $events = join '|', @{$self->on->{events}};
	my $statements = join '\n;', @{$self->on->{statements}};
	$out .= sprintf("  on %s { %s }", $events, $statements);

    }
    $out .= sprintf("  client-hostname \"%s\";\n", $self->client_hostname) if $self->client_hostname;
    # These are only for failover-state objects
    $out .= sprintf("  my state %s at %s;\n", $self->my_state, $self->my_state_date) 
	if $self->my_state;
    $out .= sprintf("  partner state %s at %s;\n", $self->partner_state, $self->partner_state_date) 
	if $self->partner_state; 
    $out .= sprintf("  mclt %s;\n", $self->mclt) if $self->mclt;
    $out .= "}\n";
    return $out;
}


# Make sure to return 1
1;

=head1 AUTHOR

Carlos Vicente  <cvicente@cpan.org>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Carlos Vicente <cvicente@cpan.org>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
=cut
