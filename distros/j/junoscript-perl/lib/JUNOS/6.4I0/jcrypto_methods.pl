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
# FILE: jcrypto_methods.pl -- generated automagikally; DO NOT EDIT
#

%jcrypto_methods = (
    ## Method : <get-certificates-information>
    ## Returns: <certificates-information>
    ## Command: "show ipsec certificates"
    get_certificates_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
	serial_number => $STRING,
    },

    ## Method : <get-crl-information>
    ## Returns: <crl-information>
    ## Command: "show ipsec certificates crl"
    get_crl_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
	crl_name => $STRING,
    },

    ## Method : <get-security-associations-information>
    ## Returns: <security-associations-information>
    ## Command: "show ipsec security-associations"
    get_security_associations_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
	sa_name => $STRING,
    },

    ## Method : <get-ipsec-tunnel-redundancy-information>
    ## Returns: <ipsec-tunnel-redundancy-information>
    ## Command: "show ipsec redundancy security-associations"
    get_ipsec_tunnel_redundancy_information => {
	security_association_name => $STRING,
    },

    ## Method : <get-ipsec-pic-redundancy-information>
    ## Returns: <ipsec-pic-redundancy-information>
    ## Command: "show ipsec redundancy interface"
    get_ipsec_pic_redundancy_information => {
	interface_name => $STRING,
    },

    ## Method : <get-ike-security-associations-information>
    ## Returns: <ike-security-associations-information>
    ## Command: "show ike security-associations"
    get_ike_security_associations_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
	peer_address => $STRING,
    },

    ## Method : <get-services-security-associations-information>
    ## Returns: <services-security-associations-information>
    ## Command: "show services ipsec-vpn ipsec security-associations"
    get_services_security_associations_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
	extensive => $TOGGLE,
	service_set => $STRING,
    },

    ## Method : <get-services-ipsec-statistics-information>
    ## Returns: <ipsec-total-statistics-information>
    ## Command: "show services ipsec-vpn ipsec statistics"
    get_services_ipsec_statistics_information => {
	remote_gw => $STRING,
	detail => $TOGGLE,
	brief => $TOGGLE,
	service_set => $STRING,
    },

    ## Method : <get-ike-services-security-associations-information>
    ## Returns: <ike-security-associations-information>
    ## Command: "show services ipsec-vpn ike security-associations"
    get_ike_services_security_associations_information => {
	brief => $TOGGLE,
	detail => $TOGGLE,
	peer_address => $STRING,
    },

);
