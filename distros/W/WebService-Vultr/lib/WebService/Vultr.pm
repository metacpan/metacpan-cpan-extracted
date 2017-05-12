    use strict; use warnings;
package WebService::Vultr;
our $VERSION = '0.12';
use Carp;
use LWP::UserAgent;
use LWP::Protocol::https;

# ABSTRACT: Perl bindings for the Vultr API

=head1 B<HTTP Response Codes>

 200	Function successfully executed
 400	Invalid API location. Check the URL that you are using
 403	Invalid or missing API key. Check that your API key is present and matches your assigned key
 405	Invalid HTTP method. Check that the method (POST|GET) matches what the documentation indicates
 500	Internal server error. Try again at a later time
 412	Request failed. Check the response body for a more detailed description

=cut

my $api = 'https://api.vultr.com';

sub new {
	my ($package, $key, $mode) = @_;
    unless (defined $mode) {$mode = 'res'};
    unless ($mode eq 'str') {
        $mode = 'res';
    }

	my $ua = LWP::UserAgent->new;

	my $self = { 
		key => "$key",
		api => "$api",
		ua => $ua,
        mode => "$mode"
	};

	bless $self, $package;
	return $self;
}


=head2 this_get 

Returns the HTTP::Response object as default. If 'str' is used as mode it returns the response string or the resonse status line.

=cut 

sub this_get {
	my ($self, $url) = @_;
	my $res = $self->{ua}->get($url);
    if ($self->{mode} eq 'str') {
	    if ($res->is_success) {
		    if ($res->content =~ /\w+/) {
			    return $res->content;
		    }
		    else {
			    return $res->status_line;
		    }
	    }
	    else {
		    confess $res->status_line
	    }
    }
    else {
        return $res;
    }
}


=head2 this_post 

Returns the HTTP::Response object as default. If 'str' is used as mode it returns the response string or the resonse status line.

=cut 

sub this_post {
	my ($self, $url, $param_ref) = @_;
	my $res = $self->{ua}->post($url, $param_ref);
    if ($self->{mode} eq 'str') {
	    if ($res->is_success) {
		    if ($res->content =~ /\w+/) {
			    return $res->content;
		    }
		    else {
			    return $res->status_line;
		    }
	    }
	    else {
		    confess $res->status_line
	    }
    }
    else {
        return $res;
    }
}

=head1 B<Vultr API methods>

=head2 account_info

GET - account
Retrieve information about the current account 

Example Request:
GET https://api.vultr.com/v1/account/info?api_key=EXAMPLE

Example Response:
{
    "balance": "-5519.11",
    "pending_charges": "57.03",
    "last_payment_date": "2014-07-18 15:31:01",
    "last_payment_amount": "-1.00"
}

Parameters:
No Parameters

=cut

sub account_info {
	my $self = shift;
	my $url = $self->{api} . '/v1/account/info?api_key=' . $self->{key};
	return this_get($self, $url);
}


=head2 os_list 

GET - public
Retrieve a list of available operating systems. If the 'windows' flag is true, a Windows licenses will be included with the instance, which will increase the cost. 

Example Request:
GET https://api.vultr.com/v1/os/list

Example Response:
{
    "127": {
        "OSID": "127",
        "name": "CentOS 6 x64",
        "arch": "x64",
        "family": "centos",
        "windows": false
    },
    "148": {
        "OSID": "148",
        "name": "Ubuntu 12.04 i386",
        "arch": "i386",
        "family": "ubuntu",
        "windows": false
    }
}

Parameters:
No Parameters

=cut

sub os_list {
	my $self = shift;
	my $url = $self->{api} . '/v1/os/list';
	return this_get($self, $url);
}


=head2 iso_list

GET - account
List all ISOs currently available on this account 

Example Request:
GET https://api.vultr.com/v1/iso/list?api_key=EXAMPLE

Example Response:
{
    "24": {
        "ISOID": 24,
        "date_created": "2014-04-01 14:10:09",
        "filename": "CentOS-6.5-x86_64-minimal.iso",
        "size": 9342976,
        "md5sum": "ec0669895a250f803e1709d0402fc411"
    }
}

Parameters:
No Parameters

=cut

sub iso_list {
	my $self = shift;
	my $url = $self->{api} . '/v1/iso/list?api_key=' . $self->{key};
	return this_get($self, $url);
	
}


=head2 plans_list

GET - public
Retrieve a list of all active plans. Plans that are no longer available will not be shown. The 'windows' field is no longer in use, and will always be false. Windows licenses will be automatically added to any plan as necessary. 

Example Request:
GET https://api.vultr.com/v1/plans/list

Example Response:
{
    "1": {
        "VPSPLANID": "1",
        "name": "Starter",
        "vcpu_count": "1",
        "ram": "512",
        "disk": "20",
        "bandwidth": "1",
        "price_per_month": "5.00",
        "windows": false
    },
    "2": {
        "VPSPLANID": "2",
        "name": "Basic",
        "vcpu_count": "1",
        "ram": "1024",
        "disk": "30",
        "bandwidth": "2",
        "price_per_month": "8.00",
        "windows": false
    }
}

Parameters:
No Parameters

=cut

sub plans_list {
	my $self = shift;
	my $url = $self->{api} . '/v1/plans/list';
	return this_get($self, $url);
}


=head2 regions_availability

GET - public
Retrieve a list of the PLANIDs currently available in this location. 

Example Request:
GET https://api.vultr.com/v1/regions/availability?DCID=1
Example Response:
[
    40,
    11,
    45,
    29,
    41,
    61
]
Parameters:
DCID integer Location to check availability of

=cut

sub regions_availability {
	my ($self, $region) = @_;
	my $url = $self->{api} . '/v1/regions/availability?DCID=' . $region;
	return this_get($self, $url);
}


=head2 regions_list

GET - public
Retrieve a list of all active regions. Note that just because a region is listed here, does not mean that there is room for new servers. 

Example Request:
GET https://api.vultr.com/v1/regions/list

Example Response:
{
    "1": {
        "DCID": "1",
        "name": "New Jersey",
        "country": "US",
        "continent": "North America",
        "state": "NJ"
    },
    "2": {
        "DCID": "2",
        "name": "Chicago",
        "country": "US",
        "continent": "North America",
        "state": "IL"
    }
}

Parameters:
No Parameters

=cut

sub regions_list {
	my ($self, $region) = @_;
	my $url = $self->{api} . '/v1/regions/list';
	return this_get($self, $url);
}


=head2 server_bandwidth

GET - account
Get the bandwidth used by a virtual machine 

Example Request:
GET https://api.vultr.com/v1/server/bandwidth?api_key=EXAMPLE&SUBID=576965

Example Response:
{
    "incoming_bytes": [
        [
            "2014-06-10",
            "81072581"
        ],
        [
            "2014-06-11",
            "222387466"
        ],
        [
            "2014-06-12",
            "216885232"
        ],
        [
            "2014-06-13",
            "117262318"
        ]
    ],
    "outgoing_bytes": [
        [
            "2014-06-10",
            "4059610"
        ],
        [
            "2014-06-11",
            "13432380"
        ],
        [
            "2014-06-12",
            "2455005"
        ],
        [
            "2014-06-13",
            "1106963"
        ]
    ]
}

Parameters:
SUBID integer Unique identifier for this subscription.  These can be found using the v1/server/list call.

=cut

sub server_bandwidth {
	my ($self, $subid) = @_;
	my $url = $self->{api} . '/v1/server/bandwidth?api_key=' . $self->{key} . '&SUBID=' . $subid;
	return this_get($self, $url);
}


=head2 server_create

POST - account
Create a new virtual machine. You will start being billed for this immediately. The response only contains the SUBID for the new machine. You should use v1/server/list to poll and wait for the machine to be created (as this does not happen instantly). 

Example Request:
POST https://api.vultr.com/v1/server/create?api_key=APIKEY
DCID=1
VPSPLANID=1
OSID=127

Example Response:
{
    "SUBID": "1312965"
}

Parameters:
DCID integer Location to create this virtual machine in.  See v1/regions/list
VPSPLANID integer Plan to use when creating this virtual machine.  See v1/plans/list
OSID integer Operating system to use.  See v1/os/list
ipxe_chain_url string (optional) If you've selected the 'custom' operating system, this can be set to chainload the specified URL on bootup, via iPXE
ISOID string (optional)  If you've selected the 'custom' operating system, this is the ID of a specific ISO to mount during the deployment
SCRIPTID integer (optional) If you've not selected a 'custom' operating system, this can be the SCRIPTID of a startup script to execute on boot.  See v1/startupscript/list
SNAPSHOTID string (optional) If you've selected the 'snapshot' operating system, this should be the SNAPSHOTID (see v1/snapshot/list) to restore for the initial installation
enable_ipv6 string (optional) 'yes' or 'no'.  If yes, an IPv6 subnet will be assigned to the machine (where available)
enable_private_network string (optional) 'yes' or 'no'. If yes, private networking support will be added to the new server.
label string (optional) This is a text label that will be shown in the control panel
SSHKEYID string (optional) List of SSH keys to apply to this server on install (only valid for Linux/FreeBSD).  See v1/sshkey/list.  Seperate keys with commas
auto_backups string (optional) 'yes' or 'no'.  If yes, automatic backups will be enabled for this server (these have an extra charge associated with them)

=cut

sub server_create {
	my ($self, $param_ref) = @_;
	my $url = $self->{api} . '/v1/server/create?api_key=' . $self->{key};
	return this_post($self, $url, $param_ref);
}


=head2 server_destroy

POST - account
Destroy (delete) a virtual machine. All data will be permanently lost, and the IP address will be released. There is no going back from this call. 

Example Request:
POST https://api.vultr.com/v1/server/destroy?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription.  These can be found using the v1/server/list call.

=cut

sub server_destroy {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/destroy?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_create_ipv4

POST - account
Add a new IPv4 address to a server. You will start being billed for this immediately. The server will be rebooted unless you specify otherwise. You must reboot the server before the IPv4 address can be configured. 

Example Request:
POST https://api.vultr.com/v1/server/create_ipv4?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription. These can be found using the v1/server/list call.
reboot string (optional, default 'yes') 'yes' or 'no'. If yes, the server is rebooted immediately.

=cut

sub server_create_ipv4 {
	my ($self, $param_ref) = @_;
	unless (defined $param_ref->{reboot}) {
		$param_ref->{reboot} = "yes";
	}
	my $url = $self->{api} . '/v1/server/create_ipv4?api_key=' . $self->{key};
	return this_post($self, $url, $param_ref);
}


=head2 server_destroy_ipv4

POST - account
Removes a secondary IPv4 address from a server. Your server will be hard-restarted. We suggest halting the machine gracefully before removing IPs. 

Example Request:
POST https://api.vultr.com/v1/server/destroy_ipv4?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription. These can be found using the v1/server/list call.
ip string IPv4 address to remove.

=cut

sub server_destroy_ipv4 {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/destroy_ipv4?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_halt

POST - account
Halt a virtual machine. This is a hard power off (basically, unplugging the machine). The data on the machine will not be modified, and you will still be billed for the machine. To completely delete a machine, see v1/server/destroy 

Example Request:
POST https://api.vultr.com/v1/server/halt?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription.  These can be found using the v1/server/list call.

=cut

sub server_halt {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/halt?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_label_set

POST - account
Set the label of a virtual machine. 

Example Request:
POST https://api.vultr.com/v1/server/label_set?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription. These can be found using the v1/server/list call.
label string This is a text label that will be shown in the control panel.

=cut

sub server_label_set {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/label_set?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_list

GET - account
 List all active or pending virtual machines on the current account. The 'status' field represents the status of the subscription and will be one of pending|active|suspended|closed. If the status is 'active', you can check 'power_status' to determine if the VPS is powered on or not. The API does not provide any way to determine if the initial installation has completed or not. 

Example Request:
 GET https://api.vultr.com/v1/server/list?api_key=EXAMPLE

Example Response:
{
    "576965": {
        "SUBID": "576965",
        "os": "CentOS 6 x64",
        "ram": "4096 MB",
        "disk": "Virtual 60 GB",
        "main_ip": "123.123.123.123",
        "vcpu_count": "2",
        "location": "New Jersey",
        "DCID": "1",
        "default_password": "nreqnusibni",
        "date_created": "2013-12-19 14:45:41",
        "pending_charges": "46.67",
        "status": "active",
        "cost_per_month": "10.05",
        "current_bandwidth_gb": 131.512,
        "allowed_bandwidth_gb": "1000",
        "netmask_v4": "255.255.255.248",
        "gateway_v4": "123.123.123.1",
        "power_status": "running",
        "VPSPLANID": "28",
        "v6_network": "2001:DB8:1000::",
        "v6_main_ip": "2001:DB8:1000::100",
        "v6_network_size": "64",
        "label": "my new server",
        "internal_ip": "10.99.0.10",
        "kvm_url": "https://my.vultr.com/subs/novnc/api.php?data=eawxFVZw2mXnhGUV",
        "auto_backups": "yes"
    }
}

Parameters:
 SUBID integer (optional) Unique identifier of a subscription. Only the subscription object will be returned.

=cut

sub server_list {
    my ($self, $subid) = @_;
    my $url = $self->{api} . '/v1/server/list?api_key=' . $self->{key};
    if (defined $subid) {
        $url .= "&SUBID=$subid";
    }
    return this_get($self, $url);
}


=head2 server_list_ipv4

GET - account
List the IPv4 information of a virtual machine. IP information is only available for virtual machines in the "active" state. 

Example Request:
GET https://api.vultr.com/v1/server/list_ipv4?api_key=EXAMPLE&SUBID=576965

Example Response:
{
    "576965": [
        {
            "ip": "123.123.123.123",
            "netmask": "255.255.255.248",
            "gateway": "123.123.123.1",
            "type": "main_ip",
            "reverse": "123.123.123.123.example.com"
        },
        {
            "ip": "123.123.123.124",
            "netmask": "255.255.255.248",
            "gateway": "123.123.123.1",
            "type": "secondary_ip",
            "reverse": "123.123.123.124.example.com"
        },
        {
            "ip": "10.99.0.10",
            "netmask": "255.255.0.0",
            "gateway": "",
            "type": "private",
            "reverse": ""
        }
    ]
}

Parameters:
SUBID integer

=cut

sub server_list_ipv4 {
    my ($self, $subid) = @_;
    my $url = $self->{api} . '/v1/server/list_ipv4?api_key=' . $self->{key} . "&SUBID=$subid";
    return this_get($self, $url);
}


=head2 server_list_ipv6

GET - account
List the IPv6 information of a virtual machine. IP information is only available for virtual machines in the "active" state. If the virtual machine does not have IPv6 enabled, then an empty array is returned. 

Example Request:
GET https://api.vultr.com/v1/server/list_ipv6?api_key=EXAMPLE&SUBID=576965

Example Response:
{
    "576965": [
        {
            "ip": "2001:DB8:1000::100",
            "network": "2001:DB8:1000::",
            "network_size": "64",
            "type": "main_ip"
        }
    ]
}

Parameters:
SUBID integer

=cut

sub server_list_ipv6 {
    my ($self, $subid) = @_;
    my $url = $self->{api} . '/v1/server/list_ipv6?api_key=' . $self->{key} . "&SUBID=$subid";
    return this_get($self, $url);
}


=head2 os_change

POST - account
Changes the operating system of a virtual machine. All data will be permanently lost. 

Example Request:
POST https://api.vultr.com/v1/server/os_change?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription. These can be found using the v1/server/list call.
OSID integer Operating system to use. See /v1/server/os_change_list.

=cut

sub server_os_change {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/os_change?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_os_change_list 

GET - account
Retrieves a list of operating systems to which this server can be changed. 

Example Request:
GET https://api.vultr.com/v1/server/os_change_list?api_key=EXAMPLE&SUBID=576965

Example Response:
{
    "127": {
        "OSID": "127",
        "name": "CentOS 6 x64",
        "arch": "x64",
        "family": "centos",
        "windows": false,
        "surcharge": "0.00"
    },
    "148": {
        "OSID": "148",
        "name": "Ubuntu 12.04 i386",
        "arch": "i386",
        "family": "ubuntu",
        "windows": false,
        "surcharge": "0.00"
    }
}

Parameters:
SUBID integer Unique identifier for this subscription. These can be found using the v1/server/list call.

=cut

sub server_os_change_list {
    my ($self, $subid) = @_;
    my $url = $self->{api} . '/v1/server/os_change_list?api_key=' . $self->{key} . "&SUBID=$subid";
    return this_get($self, $url);
}


=head2 server_reboot

POST - account
Reboot a virtual machine. This is a hard reboot (basically, unplugging the machine). 

Example Request:
POST https://api.vultr.com/v1/server/reboot?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription.  These can be found using the v1/server/list call.

=cut

sub server_reboot {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/reboot?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_reinstall

POST - account
Reinstall the operating system on a virtual machine. All data will be permanently lost, but the IP address will remain the same There is no going back from this call. 

Example Request:
POST https://api.vultr.com/v1/server/reinstall?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription.  These can be found using the v1/server/list call.

=cut

sub server_reinstall {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/reinstall?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_restore_backup

POST - account
Restore the specificed backup to the virtual machine. Any data already on the virtual machine will be lost. 

Example Request:
POST https://api.vultr.com/v1/server/restore_backup?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription.  These can be found using the v1/server/list call.
BACKUPID string BACKUPID (see v1/backup/list) to restore to this instance

=cut

sub server_restore_backup {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/restore_backup?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_restore_snapshot

POST - account
Restore the specificed snapshot to the virtual machine. Any data already on the virtual machine will be lost. 

Example Request:
POST https://api.vultr.com/v1/server/restore_snapshot?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription.  These can be found using the v1/server/list call.
SNAPSHOTID string SNAPSHOTID (see v1/snapshot/list) to restore to this instance

=cut

sub server_restore_snapshot {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/restore_snapshot?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_reverse_default_ipv4

POST - account
Set a reverse DNS entry for an IPv4 address of a virtual machine to the original setting. Upon success, DNS changes may take 6-12 hours to become active. 

Example Request:
POST https://api.vultr.com/v1/server/reverse_default_ipv4?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription. These can be found using the v1/server/list call.
ip string IPv4 address used in the reverse DNS update. These can be found with the v1/server/list_ipv4 call.

=cut

sub server_reverse_default_ipv4 {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/reverse_default_ipv4?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_reverse_delete_ipv6

POST - account
Remove a reverse DNS entry for an IPv6 address of a virtual machine. Upon success, DNS changes may take 6-12 hours to become active. 

Example Request:
POST https://api.vultr.com/v1/server/reverse_delete_ipv6?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription. These can be found using the v1/server/list call.
ip string IPv6 address used in the reverse DNS update. These can be found with the v1/server/reverse_list_ipv6 call.

=cut

sub server_reverse_delete_ipv6 {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/reverse_delete_ipv6?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_reverse_list_ipv6

GET - account
List the IPv6 reverse DNS entries of a virtual machine. Reverse DNS entries are only available for virtual machines in the "active" state. If the virtual machine does not have IPv6 enabled, then an empty array is returned. 

Example Request:
GET https://api.vultr.com/v1/server/reverse_list_ipv6?api_key=EXAMPLE&SUBID=576965
Example Response:
{
    "576965": [
        {
            "ip": "2001:DB8:1000::101",
            "reverse": "host1.example.com"
        },
        {
            "ip": "2001:DB8:1000::102",
            "reverse": "host2.example.com"
        }
    ]
}
Parameters:
SUBID integer

=cut

sub server_reverse_list_ipv6 {
    my ($self, $subid) = @_;
    my $url = $self->{api} . '/v1/server/reverse_list_ipv6?api_key=' . $self->{key} . "&SUBID=$subid";
    return this_get($self, $url);
}


=head2 server_reverse_set_ipv4 

POST - account
Set a reverse DNS entry for an IPv4 address of a virtual machine. Upon success, DNS changes may take 6-12 hours to become active. 

Example Request:
POST https://api.vultr.com/v1/server/reverse_set_ipv4?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription. These can be found using the v1/server/list call.
ip string IPv4 address used in the reverse DNS update. These can be found with the v1/server/list_ipv4 call.
entry string reverse DNS entry.

=cut

sub server_reverse_set_ipv4 {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/reverse_set_ipv4?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 server_reverse_set_ipv6

POST - account
Set a reverse DNS entry for an IPv6 address of a virtual machine. Upon success, DNS changes may take 6-12 hours to become active. 

Example Request:
POST https://api.vultr.com/v1/server/reverse_set_ipv6?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription. These can be found using the v1/server/list call.
ip string IPv6 address used in the reverse DNS update. These can be found with the v1/server/list_ipv6 or v1/server/reverse_list_ipv6 calls.
entry string reverse DNS entry.

=cut

sub server_reverse_set_ipv6 {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/reverse_set_ipv6?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head server_start 

POST - account
Start a virtual machine. If the machine is already running, it will be restarted. 

Example Request:
POST https://api.vultr.com/v1/server/start?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SUBID integer Unique identifier for this subscription.  These can be found using the v1/server/list call.

=cut

sub server_start {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/server/reverse_start?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 snapshot_create

POST - account
Create a snapshot from an existing virtual machine. The virtual machine does not need to be stopped. 

Example Request:
POST https://api.vultr.com/v1/snapshot/create?api_key=APIKEY
SUBID=1312965

Example Response:
{
    "SNAPSHOTID": "544e52f31c706"
}

Parameters:
SUBID integer Identifier of the virtual machine to create a snapshot from.  See v1/server/list
description string (optional) Description of snapshot contents

=cut

sub snapshot_create {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/snapshot/create?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 snapshot_destroy

POST - account
Destroy (delete) a snapshot. There is no going back from this call. 

Example Request:
POST https://api.vultr.com/v1/snapshot/destroy?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SNAPSHOTID string Unique identifier for this snapshot.  These can be found using the v1/snapshot/list call.

=cut

sub snapshot_destroy {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/snapshot/destroy?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 snapshot_list

GET - account
List all snapshots on the current account 

Example Request:
GET https://api.vultr.com/v1/snapshot/list?api_key=EXAMPLE

Example Response:
{
    "5359435d28b9a": {
        "SNAPSHOTID": "5359435d28b9a",
        "date_created": "2014-04-18 12:40:40",
        "description": "Test snapshot",
        "size": "42949672960",
        "status": "complete"
    },
    "5359435dc1df3": {
        "SNAPSHOTID": "5359435dc1df3",
        "date_created": "2014-04-22 16:11:46",
        "description": "",
        "size": "10000000",
        "status": "complete"
    }
}

Parameters:
No Parameters

=cut

sub snapshot_list {
    my ($self) = shift;
    my $url = $self->{api} . '/v1/snapshot/list?api_key=' . $self->{key};
    return this_get($self, $url);
}


=head2 sshkey_create

POST - account
Create a new SSH Key 

Example Request:
POST https://api.vultr.com/v1/sshkey/create?api_key=APIKEY
name="test SSH key"
ssh_key="ssh-rsa AA... test@example.com"

Example Response:
{
    "SSHKEYID": "541b4960f23bd"
}

Parameters:
name string Name of the SSH key
ssh_key string SSH public key (in authorized_keys format)

=cut

sub sshkey_create {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/sshkey/create?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 sshkey_destroy

POST - account
Remove a SSH key. Note that this will not remove the key from any machines that already have it. 

Example Request:
POST https://api.vultr.com/v1/sshkey/destroy?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SSHKEYID string Unique identifier for this SSH key.  These can be found using the v1/sshkey/list call.

=cut

sub sshkey_destroy {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/sshkey/destroy?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 sshkey_list

GET - account
List all the SSH keys on the current account 

Example Request:
GET https://api.vultr.com/v1/sshkey/list?api_key=EXAMPLE

Example Response:
{
    "541b4960f23bd": {
        "SSHKEYID": "541b4960f23bd",
        "date_created": null,
        "name": "test",
        "ssh_key": "ssh-rsa AA... test@example.com"
    }
}

Parameters:
No Parameters

=cut

sub sshkey_list {
    my ($self) = shift;
    my $url = $self->{api} . '/v1/sshkey/list?api_key=' . $self->{key};
    return this_get($self, $url);
}


=head sshkey_update

POST - account
Update an existing SSH Key. Note that this will only update newly installed machines (machines installed after the update of the key). The key will not be updated on any existing machines. 

Example Request:
POST https://api.vultr.com/v1/sshkey/update?api_key=APIKEY
SSHKEYID="541b4960f23bd"
name="new key name"
ssh_key="ssh-rsa AA... someother@example.com"

Example Response:
No response, check HTTP result code

Parameters:
SSHKEYID string SSHKEYID of key to update (see /v1/sshkey/list)
name string (optional) New name for the SSH key
ssh_key string (optional) New SSH key contents

=cut

sub sshkey_update {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/sshkey/update?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 startupscript_create

POST - account
Create a startup script 

Example Request:
POST https://api.vultr.com/v1/startupscript/create?api_key=APIKEY
name="my first script"
script="#!/bin/bash\necho hello world > /root/hello"

Example Response:
{
    "SCRIPTID": 5
}

Parameters:
name string Name of the newly created startup script
script string Startup script contents
type string boot|pxe Type of startup script.  Default is 'boot'

=cut

sub startupscript_create {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/startupscript/create?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 startupscript_destroy 

POST - account
Remove a startup script 

Example Request:
POST https://api.vultr.com/v1/startupscript/destroy?api_key=EXAMPLE

Example Response:
No response, check HTTP result code

Parameters:
SCRIPTID string Unique identifier for this startup script.  These can be found using the v1/startupscript/list call.

=cut

sub startupscript_destroy {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/startupscript/destroy?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


=head2 startupscript_list

GET - account
List all startup scripts on the current account. 'boot' type scripts are executed by the server's operating system on the first boot. 'pxe' type scripts are executed by iPXE when the server itself starts up. 

Example Request:
GET https://api.vultr.com/v1/startupscript/list?api_key=EXAMPLE

Example Response:
{
    "3": {
        "SCRIPTID": "3",
        "date_created": "2014-05-21 15:27:18",
        "date_modified": "2014-05-21 15:27:18",
        "name": "test ",
        "type": "boot",
        "script": "#!/bin/bash echo Hello World > /root/hello"
    },
    "5": {
        "SCRIPTID": "5",
        "date_created": "2014-08-22 15:27:18",
        "date_modified": "2014-09-22 15:27:18",
        "name": "test ",
        "type": "pxe",
        "script": "#!ipxe\necho Hello World\nshell"
    }
}

Parameters:
No Parameters

=cut

sub startupscript_list {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/startupscript/list?api_key=' . $self->{key};
    return this_get($self, $url);
}


=head2 startupscript_update 

POST - account
Update an existing startup script 

Example Request:
POST https://api.vultr.com/v1/startupscript/update?api_key=APIKEY
SCRIPTID=5
name="my first script"
script="#!/bin/bash\necho hello world > /root/hello"

Example Response:
No response, check HTTP result code

Parameters:
SCRIPTID integer SCRIPTID of script to update (see /v1/startupscript/list)
name string (optional) New name for the startup script
script string (optional) New startup script contents

=cut

sub startupscript_update {
    my ($self, $param_ref) = @_;
    my $url = $self->{api} . '/v1/startupscript/update?api_key=' . $self->{key};
    return this_post($self, $url, $param_ref);
}


1;