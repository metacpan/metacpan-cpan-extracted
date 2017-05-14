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
# FILE: jkernel_methods.pl -- generated automagikally; DO NOT EDIT
#

%jkernel_methods = (
    ## Method : <clear-arp-table>
    ## Returns: <clear-arp-table-results>
    ## Command: "clear arp"
    clear_arp_table => {
	hostname => $STRING,
	vpn => $STRING,
    },

    ## Method : <clear-reboot>
    ## Returns: nothing
    ## Command: "clear system reboot"
    clear_reboot => {
	both_routing_engines => $TOGGLE,
    },

    ## Method : <clear-helper-statistics-information>
    ## Returns: nothing
    ## Command: "clear helper statistics"
    clear_helper_statistics_information => $NO_ARGS,

    ## Method : <clear-service-sfw-flow-table-information>
    ## Returns: <service-sfw-flow-drain-information>
    ## Command: "clear services stateful-firewall flows"
    clear_service_sfw_flow_table_information => {
	source_prefix => $STRING,
	destination_prefix => $STRING,
	source_port => $STRING,
	destination_port => $STRING,
	protocol => $STRING,
	service_set => $STRING,
	interface => $STRING,
    },

    ## Method : <clear-services-flow-collector-information>
    ## Returns: nothing
    ## Command: "clear services flow-collector"
    clear_services_flow_collector_information => $NO_ARGS,

    ## Method : <clear-services-flow-collector-statistics>
    ## Returns: <clear-services-flow-collector-response>
    ## Command: "clear services flow-collector statistics"
    clear_services_flow_collector_statistics => {
	interface => $STRING,
    },

    ## Method : <get-arp-table-information>
    ## Returns: <arp-table-information>
    ## Command: "show arp"
    get_arp_table_information => {
	no_resolve => $TOGGLE,
    },

    ## Method : <get-interface-information>
    ## Returns: <interface-information>
    ## Command: "show interfaces"
    get_interface_information => {
	extensive => $TOGGLE,
	statistics => $TOGGLE,
	media => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
	brief => $TOGGLE,
	descriptions => $TOGGLE,
	snmp_index => $STRING,
	interface_name => $STRING,
    },

    ## Method : <get-mac-database>
    ## Returns: <mac-database>
    ## Command: "show interfaces mac-database"
    get_mac_database => {
	interface_name => $STRING,
	mac_address => $STRING,
    },

    ## Method : <get-interface-queue-information>
    ## Returns: <interface-information>
    ## Command: "show interfaces queue"
    get_interface_queue_information => {
	forwarding_class => $STRING,
	interface_name => $STRING,
    },

    ## Method : <get-interface-filter-information>
    ## Returns: <interface-filter-information>
    ## Command: "show interfaces filters"
    get_interface_filter_information => {
	interface_name => $STRING,
    },

    ## Method : <get-interface-policer-information>
    ## Returns: <interface-policer-information>
    ## Command: "show interfaces policers"
    get_interface_policer_information => {
	interface_name => $STRING,
    },

    ## Method : <get-destination-class-statistics>
    ## Returns: <destination-class-statistics>
    ## Command: "show interfaces destination-class"
    get_destination_class_statistics => {
	class_name => $STRING,
	interface_name => $STRING,
    },

    ## Method : <get-source-class-statistics>
    ## Returns: <source-class-statistics>
    ## Command: "show interfaces source-class"
    get_source_class_statistics => {
	class_name => $STRING,
	interface_name => $STRING,
    },

    ## Method : <get-forwarding-table-information>
    ## Returns: <forwarding-table-information>
    ## Command: "show route forwarding-table"
    get_forwarding_table_information => {
	detail => $TOGGLE,
	extensive => $TOGGLE,
	multicast => $TOGGLE,
	family => $STRING,
	vpn => $STRING,
	table => $STRING,
	summary => $TOGGLE,
	matching => $STRING,
	destination => $STRING,
	label => $STRING,
	ccc => $STRING,
    },

    ## Method : <get-directory-usage-information>
    ## Returns: <directory-usage-information>
    ## Command: "show system directory-usage"
    get_directory_usage_information => {
	path => $STRING,
	depth => $STRING,
    },

    ## Method : <get-package-backup-information>
    ## Returns: <package-backup-information>
    ## Command: "show system software backup"
    get_package_backup_information => $NO_ARGS,

    ## Method : <get-system-storage>
    ## Returns: <system-storage-information>
    ## Command: "show system storage"
    get_system_storage => {
    },

    ## Method : <get-switchover-information>
    ## Returns: <switchover-information>
    ## Command: "show system switchover"
    get_switchover_information => {
    },

    ## Method : <get-system-users-information>
    ## Returns: <system-users-information>
    ## Command: "show system users"
    get_system_users_information => {
	no_resolve => $TOGGLE,
    },

    ## Method : <get-autoinstallation-status-information>
    ## Returns: <autoinstallation-status-information>
    ## Command: "show system autoinstallation status"
    get_autoinstallation_status_information => $NO_ARGS,

    ## Method : <get-pfe-information>
    ## Returns: <pfe-information>
    ## Command: "show pfe terse"
    get_pfe_information => $NO_ARGS,

    ## Method : <get-accounting-profile-information>
    ## Returns: <accounting-profile-information>
    ## Command: "show accounting profile"
    get_accounting_profile_information => {
	profile => $STRING,
    },

    ## Method : <get-accounting-record-information>
    ## Returns: <accounting-record-information>
    ## Command: "show accounting records"
    get_accounting_record_information => {
	profile => $STRING,
	since => $STRING,
	utc_timestamp => $TOGGLE,
    },

    ## Method : <get-alarm-information>
    ## Returns: <alarm-information>
    ## Command: "show chassis alarms"
    get_alarm_information => {
    },

    ## Method : <get-environment-information>
    ## Returns: <environment-information>
    ## Command: "show chassis environment"
    get_environment_information => {
    },

    ## Method : <get-firmware-information>
    ## Returns: <firmware-information>
    ## Command: "show chassis firmware"
    get_firmware_information => {
    },

    ## Method : <get-fpc-information>
    ## Returns: <fpc-information>
    ## Command: "show chassis fpc"
    get_fpc_information => {
    },

    ## Method : <get-pic-information>
    ## Returns: <fpc-information>
    ## Command: "show chassis fpc pic-status"
    get_pic_information => {
	slot => $STRING,
    },

    ## Method : <get-pic-detail>
    ## Returns: <pic-information>
    ## Command: "show chassis pic"
    get_pic_detail => {
	fpc_slot => $STRING,
	pic_slot => $STRING,
    },

    ## Method : <get-spmb-information>
    ## Returns: <spmb-information>
    ## Command: "show chassis spmb"
    get_spmb_information => {
    },

    ## Method : <get-sib-information>
    ## Returns: <sib-information>
    ## Command: "show chassis spmb sibs"
    get_sib_information => {
    },

    ## Method : <get-chassis-inventory>
    ## Returns: <chassis-inventory>
    ## Command: "show chassis hardware"
    get_chassis_inventory => {
	detail => $TOGGLE,
	extensive => $TOGGLE,
	frus => $TOGGLE,
    },

    ## Method : <get-route-engine-information>
    ## Returns: <route-engine-information>
    ## Command: "show chassis routing-engine"
    get_route_engine_information => {
	slot => $STRING,
    },

    ## Method : <get-ssb-information>
    ## Returns: <scb-information>
    ## Command: "show chassis ssb"
    get_ssb_information => {
	slot => $STRING,
    },

    ## Method : <get-scb-information>
    ## Returns: <scb-information>
    ## Command: "show chassis scb"
    get_scb_information => $NO_ARGS,

    ## Method : <get-fwdd-information>
    ## Returns: <scb-information>
    ## Command: "show chassis forwarding"
    get_fwdd_information => $NO_ARGS,

    ## Method : <get-sfm-information>
    ## Returns: <scb-information>
    ## Command: "show chassis sfm"
    get_sfm_information => $NO_ARGS,

    ## Method : <get-feb-information>
    ## Returns: <scb-information>
    ## Command: "show chassis feb"
    get_feb_information => $NO_ARGS,

    ## Method : <get-snmp-information>
    ## Returns: <snmp-statistics>
    ## Command: "show snmp statistics"
    get_snmp_information => $NO_ARGS,

    ## Method : <get-rmon-information>
    ## Returns: <rmon-information>
    ## Command: "show snmp rmon"
    get_rmon_information => $NO_ARGS,

    ## Method : <get-rmon-alarm-information>
    ## Returns: <rmon-alarm-information>
    ## Command: "show snmp rmon alarms"
    get_rmon_alarm_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
    },

    ## Method : <get-rmon-event-information>
    ## Returns: <rmon-event-information>
    ## Command: "show snmp rmon events"
    get_rmon_event_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
    },

    ## Method : <get-snmp-v3-information>
    ## Returns: <snmp-v3-information>
    ## Command: "show snmp v3"
    get_snmp_v3_information => $NO_ARGS,

    ## Method : <get-snmp-v3-general-information>
    ## Returns: <snmp-v3-general-information>
    ## Command: "show snmp v3 general"
    get_snmp_v3_general_information => $NO_ARGS,

    ## Method : <get-snmp-v3-group-information>
    ## Returns: <snmp-v3-group-information>
    ## Command: "show snmp v3 groups"
    get_snmp_v3_group_information => $NO_ARGS,

    ## Method : <get-snmp-v3-usm-user-information>
    ## Returns: <snmp-v3-usm-user-information>
    ## Command: "show snmp v3 users"
    get_snmp_v3_usm_user_information => $NO_ARGS,

    ## Method : <get-snmp-v3-access-information>
    ## Returns: <snmp-v3-access-information>
    ## Command: "show snmp v3 access"
    get_snmp_v3_access_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
    },

    ## Method : <get-snmp-v3-community-information>
    ## Returns: <snmp-v3-community-information>
    ## Command: "show snmp v3 community"
    get_snmp_v3_community_information => $NO_ARGS,

    ## Method : <get-snmp-v3-target-information>
    ## Returns: <snmp-v3-target-information>
    ## Command: "show snmp v3 target"
    get_snmp_v3_target_information => $NO_ARGS,

    ## Method : <get-snmp-v3-target-address-information>
    ## Returns: <snmp-v3-target-address-information>
    ## Command: "show snmp v3 target address"
    get_snmp_v3_target_address_information => $NO_ARGS,

    ## Method : <get-snmp-v3-target-parameters-information>
    ## Returns: <snmp-v3-target-parameters-information>
    ## Command: "show snmp v3 target parameters"
    get_snmp_v3_target_parameters_information => $NO_ARGS,

    ## Method : <get-snmp-v3-notify-information>
    ## Returns: <snmp-v3-notify-information>
    ## Command: "show snmp v3 notify"
    get_snmp_v3_notify_information => $NO_ARGS,

    ## Method : <get-snmp-v3-notify-filter-information>
    ## Returns: <snmp-v3-notify-filter-information>
    ## Command: "show snmp v3 notify filter"
    get_snmp_v3_notify_filter_information => $NO_ARGS,

    ## Method : <get-firewall-information>
    ## Returns: <firewall-information>
    ## Command: "show firewall"
    get_firewall_information => {
    },

    ## Method : <get-firewall-counter-information>
    ## Returns: <firewall-counter-information>
    ## Command: "show firewall counter"
    get_firewall_counter_information => {
	countername => $STRING,
	filter => $STRING,
    },

    ## Method : <get-firewall-filter-information>
    ## Returns: <firewall-filter-information>
    ## Command: "show firewall filter"
    get_firewall_filter_information => {
	filtername => $STRING,
	counter => $STRING,
    },

    ## Method : <get-firewall-log-information>
    ## Returns: <firewall-log-information>
    ## Command: "show firewall log"
    get_firewall_log_information => {
	get_firewall_log_detailed_information => $TOGGLE,
	interface => $STRING,
    },

    ## Method : <get-firewall-prefix-action-information>
    ## Returns: <firewall-prefix-action-information>
    ## Command: "show firewall prefix-action-stats"
    get_firewall_prefix_action_information => {
	filter => $STRING,
	prefix_action => $STRING,
	from => $STRING,
	to => $STRING,
    },

    ## Method : <get-cos-information>
    ## Returns: <cos-information>
    ## Command: "show class-of-service"
    get_cos_information => $NO_ARGS,

    ## Method : <get-cos-forwarding-class-information>
    ## Returns: <cos-forwarding-class-information>
    ## Command: "show class-of-service forwarding-class"
    get_cos_forwarding_class_information => $NO_ARGS,

    ## Method : <get-cos-drop-profile-information>
    ## Returns: <cos-drop-profile-information>
    ## Command: "show class-of-service drop-profile"
    get_cos_drop_profile_information => {
	profile_name => $STRING,
    },

    ## Method : <get-cos-adaptive-shaper-information>
    ## Returns: <cos-adaptive-shaper-information>
    ## Command: "show class-of-service adaptive-shaper"
    get_cos_adaptive_shaper_information => {
	adaptive_shaper_name => $STRING,
    },

    ## Method : <get-cos-virtual-channel-information>
    ## Returns: <cos-virtual-channel-information>
    ## Command: "show class-of-service virtual-channel"
    get_cos_virtual_channel_information => {
	virtual_channel_name => $STRING,
    },

    ## Method : <get-cos-virtual-channel-group-information>
    ## Returns: <cos-virtual-channel-group-information>
    ## Command: "show class-of-service virtual-channel-group"
    get_cos_virtual_channel_group_information => {
	virtual_channel_group_name => $STRING,
    },

    ## Method : <get-cos-classifier-information>
    ## Returns: <cos-classifier-information>
    ## Command: "show class-of-service classifier"
    get_cos_classifier_information => {
	name => $STRING,
	type => $STRING,
    },

    ## Method : <get-cos-loss-priority-map-information>
    ## Returns: <cos-loss-priority-map-information>
    ## Command: "show class-of-service loss-priority-map"
    get_cos_loss_priority_map_information => {
	name => $STRING,
	type => $STRING,
    },

    ## Method : <get-cos-rewrite-information>
    ## Returns: <cos-rewrite-information>
    ## Command: "show class-of-service rewrite-rule"
    get_cos_rewrite_information => {
	name => $STRING,
	type => $STRING,
    },

    ## Method : <get-cos-code-point-map-information>
    ## Returns: <cos-code-point-map-information>
    ## Command: "show class-of-service code-point-aliases"
    get_cos_code_point_map_information => {
	dscp => $TOGGLE,
	dscp_ipv6 => $TOGGLE,
	exp => $TOGGLE,
	ieee_802_1 => $TOGGLE,
	inet_precedence => $TOGGLE,
    },

    ## Method : <get-cos-scheduler-map-information>
    ## Returns: <cos-scheduler-map-information>
    ## Command: "show class-of-service scheduler-map"
    get_cos_scheduler_map_information => {
	name => $STRING,
    },

    ## Method : <get-cos-interface-map-information>
    ## Returns: <cos-interface-information>
    ## Command: "show class-of-service interface"
    get_cos_interface_map_information => {
	interface_name => $STRING,
    },

    ## Method : <get-cos-table-information>
    ## Returns: <cos-table-information>
    ## Command: "show class-of-service forwarding-table"
    get_cos_table_information => $NO_ARGS,

    ## Method : <get-cos-classifier-table-information>
    ## Returns: <cos-classifier-table-information>
    ## Command: "show class-of-service forwarding-table classifier"
    get_cos_classifier_table_information => $NO_ARGS,

    ## Method : <get-cos-classifier-table-map-information>
    ## Returns: <cos-classifier-table-map-information>
    ## Command: "show class-of-service forwarding-table classifier mapping"
    get_cos_classifier_table_map_information => $NO_ARGS,

    ## Method : <get-cos-loss-priority-map-table-information>
    ## Returns: <cos-los-priority-map-table-information>
    ## Command: "show class-of-service forwarding-table loss-priority-map"
    get_cos_loss_priority_map_table_information => $NO_ARGS,

    ## Method : <get-cos-loss-priority-map-table-binding-information>
    ## Returns: <cos-loss-priority-map-table-binding-information>
    ## Command: "show class-of-service forwarding-table loss-priority-map mapping"
    get_cos_loss_priority_map_table_binding_information => $NO_ARGS,

    ## Method : <get-cos-scheduler-map-table-information>
    ## Returns: <cos-scheduler-map-table-information>
    ## Command: "show class-of-service forwarding-table scheduler-map"
    get_cos_scheduler_map_table_information => $NO_ARGS,

    ## Method : <get-cos-policer-table-map-information>
    ## Returns: <cos-policer-table-map-information>
    ## Command: "show class-of-service forwarding-table policer"
    get_cos_policer_table_map_information => $NO_ARGS,

    ## Method : <get-cos-shaper-table-map-information>
    ## Returns: <cos-shaper-table-map-information>
    ## Command: "show class-of-service forwarding-table shaper"
    get_cos_shaper_table_map_information => $NO_ARGS,

    ## Method : <get-cos-red-information>
    ## Returns: <cos-red-information>
    ## Command: "show class-of-service forwarding-table drop-profile"
    get_cos_red_information => $NO_ARGS,

    ## Method : <get-cos-rewrite-table-information>
    ## Returns: <cos-rewrite-table-information>
    ## Command: "show class-of-service forwarding-table rewrite-rule"
    get_cos_rewrite_table_information => $NO_ARGS,

    ## Method : <get-cos-rewrite-table-map-information>
    ## Returns: <cos-rewrite-table-map-information>
    ## Command: "show class-of-service forwarding-table rewrite-rule mapping"
    get_cos_rewrite_table_map_information => $NO_ARGS,

    ## Method : <get-cos-fwtab-fabric-scheduler-map-information>
    ## Returns: <cos-fwtab-fabric-scheduler-map-information>
    ## Command: "show class-of-service forwarding-table fabric scheduler-map"
    get_cos_fwtab_fabric_scheduler_map_information => $NO_ARGS,

    ## Method : <get-fabric-queue-information>
    ## Returns: <fabric-queue-information>
    ## Command: "show class-of-service fabric statistics"
    get_fabric_queue_information => {
	destination => $STRING,
	source => $STRING,
	summary => $TOGGLE,
    },

    ## Method : <get-cos-fabric-scheduler-map-information>
    ## Returns: <cos-fabric-scheduler-map-information>
    ## Command: "show class-of-service fabric scheduler-map"
    get_cos_fabric_scheduler_map_information => $NO_ARGS,

    ## Method : <get-service-accounting-information>
    ## Returns: <service-accounting-information>
    ## Command: "show services accounting"
    get_service_accounting_information => $NO_ARGS,

    ## Method : <get-service-accounting-status-information>
    ## Returns: <service-accounting-status-information>
    ## Command: "show services accounting status"
    get_service_accounting_status_information => {
	name => $STRING,
    },

    ## Method : <get-service-accounting-usage-information>
    ## Returns: <service-accounting-usage-information>
    ## Command: "show services accounting usage"
    get_service_accounting_usage_information => {
	name => $STRING,
    },

    ## Method : <get-service-accounting-memory-information>
    ## Returns: <service-accounting-memory-information>
    ## Command: "show services accounting memory"
    get_service_accounting_memory_information => {
	name => $STRING,
    },

    ## Method : <get-service-accounting-flow-information>
    ## Returns: <service-accounting-flow-information>
    ## Command: "show services accounting flow"
    get_service_accounting_flow_information => {
	name => $STRING,
    },

    ## Method : <get-service-accounting-flow-detail>
    ## Returns: <service-accounting-flow-detail>
    ## Command: "show services accounting flow-detail"
    get_service_accounting_flow_detail => {
	name => $STRING,
	limit => $STRING,
	order => $STRING,
	extensive => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
	source_prefix => $STRING,
	destination_prefix => $STRING,
	source_port => $STRING,
	destination_port => $STRING,
	input_snmp_interface_index => $STRING,
	output_snmp_interface_index => $STRING,
	source_as => $STRING,
	destination_as => $STRING,
	tos => $STRING,
	proto => $STRING,
    },

    ## Method : <get-service-accounting-aggregation-information>
    ## Returns: <service-accounting-aggregation-information>
    ## Command: "show services accounting aggregation"
    get_service_accounting_aggregation_information => $NO_ARGS,

    ## Method : <get-service-accounting-aggregation-as-information>
    ## Returns: <service-accounting-aggregation-as-information>
    ## Command: "show services accounting aggregation as"
    get_service_accounting_aggregation_as_information => {
	name => $STRING,
	limit => $STRING,
	order => $STRING,
	extensive => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
	source_as => $STRING,
	destination_as => $STRING,
	input_snmp_interface_index => $STRING,
	output_snmp_interface_index => $STRING,
    },

    ## Method : <get-service-accounting-aggregation-protocol-port-information>
    ## Returns: <service-accounting-aggregation-protocol-port-information>
    ## Command: "show services accounting aggregation protocol-port"
    get_service_accounting_aggregation_protocol_port_information => {
	name => $STRING,
	limit => $STRING,
	order => $STRING,
	extensive => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
	proto => $STRING,
	source_port => $STRING,
	destination_port => $STRING,
    },

    ## Method : <get-service-accounting-aggregation-source-prefix-information>
    ## Returns: <service-accounting-aggregation-source-prefix-information>
    ## Command: "show services accounting aggregation source-prefix"
    get_service_accounting_aggregation_source_prefix_information => {
	name => $STRING,
	limit => $STRING,
	order => $STRING,
	extensive => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
	source_prefix => $STRING,
	source_as => $STRING,
	input_snmp_interface_index => $STRING,
    },

    ## Method : <get-service-accounting-aggregation-destination-prefix-information>
    ## Returns: <service-accounting-aggregation-destination-prefix-information>
    ## Command: "show services accounting aggregation destination-prefix"
    get_service_accounting_aggregation_destination_prefix_information => {
	name => $STRING,
	limit => $STRING,
	order => $STRING,
	extensive => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
	destination_prefix => $STRING,
	destination_as => $STRING,
	output_snmp_interface_index => $STRING,
    },

    ## Method : <get-service-accounting-aggregation-source-destination-prefix-information>
    ## Returns: <service-accounting-aggregation-source-destination-prefix-information>
    ## Command: "show services accounting aggregation source-destination-prefix"
    get_service_accounting_aggregation_source_destination_prefix_information => {
	name => $STRING,
	limit => $STRING,
	order => $STRING,
	extensive => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
	source_prefix => $STRING,
	source_as => $STRING,
	input_snmp_interface_index => $STRING,
	destination_prefix => $STRING,
	destination_as => $STRING,
	output_snmp_interface_index => $STRING,
    },

    ## Method : <get-service-accounting-errors-information>
    ## Returns: <service-accounting-errors-information>
    ## Command: "show services accounting errors"
    get_service_accounting_errors_information => {
	name => $STRING,
    },

    ## Method : <get-packet-distribution-information>
    ## Returns: <packet-distribution-information>
    ## Command: "show services accounting packet-size-distribution"
    get_packet_distribution_information => {
	name => $STRING,
    },

    ## Method : <get-service-set-memory-statistics>
    ## Returns: <service-set-memory-statistics-information>
    ## Command: "show services service-sets memory-usage"
    get_service_set_memory_statistics => {
	service_set => $STRING,
	interface => $STRING,
    },

    ## Method : <get-service-set-cpu-statistics>
    ## Returns: <service-set-cpu-statistics-information>
    ## Command: "show services service-sets cpu-usage"
    get_service_set_cpu_statistics => {
	service_set => $STRING,
	interface => $STRING,
    },

    ## Method : <get-service-nat-pool-information>
    ## Returns: <service-nat-pool-information>
    ## Command: "show services nat pool"
    get_service_nat_pool_information => {
	pool_name => $STRING,
    },

    ## Method : <get-service-sfw-flow-table-information>
    ## Returns: <service-sfw-flow-table-information>
    ## Command: "show services stateful-firewall flows"
    get_service_sfw_flow_table_information => {
	limit => $STRING,
	extensive => $TOGGLE,
	brief => $TOGGLE,
	terse => $TOGGLE,
	source_prefix => $STRING,
	destination_prefix => $STRING,
	source_port => $STRING,
	destination_port => $STRING,
	protocol => $STRING,
	service_set => $STRING,
	interface => $STRING,
	get_service_sfw_flow_count_information => $TOGGLE,
    },

    ## Method : <get-service-sfw-conversation-information>
    ## Returns: <service-sfw-conversation-information>
    ## Command: "show services stateful-firewall conversations"
    get_service_sfw_conversation_information => {
	limit => $STRING,
	extensive => $TOGGLE,
	brief => $TOGGLE,
	terse => $TOGGLE,
	source_prefix => $STRING,
	destination_prefix => $STRING,
	source_port => $STRING,
	destination_port => $STRING,
	protocol => $STRING,
	service_set => $STRING,
	interface => $STRING,
    },

    ## Method : <get-service-ids-source-table-information>
    ## Returns: <service-ids-flow-table-information>
    ## Command: "show services ids source-table"
    get_service_ids_source_table_information => {
	source_prefix => $STRING,
	service_set => $STRING,
	interface => $STRING,
	order => $STRING,
	threshold => $STRING,
	limit => $STRING,
	extensive => $TOGGLE,
	brief => $TOGGLE,
	terse => $TOGGLE,
    },

    ## Method : <get-service-ids-destination-table-information>
    ## Returns: <service-ids-flow-table-information>
    ## Command: "show services ids destination-table"
    get_service_ids_destination_table_information => {
	destination_prefix => $STRING,
	service_set => $STRING,
	interface => $STRING,
	order => $STRING,
	threshold => $STRING,
	limit => $STRING,
	extensive => $TOGGLE,
	brief => $TOGGLE,
	terse => $TOGGLE,
    },

    ## Method : <get-service-ids-pair-table-information>
    ## Returns: <service-ids-flow-table-information>
    ## Command: "show services ids pair-table"
    get_service_ids_pair_table_information => {
	source_prefix => $STRING,
	destination_prefix => $STRING,
	service_set => $STRING,
	interface => $STRING,
	order => $STRING,
	threshold => $STRING,
	limit => $STRING,
	extensive => $TOGGLE,
	brief => $TOGGLE,
	terse => $TOGGLE,
    },

    ## Method : <get-service-identification-statistics-information>
    ## Returns: <service-identification-statistics-information>
    ## Command: "show services service-identification statistics"
    get_service_identification_statistics_information => {
	detail => $TOGGLE,
    },

    ## Method : <get-header-redirect-set-statistics-information>
    ## Returns: <header-redirect-set-statistics-information>
    ## Command: "show services service-identification header-redirect statistics"
    get_header_redirect_set_statistics_information => $NO_ARGS,

    ## Method : <get-uri-redirect-set-statistics-information>
    ## Returns: <uri-redirect-set-statistics-information>
    ## Command: "show services service-identification uri-redirect statistics"
    get_uri_redirect_set_statistics_information => $NO_ARGS,

    ## Method : <get-flow-table-statistics-information>
    ## Returns: <flow-table-statistics-information>
    ## Command: "show services flow-table statistics"
    get_flow_table_statistics_information => {
	detail => $TOGGLE,
    },

    ## Method : <get-l2tp-tunnel-information>
    ## Returns: <service-l2tp-tunnel-information>
    ## Command: "show services l2tp tunnel"
    get_l2tp_tunnel_information => {
	extensive => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	statistics => $TOGGLE,
	tunnel_group => $STRING,
	local_tunnel_id => $STRING,
	interface => $STRING,
	local_gateway => $STRING,
	local_gateway_name => $STRING,
	peer_gateway => $STRING,
	peer_gateway_name => $STRING,
    },

    ## Method : <get-l2tp-session-information>
    ## Returns: <service-l2tp-session-information>
    ## Command: "show services l2tp session"
    get_l2tp_session_information => {
	extensive => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	statistics => $TOGGLE,
	tunnel_group => $STRING,
	local_tunnel_id => $STRING,
	interface => $STRING,
	local_gateway => $STRING,
	local_gateway_name => $STRING,
	peer_gateway => $STRING,
	peer_gateway_name => $STRING,
	local_session_id => $STRING,
	user => $STRING,
    },

    ## Method : <get-l2tp-multilink-information>
    ## Returns: <services-l2tp-multilink-information>
    ## Command: "show services l2tp multilink"
    get_l2tp_multilink_information => {
	extensive => $TOGGLE,
	brief => $TOGGLE,
	detail => $TOGGLE,
	statistics => $TOGGLE,
	bundle_id => $STRING,
    },

    ## Method : <get-l2tp-summary-information>
    ## Returns: <service-l2tp-summary-information>
    ## Command: "show services l2tp summary"
    get_l2tp_summary_information => {
	interface => $STRING,
    },

    ## Method : <get-services-flow-collector-information>
    ## Returns: <services-flow-collector-information>
    ## Command: "show services flow-collector"
    get_services_flow_collector_information => {
	extensive => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
	interface => $STRING,
    },

    ## Method : <get-services-flow-collector-file-information>
    ## Returns: <services-flow-collector-file-information>
    ## Command: "show services flow-collector file"
    get_services_flow_collector_file_information => {
	interface => $STRING,
	extensive => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
    },

    ## Method : <get-services-flow-collector-input-information>
    ## Returns: <services-flow-collector-input-information>
    ## Command: "show services flow-collector input"
    get_services_flow_collector_input_information => {
	interface => $STRING,
	extensive => $TOGGLE,
	detail => $TOGGLE,
	terse => $TOGGLE,
    },

    ## Method : <get-helper-statistics-information>
    ## Returns: <helper-statistics-information>
    ## Command: "show helper statistics"
    get_helper_statistics_information => $NO_ARGS,

    ## Method : <get-passive-monitoring-information>
    ## Returns: <passive-monitoring-information>
    ## Command: "show passive-monitoring"
    get_passive_monitoring_information => $NO_ARGS,

    ## Method : <get-passive-monitoring-usage-information>
    ## Returns: <passive-monitoring-usage-information>
    ## Command: "show passive-monitoring usage"
    get_passive_monitoring_usage_information => {
	interface_name => $STRING,
    },

    ## Method : <get-passive-monitoring-memory-information>
    ## Returns: <passive-monitoring-memory-information>
    ## Command: "show passive-monitoring memory"
    get_passive_monitoring_memory_information => {
	interface_name => $STRING,
    },

    ## Method : <get-passive-monitoring-flow-information>
    ## Returns: <passive-monitoring-flow-information>
    ## Command: "show passive-monitoring flow"
    get_passive_monitoring_flow_information => {
	interface_name => $STRING,
    },

    ## Method : <get-passive-monitoring-error-information>
    ## Returns: <passive-monitoring-error-information>
    ## Command: "show passive-monitoring error"
    get_passive_monitoring_error_information => {
	interface_name => $STRING,
    },

    ## Method : <get-passive-monitoring-status-information>
    ## Returns: <passive-monitoring-status-information>
    ## Command: "show passive-monitoring status"
    get_passive_monitoring_status_information => {
	interface_name => $STRING,
    },

    ## Method : <request-reboot>
    ## Returns: nothing
    ## Command: "request system reboot"
    request_reboot => {
	backup_routing_engine => $TOGGLE,
	at => $STRING,
	in => $STRING,
	message => $STRING,
	media => $STRING,
    },

    ## Method : <request-halt>
    ## Returns: nothing
    ## Command: "request system halt"
    request_halt => {
	at => $STRING,
	in => $STRING,
	message => $STRING,
	media => $STRING,
	both_routing_engines => $TOGGLE,
	backup_routing_engine => $TOGGLE,
    },

    ## Method : <request-snapshot>
    ## Returns: nothing
    ## Command: "request system snapshot"
    request_snapshot => {
	partition => $TOGGLE,
	factory => $TOGGLE,
	as_primary => $TOGGLE,
	media => $STRING,
	swap_size => $STRING,
	config_size => $STRING,
	root_size => $STRING,
	data_size => $STRING,
    },

    ## Method : <request-save-rescue-configuration>
    ## Returns: <rescue-management-results>
    ## Command: "request system configuration rescue save"
    request_save_rescue_configuration => $NO_ARGS,

    ## Method : <request-delete-rescue-configuration>
    ## Returns: <rescue-management-results>
    ## Command: "request system configuration rescue delete"
    request_delete_rescue_configuration => $NO_ARGS,

    ## Method : <request-services-flow-collector-test-file-transfer>
    ## Returns: <flow-collector-test-file-transfer-response>
    ## Command: "request services flow-collector test-file-transfer"
    request_services_flow_collector_test_file_transfer => {
	filename => $STRING,
	channel_zero => $TOGGLE,
	channel_one => $TOGGLE,
	primary => $TOGGLE,
	secondary => $TOGGLE,
	interface => $STRING,
    },

    ## Method : <request-services-flow-collector-destination>
    ## Returns: <flow-collector-destination-response>
    ## Command: "request services flow-collector destination"
    request_services_flow_collector_destination => {
	primary => $TOGGLE,
	secondary => $TOGGLE,
	interface => $STRING,
    },

);
