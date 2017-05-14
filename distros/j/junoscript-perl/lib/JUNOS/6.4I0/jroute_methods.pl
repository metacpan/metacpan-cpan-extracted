#
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001- Juniper Networks, Inc.  All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# FILE: jroute_methods.pl -- generated automagikally; DO NOT EDIT
#

%jroute_methods = (
    ## Method : <request-end-session>
    ## Returns: <end-session>
    ## Command: "quit"
    request_end_session => $NO_ARGS,

    ## Method : <clear-system-commit>
    ## Returns: nothing
    ## Command: "clear system commit"
    clear_system_commit => $NO_ARGS,

    ## Method : <clear-ipv6-nd-information>
    ## Returns: <ipv6-modify-nd>
    ## Command: "clear ipv6 neighbors"
    clear_ipv6_nd_information => {
	host => $STRING,
    },

    ## Method : <get-commit-information>
    ## Returns: <commit-information>
    ## Command: "show system commit"
    get_commit_information => $NO_ARGS,

    ## Method : <get-rollback-information>
    ## Returns: <rollback-information>
    ## Command: "show system rollback"
    get_rollback_information => {
	rollback => $STRING,
	compare => $STRING,
	format => $STRING,
    },

    ## Method : <get-system-uptime-information>
    ## Returns: <system-uptime-information>
    ## Command: "show system uptime"
    get_system_uptime_information => {
    },

    ## Method : <get-license-information>
    ## Returns: <license-information>
    ## Command: "show system license"
    get_license_information => $NO_ARGS,

    ## Method : <get-license-key-information>
    ## Returns: <license-key-information>
    ## Command: "show system license keys"
    get_license_key_information => $NO_ARGS,

    ## Method : <get-license-usage-summary>
    ## Returns: <license-usage-summary>
    ## Command: "show system license usage"
    get_license_usage_summary => $NO_ARGS,

    ## Method : <get-service-deployment-service-information>
    ## Returns: <service-deployment-service-information>
    ## Command: "show system services service-deployment"
    get_service_deployment_service_information => $NO_ARGS,

    ## Method : <get-software-information>
    ## Returns: <software-information>
    ## Command: "show version"
    get_software_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
    },

    ## Method : <get-route-information>
    ## Returns: <route-information>
    ## Command: "show route"
    get_route_information => {
	logical_router => $STRING,
	terse => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	best => $TOGGLE,
	exact => $TOGGLE,
	range => $TOGGLE,
	table => $STRING,
	label => $STRING,
	ccc => $STRING,
	inactive => $TOGGLE,
	damping => $STRING,
	next_hop => $STRING,
	source_gateway => $STRING,
	protocol => $STRING,
	bgp => $TOGGLE,
	dvmrp => $TOGGLE,
	pim => $TOGGLE,
	ripng => $TOGGLE,
	rip => $TOGGLE,
	msdp => $TOGGLE,
	neighbor => $STRING,
	bgp => $TOGGLE,
	rip => $TOGGLE,
	ripng => $TOGGLE,
	dvmrp => $TOGGLE,
	pim => $TOGGLE,
	msdp => $TOGGLE,
	peer => $STRING,
	aspath_regex => $STRING,
	no_community => $TOGGLE,
	community_name => $STRING,
	label_switched_path => $STRING,
	destination => $STRING,
	hidden => $TOGGLE,
	all => $TOGGLE,
    },

    ## Method : <get-instance-information>
    ## Returns: <instance-information>
    ## Command: "show route instance"
    get_instance_information => {
	logical_router => $STRING,
	summary => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	name => $STRING,
    },

    ## Method : <get-route-summary-information>
    ## Returns: <route-summary-information>
    ## Command: "show route summary"
    get_route_summary_information => {
	logical_router => $STRING,
    },

    ## Method : <get-rtexport-table-information>
    ## Returns: <rtexport-table-information>
    ## Command: "show route export"
    get_rtexport_table_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	table_name => $STRING,
    },

    ## Method : <get-rtexport-target-information>
    ## Returns: <rtexport-target-information>
    ## Command: "show route export vrf-target"
    get_rtexport_target_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
	logical_router => $STRING,
    },

    ## Method : <get-rtexport-instance-information>
    ## Returns: <rtexport-instance-information>
    ## Command: "show route export instance"
    get_rtexport_instance_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
	logical_router => $STRING,
	instance_name => $STRING,
    },

    ## Method : <get-bgp-summary-information>
    ## Returns: <bgp-information>
    ## Command: "show bgp summary"
    get_bgp_summary_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-bgp-group-information>
    ## Returns: <bgp-group-information>
    ## Command: "show bgp group"
    get_bgp_group_information => {
	logical_router => $STRING,
	summary => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	instance => $STRING,
	group_name => $STRING,
    },

    ## Method : <get-bgp-rtf-information>
    ## Returns: <bgp-rtf-information>
    ## Command: "show bgp group rtf"
    get_bgp_rtf_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	group_name => $STRING,
    },

    ## Method : <get-bgp-traffic-statistics-information>
    ## Returns: <bgp-traffic-statistics-information>
    ## Command: "show bgp group traffic-statistics"
    get_bgp_traffic_statistics_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	group_name => $STRING,
    },

    ## Method : <get-bgp-neighbor-information>
    ## Returns: <bgp-information>
    ## Command: "show bgp neighbor"
    get_bgp_neighbor_information => {
	logical_router => $STRING,
	instance => $STRING,
	neighbor_address => $STRING,
    },

    ## Method : <get-ipv6-nd-information>
    ## Returns: <ipv6-nd-information>
    ## Command: "show ipv6 neighbors"
    get_ipv6_nd_information => $NO_ARGS,

    ## Method : <get-ipv6-ra-information>
    ## Returns: <ipv6-ra-information>
    ## Command: "show ipv6 router-advertisement"
    get_ipv6_ra_information => {
	logical_router => $STRING,
	interface => $STRING,
	conflicts => $TOGGLE,
	prefix => $STRING,
    },

    ## Method : <get-isis-adjacency-information>
    ## Returns: <isis-adjacency-information>
    ## Command: "show isis adjacency"
    get_isis_adjacency_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	instance => $STRING,
	system_id => $STRING,
    },

    ## Method : <get-isis-database-information>
    ## Returns: <isis-database-information>
    ## Command: "show isis database"
    get_isis_database_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	instance => $STRING,
	level => $STRING,
	system_id => $STRING,
    },

    ## Method : <get-isis-hostname-information>
    ## Returns: <isis-hostname-information>
    ## Command: "show isis hostname"
    get_isis_hostname_information => {
	logical_router => $STRING,
    },

    ## Method : <get-isis-interface-information>
    ## Returns: <isis-interface-information>
    ## Command: "show isis interface"
    get_isis_interface_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	instance => $STRING,
	interface_name => $STRING,
    },

    ## Method : <get-isis-route-information>
    ## Returns: <isis-route-information>
    ## Command: "show isis route"
    get_isis_route_information => {
	logical_router => $STRING,
	instance => $STRING,
	destination => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
	topology => $STRING,
    },

    ## Method : <get-isis-spf-information>
    ## Returns: <isis-spf-information>
    ## Command: "show isis spf"
    get_isis_spf_information => $NO_ARGS,

    ## Method : <get-isis-statistics-information>
    ## Returns: <isis-statistics-information>
    ## Command: "show isis statistics"
    get_isis_statistics_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-mpls-admin-group-information>
    ## Returns: <mpls-admin-group-information>
    ## Command: "show mpls admin-groups"
    get_mpls_admin_group_information => {
	logical_router => $STRING,
    },

    ## Method : <get-mpls-cspf-information>
    ## Returns: <mpls-cspf-information>
    ## Command: "show mpls cspf"
    get_mpls_cspf_information => {
	logical_router => $STRING,
    },

    ## Method : <get-mpls-path-information>
    ## Returns: <mpls-path-information>
    ## Command: "show mpls path"
    get_mpls_path_information => {
	logical_router => $STRING,
	path => $STRING,
    },

    ## Method : <get-mpls-interface-information>
    ## Returns: <mpls-interface-information>
    ## Command: "show mpls interface"
    get_mpls_interface_information => {
	logical_router => $STRING,
    },

    ## Method : <get-mpls-diffserv-te-information>
    ## Returns: <mpls-differv-te-information>
    ## Command: "show mpls diffserv-te"
    get_mpls_diffserv_te_information => {
	logical_router => $STRING,
    },

    ## Method : <get-mpls-lsp-information>
    ## Returns: <mpls-lsp-information>
    ## Command: "show mpls lsp"
    get_mpls_lsp_information => {
	logical_router => $STRING,
	ingress => $TOGGLE,
	egress => $TOGGLE,
	transit => $TOGGLE,
	terse => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	descriptions => $TOGGLE,
	up => $TOGGLE,
	down => $TOGGLE,
	unidirectional => $TOGGLE,
	bidirectional => $TOGGLE,
	p2mp => $TOGGLE,
	statistics => $TOGGLE,
	bypass => $TOGGLE,
	name => $STRING,
    },

    ## Method : <get-mpls-call-admission-control-information>
    ## Returns: <mpls-call-admission-control-information>
    ## Command: "show mpls call-admission-control"
    get_mpls_call_admission_control_information => {
	logical_router => $STRING,
	lsp_name => $STRING,
    },

    ## Method : <get-rsvp-interface-information>
    ## Returns: <rsvp-interface-information>
    ## Command: "show rsvp interface"
    get_rsvp_interface_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	link_management => $TOGGLE,
    },

    ## Method : <get-rsvp-neighbor-information>
    ## Returns: <rsvp-neighbor-information>
    ## Command: "show rsvp neighbor"
    get_rsvp_neighbor_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
    },

    ## Method : <get-rsvp-session-information>
    ## Returns: <rsvp-session-information>
    ## Command: "show rsvp session"
    get_rsvp_session_information => {
	logical_router => $STRING,
	ingress => $TOGGLE,
	egress => $TOGGLE,
	transit => $TOGGLE,
	lsp => $TOGGLE,
	nolsp => $TOGGLE,
	up => $TOGGLE,
	down => $TOGGLE,
	unidirectional => $TOGGLE,
	bidirectional => $TOGGLE,
	p2mp => $TOGGLE,
	terse => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	statistics => $TOGGLE,
	bypass => $TOGGLE,
	name => $STRING,
	interface => $STRING,
	te_link => $STRING,
    },

    ## Method : <get-rsvp-statistics-information>
    ## Returns: <rsvp-statistics-information>
    ## Command: "show rsvp statistics"
    get_rsvp_statistics_information => {
	logical_router => $STRING,
    },

    ## Method : <get-rsvp-version-information>
    ## Returns: <rsvp-version-information>
    ## Command: "show rsvp version"
    get_rsvp_version_information => {
	logical_router => $STRING,
    },

    ## Method : <get-ted-database-information>
    ## Returns: <ted-database-information>
    ## Command: "show ted database"
    get_ted_database_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	system_id => $STRING,
    },

    ## Method : <get-ted-link-information>
    ## Returns: <ted-link-information>
    ## Command: "show ted link"
    get_ted_link_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
    },

    ## Method : <get-ted-protocol-information>
    ## Returns: <ted-protocol-information>
    ## Command: "show ted protocol"
    get_ted_protocol_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
    },

    ## Method : <get-igmp-group-information>
    ## Returns: <igmp-group-information>
    ## Command: "show igmp group"
    get_igmp_group_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	group_name => $STRING,
    },

    ## Method : <get-igmp-interface-information>
    ## Returns: <igmp-interface-information>
    ## Command: "show igmp interface"
    get_igmp_interface_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	interface_name => $STRING,
    },

    ## Method : <get-igmp-statistics-information>
    ## Returns: <igmp-statistics-information>
    ## Command: "show igmp statistics"
    get_igmp_statistics_information => {
	logical_router => $STRING,
	interface => $STRING,
    },

    ## Method : <get-mld-group-information>
    ## Returns: <mld-group-information>
    ## Command: "show mld group"
    get_mld_group_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	group_name => $STRING,
    },

    ## Method : <get-mld-interface-information>
    ## Returns: <mld-interface-information>
    ## Command: "show mld interface"
    get_mld_interface_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	interface_name => $STRING,
    },

    ## Method : <get-mld-statistics-information>
    ## Returns: <mld-statistics-information>
    ## Command: "show mld statistics"
    get_mld_statistics_information => {
	logical_router => $STRING,
	interface => $STRING,
    },

    ## Method : <get-dvmrp-neighbors-information>
    ## Returns: <dvmrp-neighbors-information>
    ## Command: "show dvmrp neighbors"
    get_dvmrp_neighbors_information => {
	logical_router => $STRING,
    },

    ## Method : <get-dvmrp-interfaces-information>
    ## Returns: <dvmrp-interfaces-information>
    ## Command: "show dvmrp interfaces"
    get_dvmrp_interfaces_information => {
	logical_router => $STRING,
    },

    ## Method : <get-dvmrp-prunes-information>
    ## Returns: <dvmrp-prunes-information>
    ## Command: "show dvmrp prunes"
    get_dvmrp_prunes_information => {
	logical_router => $STRING,
	all => $TOGGLE,
	rx => $TOGGLE,
	tx => $TOGGLE,
    },

    ## Method : <get-dvmrp-prefix-information>
    ## Returns: <dvmrp-prefix-information>
    ## Command: "show dvmrp prefix"
    get_dvmrp_prefix_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	prefix => $STRING,
    },

    ## Method : <get-multicast-route-information>
    ## Returns: <multicast-route-information>
    ## Command: "show multicast route"
    get_multicast_route_information => {
	logical_router => $STRING,
	all => $TOGGLE,
	active => $TOGGLE,
	inactive => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
	group => $STRING,
	source_prefix => $STRING,
	regexp => $STRING,
	instance => $STRING,
    },

    ## Method : <get-multicast-next-hops-information>
    ## Returns: <multicast-next-hops-information>
    ## Command: "show multicast next-hops"
    get_multicast_next_hops_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	identifier => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
    },

    ## Method : <get-multicast-rpf-information>
    ## Returns: <multicast-rpf-information>
    ## Command: "show multicast rpf"
    get_multicast_rpf_information => {
	logical_router => $STRING,
	summary => $TOGGLE,
	prefix => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
	instance => $STRING,
    },

    ## Method : <get-multicast-scope-information>
    ## Returns: <multicast-scope-information>
    ## Command: "show multicast scope"
    get_multicast_scope_information => {
	logical_router => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
	instance => $STRING,
    },

    ## Method : <get-multicast-sessions-information>
    ## Returns: <multicast-sessions-information>
    ## Command: "show multicast sessions"
    get_multicast_sessions_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	regexp => $STRING,
    },

    ## Method : <get-multicast-statistics-information>
    ## Returns: <multicast-statistics-information>
    ## Command: "show multicast statistics"
    get_multicast_statistics_information => {
	logical_router => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
	instance => $STRING,
    },

    ## Method : <get-multicast-usage-information>
    ## Returns: <multicast-usage-information>
    ## Command: "show multicast usage"
    get_multicast_usage_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	instance => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
    },

    ## Method : <get-pim-bootstrap-information>
    ## Returns: <pim-bootstrap-information>
    ## Command: "show pim bootstrap"
    get_pim_bootstrap_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-pim-interfaces-information>
    ## Returns: <pim-interfaces-information>
    ## Command: "show pim interfaces"
    get_pim_interfaces_information => {
	logical_router => $STRING,
	interface_name => $STRING,
	instance => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
    },

    ## Method : <get-pim-join-information>
    ## Returns: <pim-join-information>
    ## Command: "show pim join"
    get_pim_join_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	range => $STRING,
	instance => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
    },

    ## Method : <get-pim-neighbors-information>
    ## Returns: <pim-neighbors-information>
    ## Command: "show pim neighbors"
    get_pim_neighbors_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	instance => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
    },

    ## Method : <get-pim-rps-information>
    ## Returns: <pim-rps-information>
    ## Command: "show pim rps"
    get_pim_rps_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	group_address => $STRING,
	instance => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
    },

    ## Method : <get-pim-source-information>
    ## Returns: <pim-source-information>
    ## Command: "show pim source"
    get_pim_source_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	source => $STRING,
	instance => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
    },

    ## Method : <get-pim-statistics-information>
    ## Returns: <pim-statistics-information>
    ## Command: "show pim statistics"
    get_pim_statistics_information => {
	logical_router => $STRING,
	interface => $STRING,
	inet => $TOGGLE,
	inet6 => $TOGGLE,
	instance => $STRING,
    },

    ## Method : <get-sap-listen-information>
    ## Returns: <sap-listen-information>
    ## Command: "show sap listen"
    get_sap_listen_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
    },

    ## Method : <get-msdp-statistics-information>
    ## Returns: <pim-msdp-statistics-information>
    ## Command: "show msdp statistics"
    get_msdp_statistics_information => {
	logical_router => $STRING,
	peer => $STRING,
    },

    ## Method : <get-msdp-source-information>
    ## Returns: <pim-msdp-source-information>
    ## Command: "show msdp source"
    get_msdp_source_information => {
	logical_router => $STRING,
	source => $STRING,
    },

    ## Method : <get-msdp-source-active-information>
    ## Returns: <pim-msdp-source-active-information>
    ## Command: "show msdp source-active"
    get_msdp_source_active_information => {
	logical_router => $STRING,
	group => $STRING,
	source => $STRING,
	peer => $STRING,
	local => $TOGGLE,
	originator => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
    },

    ## Method : <get-ospf-database-information>
    ## Returns: <ospf-database-information>
    ## Command: "show ospf database"
    get_ospf_database_information => {
	logical_router => $STRING,
	router => $TOGGLE,
	network => $TOGGLE,
	netsummary => $TOGGLE,
	asbrsummary => $TOGGLE,
	extern => $TOGGLE,
	nssa => $TOGGLE,
	link_local => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	summary => $TOGGLE,
	area => $STRING,
	lsa_id => $STRING,
	advertising_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ospf-interface-information>
    ## Returns: <ospf-interface-information>
    ## Command: "show ospf interface"
    get_ospf_interface_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	interface_name => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ospf-neighbor-information>
    ## Returns: <ospf-neighbor-information>
    ## Command: "show ospf neighbor"
    get_ospf_neighbor_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	neighbor => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ospf-route-information>
    ## Returns: <ospf-route-information>
    ## Command: "show ospf route"
    get_ospf_route_information => {
	logical_router => $STRING,
	detail => $TOGGLE,
	intra => $TOGGLE,
	inter => $TOGGLE,
	abr => $TOGGLE,
	asbr => $TOGGLE,
	extern => $TOGGLE,
	instance => $STRING,
    },

    ## Method : <get-ospf-statistics-information>
    ## Returns: <ospf-statistics-information>
    ## Command: "show ospf statistics"
    get_ospf_statistics_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ospf-io-statistics-information>
    ## Returns: <ospf-io-statistics-information>
    ## Command: "show ospf io-statistics"
    get_ospf_io_statistics_information => {
	logical_router => $STRING,
    },

    ## Method : <get-ospf-log-information>
    ## Returns: <ospf-log-information>
    ## Command: "show ospf log"
    get_ospf_log_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ospf3-database-information>
    ## Returns: <ospf3-database-information>
    ## Command: "show ospf3 database"
    get_ospf3_database_information => {
	logical_router => $STRING,
	router => $TOGGLE,
	network => $TOGGLE,
	inter_area_prefix => $TOGGLE,
	inter_area_router => $TOGGLE,
	extern => $TOGGLE,
	nssa => $TOGGLE,
	link => $TOGGLE,
	link_local => $TOGGLE,
	intra_area_prefix => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	summary => $TOGGLE,
	area => $STRING,
	lsa_id => $STRING,
	advertising_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ospf3-interface-information>
    ## Returns: <ospf3-interface-information>
    ## Command: "show ospf3 interface"
    get_ospf3_interface_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	interface_name => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ospf3-neighbor-information>
    ## Returns: <ospf3-neighbor-information>
    ## Command: "show ospf3 neighbor"
    get_ospf3_neighbor_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	neighbor => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ospf3-route-information>
    ## Returns: <ospf3-route-information>
    ## Command: "show ospf3 route"
    get_ospf3_route_information => {
	logical_router => $STRING,
	detail => $TOGGLE,
	intra => $TOGGLE,
	inter => $TOGGLE,
	transit => $TOGGLE,
	abr => $TOGGLE,
	asbr => $TOGGLE,
	extern => $TOGGLE,
	instance => $STRING,
    },

    ## Method : <get-ospf3-statistics-information>
    ## Returns: <ospf3-statistics-information>
    ## Command: "show ospf3 statistics"
    get_ospf3_statistics_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ospf3-io-statistics-information>
    ## Returns: <ospf3-io-statistics-information>
    ## Command: "show ospf3 io-statistics"
    get_ospf3_io_statistics_information => {
	logical_router => $STRING,
    },

    ## Method : <get-ospf3-log-information>
    ## Returns: <ospf3-log-information>
    ## Command: "show ospf3 log"
    get_ospf3_log_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-rip-statistics-information>
    ## Returns: <rip-statistics-information>
    ## Command: "show rip statistics"
    get_rip_statistics_information => {
	logical_router => $STRING,
	name => $STRING,
	instance => $STRING,
    },

    ## Method : <get-rip-general-statistics-information>
    ## Returns: <rip-general-statistics-information>
    ## Command: "show rip general-statistics"
    get_rip_general_statistics_information => {
	logical_router => $STRING,
    },

    ## Method : <get-rip-neighbor-information>
    ## Returns: <rip-neighbor-information>
    ## Command: "show rip neighbor"
    get_rip_neighbor_information => {
	logical_router => $STRING,
	name => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ldp-interface-information>
    ## Returns: <ldp-interface-information>
    ## Command: "show ldp interface"
    get_ldp_interface_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	instance => $STRING,
    },

    ## Method : <get-ldp-neighbor-information>
    ## Returns: <ldp-neighbor-information>
    ## Command: "show ldp neighbor"
    get_ldp_neighbor_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	instance => $STRING,
    },

    ## Method : <get-ldp-session-information>
    ## Returns: <ldp-session-information>
    ## Command: "show ldp session"
    get_ldp_session_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	instance => $STRING,
	destination => $STRING,
    },

    ## Method : <get-ldp-route-information>
    ## Returns: <ldp-route-information>
    ## Command: "show ldp route"
    get_ldp_route_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	instance => $STRING,
	destination => $STRING,
    },

    ## Method : <get-ldp-path-information>
    ## Returns: <ldp-path-information>
    ## Command: "show ldp path"
    get_ldp_path_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	instance => $STRING,
	destination => $STRING,
    },

    ## Method : <get-ldp-database-information>
    ## Returns: <ldp-database-information>
    ## Command: "show ldp database"
    get_ldp_database_information => {
	logical_router => $STRING,
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	instance => $STRING,
	session => $STRING,
	inet => $TOGGLE,
	l2circuit => $TOGGLE,
    },

    ## Method : <get-ldp-statistics-information>
    ## Returns: <ldp-statistics-information>
    ## Command: "show ldp statistics"
    get_ldp_statistics_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-ldp-traffic-statistics-information>
    ## Returns: <ldp-traffic-statistics-information>
    ## Command: "show ldp traffic-statistics"
    get_ldp_traffic_statistics_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-l2ckt-connection-information>
    ## Returns: <l2ckt-connection-information>
    ## Command: "show l2circuit connections"
    get_l2ckt_connection_information => {
	logical_router => $STRING,
	neighbor => $STRING,
	interface => $STRING,
	down => $TOGGLE,
	up => $TOGGLE,
	up_down => $TOGGLE,
	brief => $TOGGLE,
	extensive => $TOGGLE,
	history => $TOGGLE,
	status => $TOGGLE,
	summary => $TOGGLE,
    },

    ## Method : <get-l2vpn-connection-information>
    ## Returns: <l2vpn-connection-information>
    ## Command: "show l2vpn connections"
    get_l2vpn_connection_information => {
	logical_router => $STRING,
	instance => $STRING,
	local_site => $STRING,
	remote_site => $STRING,
	down => $TOGGLE,
	up => $TOGGLE,
	up_down => $TOGGLE,
	brief => $TOGGLE,
	extensive => $TOGGLE,
	history => $TOGGLE,
	status => $TOGGLE,
	summary => $TOGGLE,
    },

    ## Method : <get-vpls-connection-information>
    ## Returns: <vpls-connection-information>
    ## Command: "show vpls connections"
    get_vpls_connection_information => {
	logical_router => $STRING,
	instance => $STRING,
	local_site => $STRING,
	remote_site => $STRING,
	down => $TOGGLE,
	up => $TOGGLE,
	up_down => $TOGGLE,
	brief => $TOGGLE,
	extensive => $TOGGLE,
	history => $TOGGLE,
	status => $TOGGLE,
	summary => $TOGGLE,
    },

    ## Method : <get-vpls-statistics-information>
    ## Returns: <vpls-statistics-information>
    ## Command: "show vpls statistics"
    get_vpls_statistics_information => {
	logical_router => $STRING,
	instance => $STRING,
    },

    ## Method : <get-lm-information>
    ## Returns: <lm-information>
    ## Command: "show link-management"
    get_lm_information => $NO_ARGS,

    ## Method : <get-lm-peer-information>
    ## Returns: <lm-peer-information>
    ## Command: "show link-management peer"
    get_lm_peer_information => {
	name => $STRING,
    },

    ## Method : <get-lm-te-link-information>
    ## Returns: <lm-te-link-information>
    ## Command: "show link-management te-link"
    get_lm_te_link_information => {
	name => $STRING,
    },

    ## Method : <get-lm-routing-information>
    ## Returns: <lm-information>
    ## Command: "show link-management routing"
    get_lm_routing_information => $NO_ARGS,

    ## Method : <get-lm-routing-peer-information>
    ## Returns: <lm-peer-information>
    ## Command: "show link-management routing peer"
    get_lm_routing_peer_information => {
	name => $STRING,
    },

    ## Method : <get-lm-routing-te-link-information>
    ## Returns: <lm-te-link-information>
    ## Command: "show link-management routing te-link"
    get_lm_routing_te_link_information => {
	name => $STRING,
    },

    ## Method : <get-pgm-nak>
    ## Returns: <pgm-nak>
    ## Command: "show pgm negative-acknowledgments"
    get_pgm_nak => $NO_ARGS,

    ## Method : <get-pgm-source-path-messages>
    ## Returns: <pgm-source-path-messages>
    ## Command: "show pgm source-path-messages"
    get_pgm_source_path_messages => $NO_ARGS,

    ## Method : <get-pgm-statistics>
    ## Returns: <pgm-statistics-information>
    ## Command: "show pgm statistics"
    get_pgm_statistics => $NO_ARGS,

    ## Method : <get-ggsn-imsi-trace>
    ## Returns: <call-trace-information>
    ## Command: "show services ggsn trace imsi"
    get_ggsn_imsi_trace => {
	imsi_identifier => $STRING,
    },

    ## Method : <get-ggsn-msisdn-trace>
    ## Returns: <call-trace-information>
    ## Command: "show services ggsn trace msisdn"
    get_ggsn_msisdn_trace => {
	msisdn_identifier => $STRING,
    },

    ## Method : <get-ggsn-trace>
    ## Returns: <call-trace-information>
    ## Command: "show services ggsn trace all"
    get_ggsn_trace => $NO_ARGS,

    ## Method : <get-ggsn-interface-information>
    ## Returns: <ggsn-interface-information>
    ## Command: "show services ggsn status"
    get_ggsn_interface_information => $NO_ARGS,

    ## Method : <get-ggsn-statistics>
    ## Returns: <ggsn-statistics>
    ## Command: "show services ggsn statistics"
    get_ggsn_statistics => $NO_ARGS,

    ## Method : <get-ggsn-gtp-statistics-information>
    ## Returns: <gtp-statistics-information>
    ## Command: "show services ggsn statistics gtp"
    get_ggsn_gtp_statistics_information => $NO_ARGS,

    ## Method : <get-ggsn-gtp-prime-statistics-information>
    ## Returns: <gtp-prime-statistics-information>
    ## Command: "show services ggsn statistics gtp-prime"
    get_ggsn_gtp_prime_statistics_information => $NO_ARGS,

    ## Method : <get-ggsn-imsi-user-information>
    ## Returns: <mobile-user-information>
    ## Command: "show services ggsn statistics imsi"
    get_ggsn_imsi_user_information => {
	imsi_identifier => $STRING,
    },

    ## Method : <get-ggsn-apn-statistics-information>
    ## Returns: <apn-statistics-information>
    ## Command: "show services ggsn statistics apn"
    get_ggsn_apn_statistics_information => {
	apn_name => $STRING,
    },

    ## Method : <get-ggsn-sgsn-statistics-information>
    ## Returns: <sgsn-statistics-information>
    ## Command: "show services ggsn statistics sgsn"
    get_ggsn_sgsn_statistics_information => {
	address => $STRING,
    },

    ## Method : <set-logical-router>
    ## Returns: nothing
    ## Command: "set cli logical-router"
    set_logical_router => {
	logical_router => $STRING,
    },

    ## Method : <request-package-add>
    ## Returns: nothing
    ## Command: "request system software add"
    request_package_add => {
	force => $TOGGLE,
	reboot => $TOGGLE,
	delay_restart => $TOGGLE,
	no_copy => $TOGGLE,
	no_validate => $TOGGLE,
	validate => $TOGGLE,
	package_name => $STRING,
	backup_routing_engine => $TOGGLE,
    },

    ## Method : <request-package-delete>
    ## Returns: nothing
    ## Command: "request system software delete"
    request_package_delete => {
	force => $TOGGLE,
	package_name => $STRING,
    },

    ## Method : <request-package-validate>
    ## Returns: nothing
    ## Command: "request system software validate"
    request_package_validate => {
	package_name => $STRING,
    },

    ## Method : <request-package-delete-backup>
    ## Returns: nothing
    ## Command: "request system software delete-backup"
    request_package_delete_backup => $NO_ARGS,

    ## Method : <request-license-delete>
    ## Returns: nothing
    ## Command: "request system license delete"
    request_license_delete => {
	license_identifier => $STRING,
    },

    ## Method : <request-ggsn-restart-node>
    ## Returns: <node-action-results>
    ## Command: "request services ggsn restart node"
    request_ggsn_restart_node => $NO_ARGS,

    ## Method : <request-ggsn-restart-interface>
    ## Returns: <interface-action-results>
    ## Command: "request services ggsn restart interface"
    request_ggsn_restart_interface => {
	interface_name => $STRING,
    },

    ## Method : <request-ggsn-stop-node>
    ## Returns: nothing
    ## Command: "request services ggsn stop node"
    request_ggsn_stop_node => $NO_ARGS,

    ## Method : <request-ggsn-stop-interface>
    ## Returns: <interface-action-results>
    ## Command: "request services ggsn stop interface"
    request_ggsn_stop_interface => {
	interface_name => $STRING,
    },

    ## Method : <request-ggsn-terminate-context>
    ## Returns: <pdp-context-deletion-results>
    ## Command: "request services ggsn pdp terminate context"
    request_ggsn_terminate_context => {
	imsi => $STRING,
	nsapi => $STRING,
    },

    ## Method : <request-ggsn-terminate-msisdn-context>
    ## Returns: nothing
    ## Command: "request services ggsn pdp terminate context msisdn"
    request_ggsn_terminate_msisdn_context => {
	msisdn => $STRING,
    },

    ## Method : <request-ggsn-terminate-contexts-apn>
    ## Returns: <apn-pdp-context-deletion-results>
    ## Command: "request services ggsn pdp terminate apn"
    request_ggsn_terminate_contexts_apn => {
	apn_name => $STRING,
    },

    ## Method : <request-ggsn-start-imsi-trace>
    ## Returns: nothing
    ## Command: "request services ggsn trace start imsi"
    request_ggsn_start_imsi_trace => {
	imsi_identifier => $STRING,
    },

    ## Method : <request-ggsn-start-msisdn-trace>
    ## Returns: nothing
    ## Command: "request services ggsn trace start msisdn"
    request_ggsn_start_msisdn_trace => {
	msisdn_identifier => $STRING,
    },

    ## Method : <request-ggsn-stop-imsi-trace>
    ## Returns: nothing
    ## Command: "request services ggsn trace stop imsi"
    request_ggsn_stop_imsi_trace => {
	imsi_identifier => $STRING,
    },

    ## Method : <request-ggsn-stop-msisdn-trace>
    ## Returns: nothing
    ## Command: "request services ggsn trace stop msisdn"
    request_ggsn_stop_msisdn_trace => {
	msisdn_identifier => $STRING,
    },

    ## Method : <request-ggsn-stop-trace-activity>
    ## Returns: nothing
    ## Command: "request services ggsn trace stop all"
    request_ggsn_stop_trace_activity => $NO_ARGS,

    ## Method : <get-syslog-tag-information>
    ## Returns: <syslog-tag-information>
    ## Command: "help syslog"
    get_syslog_tag_information => {
	syslog_tag => $STRING,
    },

    ## Method : <get-cli-tip>
    ## Returns: nothing
    ## Command: "help tip cli"
    get_cli_tip => {
	number => $STRING,
    },

    ## Method : <file-list>
    ## Returns: <directory-list>
    ## Command: "file list"
    file_list => {
	detail => $TOGGLE,
	recursive => $TOGGLE,
	path => $STRING,
    },

    ## Method : <file-delete>
    ## Returns: nothing
    ## Command: "file delete"
    file_delete => {
	path => $STRING,
    },

    ## Method : <file-show>
    ## Returns: <file-content>
    ## Command: "file show"
    file_show => {
	filename => $STRING,
	encoding => $STRING,
    },

    ## Method : <file-compare>
    ## Returns: nothing
    ## Command: "file compare"
    file_compare => {
	context => $TOGGLE,
	unified => $TOGGLE,
	ignore_white_space => $TOGGLE,
	from_file => $STRING,
	to_file => $STRING,
    },

);
