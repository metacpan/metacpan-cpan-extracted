package WWW::Hetzner;

# ABSTRACT: Perl client for Hetzner APIs (Cloud, Storage, Robot)

use Moo;
use WWW::Hetzner::Cloud;
use WWW::Hetzner::Storage;
use WWW::Hetzner::Robot;
use namespace::clean;

our $VERSION = '0.101';


has cloud => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Cloud->new },
);


has robot => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Robot->new },
);


has storage => (
    is      => 'lazy',
    builder => sub { WWW::Hetzner::Storage->new },
);



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner - Perl client for Hetzner APIs (Cloud, Storage, Robot)

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    # Cloud API (Cloud Servers, DNS)
    use WWW::Hetzner::Cloud;

    my $cloud = WWW::Hetzner::Cloud->new(
        token => $ENV{HETZNER_API_TOKEN},
    );

    my $servers = $cloud->servers->list;
    my $server = $cloud->servers->create(
        name        => 'my-server',
        server_type => 'cx22',
        image       => 'debian-12',
    );

    my $zones = $cloud->zones->list;
    my $zone = $cloud->zones->create(name => 'example.com');
    $zone->rrsets->add_a('www', '1.2.3.4');

    # Robot API (Dedicated Servers)
    use WWW::Hetzner::Robot;

    my $robot = WWW::Hetzner::Robot->new(
        user     => $ENV{HETZNER_ROBOT_USER},
        password => $ENV{HETZNER_ROBOT_PASSWORD},
    );

    my $dedicated = $robot->servers->list;
    $robot->reset->software(123456);  # Reset server

=head1 DESCRIPTION

WWW::Hetzner provides a unified interface to Hetzner's various APIs:

=over 4

=item * B<Cloud API> (L<WWW::Hetzner::Cloud>) - api.hetzner.cloud

=item * B<Robot API> (L<WWW::Hetzner::Robot>) - robot-ws.your-server.de (Dedicated servers)

=item * B<Hetzner API> (L<WWW::Hetzner::Storage>) - api.hetzner.com (Storage Boxes)

=back

B<Note:> The old standalone DNS API (dns.hetzner.com) no longer exists.
DNS is now part of the Cloud API.

=head2 cloud

Returns a L<WWW::Hetzner::Cloud> instance for the Cloud API.

=head2 robot

Returns a L<WWW::Hetzner::Robot> instance for the Robot API.

=head2 storage

Returns a L<WWW::Hetzner::Storage> instance for the Storage Box API.

=head1 CLOUD API CLASSES

=head2 Main Client

=over 4

=item * L<WWW::Hetzner::Cloud> - Main client class

=item * L<WWW::Hetzner::Role::HTTP> - HTTP client role (shared by all API clients)

=back

=head2 API Classes (Controllers)

=over 4

=item * L<WWW::Hetzner::Cloud::API::Actions> - Async job (Action) lookup

=item * L<WWW::Hetzner::Cloud::API::Servers> - Server management

=item * L<WWW::Hetzner::Cloud::API::SSHKeys> - SSH key management

=item * L<WWW::Hetzner::Cloud::API::Volumes> - Volume management

=item * L<WWW::Hetzner::Cloud::API::Networks> - Network management

=item * L<WWW::Hetzner::Cloud::API::Firewalls> - Firewall management

=item * L<WWW::Hetzner::Cloud::API::FloatingIPs> - Floating IP management

=item * L<WWW::Hetzner::Cloud::API::PrimaryIPs> - Primary IP management

=item * L<WWW::Hetzner::Cloud::API::LoadBalancers> - Load balancer management

=item * L<WWW::Hetzner::Cloud::API::LoadBalancerTypes> - Load balancer types (read-only)

=item * L<WWW::Hetzner::Cloud::API::Certificates> - TLS certificate management

=item * L<WWW::Hetzner::Cloud::API::PlacementGroups> - Placement group management

=item * L<WWW::Hetzner::Cloud::API::Zones> - DNS zone management

=item * L<WWW::Hetzner::Cloud::API::RRSets> - DNS record management

=item * L<WWW::Hetzner::Cloud::API::Images> - OS images (read-only)

=item * L<WWW::Hetzner::Cloud::API::ISOs> - ISO images (read-only)

=item * L<WWW::Hetzner::Cloud::API::ServerTypes> - Server types (read-only)

=item * L<WWW::Hetzner::Cloud::API::Locations> - Locations (read-only)

=item * L<WWW::Hetzner::Cloud::API::Datacenters> - Datacenters (read-only)

=item * L<WWW::Hetzner::Cloud::API::Pricing> - Current price list (read-only, C<get> only)

=back

=head2 Entity Classes (Models)

=over 4

=item * L<WWW::Hetzner::Action> - Async job object returned by mutating calls

=item * L<WWW::Hetzner::Cloud::Server> - Server object

=item * L<WWW::Hetzner::Cloud::SSHKey> - SSH key object

=item * L<WWW::Hetzner::Cloud::Volume> - Volume object

=item * L<WWW::Hetzner::Cloud::Network> - Network object

=item * L<WWW::Hetzner::Cloud::Firewall> - Firewall object

=item * L<WWW::Hetzner::Cloud::FloatingIP> - Floating IP object

=item * L<WWW::Hetzner::Cloud::PrimaryIP> - Primary IP object

=item * L<WWW::Hetzner::Cloud::LoadBalancer> - Load balancer object

=item * L<WWW::Hetzner::Cloud::LoadBalancerType> - Load balancer type object

=item * L<WWW::Hetzner::Cloud::Certificate> - Certificate object

=item * L<WWW::Hetzner::Cloud::PlacementGroup> - Placement group object

=item * L<WWW::Hetzner::Cloud::Zone> - DNS zone object

=item * L<WWW::Hetzner::Cloud::RRSet> - DNS record object

=item * L<WWW::Hetzner::Cloud::Image> - Image object

=item * L<WWW::Hetzner::Cloud::ISO> - ISO object

=item * L<WWW::Hetzner::Cloud::ServerType> - Server type object

=item * L<WWW::Hetzner::Cloud::Location> - Location object

=item * L<WWW::Hetzner::Cloud::Datacenter> - Datacenter object

=item * L<WWW::Hetzner::Cloud::Pricing> - Price list object

=back

=head2 Roles

=over 4

=item * L<WWW::Hetzner::Role::HasActions> - Controller role wrapping raw action hashes as L<WWW::Hetzner::Action> objects

=item * L<WWW::Hetzner::Role::HasAction> - Entity role exposing the Action a create call returned

=back

=head1 SERVERS API

    $cloud->servers->list
    $cloud->servers->list_by_label($selector)
    $cloud->servers->get($id)
    $cloud->servers->create(%params)
    $cloud->servers->update($id, %params)
    $cloud->servers->delete($id)
    $cloud->servers->power_on($id)
    $cloud->servers->power_off($id)
    $cloud->servers->shutdown($id)
    $cloud->servers->reboot($id)
    $cloud->servers->rebuild($id, $image)
    $cloud->servers->change_type($id, $type, %opts)
    $cloud->servers->wait_for_status($id, $status, $timeout)

Server objects:

    $server->id
    $server->name
    $server->status
    $server->ipv4
    $server->ipv6
    $server->server_type
    $server->datacenter
    $server->location
    $server->image
    $server->labels
    $server->is_running
    $server->is_off
    $server->update
    $server->delete
    $server->power_on
    $server->power_off
    $server->shutdown
    $server->reboot
    $server->rebuild($image)
    $server->refresh

=head1 SSH KEYS API

    $cloud->ssh_keys->list
    $cloud->ssh_keys->get($id)
    $cloud->ssh_keys->get_by_name($name)
    $cloud->ssh_keys->create(%params)
    $cloud->ssh_keys->update($id, %params)
    $cloud->ssh_keys->delete($id)
    $cloud->ssh_keys->ensure($name, $public_key)

SSH key objects:

    $key->id
    $key->name
    $key->public_key
    $key->fingerprint
    $key->labels
    $key->update
    $key->delete

=head1 DNS ZONES API

    $cloud->zones->list
    $cloud->zones->list_by_label($selector)
    $cloud->zones->get($id)
    $cloud->zones->create(%params)
    $cloud->zones->update($id, %params)
    $cloud->zones->delete($id)
    $cloud->zones->export($id)
    $cloud->zones->rrsets($zone_id)

Zone objects:

    $zone->id
    $zone->name
    $zone->ttl
    $zone->labels
    $zone->rrsets
    $zone->update
    $zone->delete
    $zone->export

=head1 DNS RECORDS API

    $zone->rrsets->list
    $zone->rrsets->get($name, $type)
    $zone->rrsets->create(%params)
    $zone->rrsets->update($name, $type, %params)
    $zone->rrsets->delete($name, $type)
    $zone->rrsets->add_a($name, $ip, %opts)
    $zone->rrsets->add_aaaa($name, $ip, %opts)
    $zone->rrsets->add_cname($name, $target, %opts)
    $zone->rrsets->add_mx($name, $mailserver, $priority, %opts)
    $zone->rrsets->add_txt($name, $value, %opts)

RRSet objects:

    $record->name
    $record->type
    $record->ttl
    $record->records
    $record->values
    $record->update
    $record->delete

=head1 VOLUMES API

    $cloud->volumes->list
    $cloud->volumes->get($id)
    $cloud->volumes->create(%params)
    $cloud->volumes->update($id, %params)
    $cloud->volumes->delete($id)
    $cloud->volumes->attach($volume_id, $server_id)
    $cloud->volumes->detach($volume_id)
    $cloud->volumes->resize($volume_id, $size)

Volume objects:

    $volume->id
    $volume->name
    $volume->size
    $volume->server
    $volume->location
    $volume->status
    $volume->labels
    $volume->update
    $volume->delete
    $volume->attach($server_id)
    $volume->detach
    $volume->resize($size)

See L<WWW::Hetzner::Cloud::API::Volumes>, L<WWW::Hetzner::Cloud::Volume>

=head1 NETWORKS API

    $cloud->networks->list
    $cloud->networks->get($id)
    $cloud->networks->create(name => 'mynet', ip_range => '10.0.0.0/8')
    $cloud->networks->update($id, %params)
    $cloud->networks->delete($id)
    $cloud->networks->add_subnet($network_id, %params)
    $cloud->networks->add_route($network_id, %params)
    $cloud->networks->delete_subnet($network_id, $subnet_id)
    $cloud->networks->delete_route($network_id, $route_id)

Network objects:

    $network->id
    $network->name
    $network->ip_range
    $network->subnets
    $network->routes
    $network->servers
    $network->labels
    $network->update
    $network->delete
    $network->add_subnet(%params)
    $network->add_route(%params)

See L<WWW::Hetzner::Cloud::API::Networks>, L<WWW::Hetzner::Cloud::Network>

=head1 FIREWALLS API

    $cloud->firewalls->list
    $cloud->firewalls->get($id)
    $cloud->firewalls->create(name => 'web-fw')
    $cloud->firewalls->update($id, %params)
    $cloud->firewalls->delete($id)
    $cloud->firewalls->add_rule($firewall_id, %params)
    $cloud->firewalls->remove_rule($firewall_id, %params)
    $cloud->firewalls->apply_to($firewall_id, %params)
    $cloud->firewalls->remove_from($firewall_id, %params)

Firewall objects:

    $firewall->id
    $firewall->name
    $firewall->rules
    $firewall->applied_to
    $firewall->labels
    $firewall->update
    $firewall->delete
    $firewall->add_rule(%params)
    $firewall->apply_to(%params)

See L<WWW::Hetzner::Cloud::API::Firewalls>, L<WWW::Hetzner::Cloud::Firewall>

=head1 FLOATING IPS API

    $cloud->floating_ips->list
    $cloud->floating_ips->get($id)
    $cloud->floating_ips->create(%params)
    $cloud->floating_ips->update($id, %params)
    $cloud->floating_ips->delete($id)
    $cloud->floating_ips->assign($ip_id, $server_id)
    $cloud->floating_ips->unassign($ip_id)

Floating IP objects:

    $ip->id
    $ip->name
    $ip->ip
    $ip->type
    $ip->server
    $ip->home_location
    $ip->labels
    $ip->update
    $ip->delete
    $ip->assign($server_id)
    $ip->unassign

See L<WWW::Hetzner::Cloud::API::FloatingIPs>, L<WWW::Hetzner::Cloud::FloatingIP>

=head1 PRIMARY IPS API

    $cloud->primary_ips->list
    $cloud->primary_ips->get($id)
    $cloud->primary_ips->create(%params)
    $cloud->primary_ips->update($id, %params)
    $cloud->primary_ips->delete($id)
    $cloud->primary_ips->assign($ip_id, $assignee_id)
    $cloud->primary_ips->unassign($ip_id)

Primary IP objects:

    $ip->id
    $ip->name
    $ip->ip
    $ip->type
    $ip->assignee_id
    $ip->assignee_type
    $ip->datacenter
    $ip->labels
    $ip->update
    $ip->delete
    $ip->assign($assignee_id)
    $ip->unassign

See L<WWW::Hetzner::Cloud::API::PrimaryIPs>, L<WWW::Hetzner::Cloud::PrimaryIP>

=head1 LOAD BALANCERS API

    $cloud->load_balancers->list
    $cloud->load_balancers->get($id)
    $cloud->load_balancers->create(%params)
    $cloud->load_balancers->update($id, %params)
    $cloud->load_balancers->delete($id)
    $cloud->load_balancers->add_target($lb_id, %params)
    $cloud->load_balancers->remove_target($lb_id, %params)
    $cloud->load_balancers->add_service($lb_id, %params)
    $cloud->load_balancers->remove_service($lb_id, $service)

Load Balancer objects:

    $lb->id
    $lb->name
    $lb->public_net
    $lb->private_net
    $lb->location
    $lb->load_balancer_type
    $lb->targets
    $lb->services
    $lb->labels
    $lb->update
    $lb->delete
    $lb->add_target(%params)
    $lb->add_service(%params)

See L<WWW::Hetzner::Cloud::API::LoadBalancers>, L<WWW::Hetzner::Cloud::LoadBalancer>

=head1 CERTIFICATES API

    $cloud->certificates->list
    $cloud->certificates->get($id)
    $cloud->certificates->create(%params)
    $cloud->certificates->update($id, %params)
    $cloud->certificates->delete($id)

Certificate objects:

    $cert->id
    $cert->name
    $cert->type
    $cert->certificate
    $cert->domain_names
    $cert->fingerprint
    $cert->not_valid_before
    $cert->not_valid_after
    $cert->labels
    $cert->update
    $cert->delete

See L<WWW::Hetzner::Cloud::API::Certificates>, L<WWW::Hetzner::Cloud::Certificate>

=head1 PLACEMENT GROUPS API

    $cloud->placement_groups->list
    $cloud->placement_groups->get($id)
    $cloud->placement_groups->create(name => 'pg', type => 'spread')
    $cloud->placement_groups->update($id, %params)
    $cloud->placement_groups->delete($id)

Placement Group objects:

    $pg->id
    $pg->name
    $pg->type
    $pg->servers
    $pg->labels
    $pg->update
    $pg->delete

See L<WWW::Hetzner::Cloud::API::PlacementGroups>, L<WWW::Hetzner::Cloud::PlacementGroup>

=head1 READ-ONLY APIs

    # Images
    $cloud->images->list
    $cloud->images->get($id)

    # ISOs
    $cloud->isos->list
    $cloud->isos->list(architecture => 'arm')
    $cloud->isos->get($id)
    $cloud->isos->get_by_name('netboot.xyz.iso')

    # Server Types
    $cloud->server_types->list
    $cloud->server_types->get($id)

    # Load Balancer Types
    $cloud->load_balancer_types->list
    $cloud->load_balancer_types->get($id)
    $cloud->load_balancer_types->get_by_name('lb11')

    # Locations
    $cloud->locations->list
    $cloud->locations->get($id)

    # Datacenters
    $cloud->datacenters->list
    $cloud->datacenters->get($id)

    # Pricing - a single object, so no list and no lookup by id
    $cloud->pricing->get

See L<WWW::Hetzner::Cloud::API::ISOs>, L<WWW::Hetzner::Cloud::API::LoadBalancerTypes>,
L<WWW::Hetzner::Cloud::API::Pricing>

=head1 STORAGE BOX API

    my $storage = WWW::Hetzner->new->storage;

    my $boxes = $storage->storage_boxes->list;       # one API page
    my $all   = $storage->storage_boxes->list_all;   # every page
    my $box   = $storage->storage_boxes->get($id);

    my $created = $storage->storage_boxes->create(
        name             => 'my-box',
        location         => 'fsn1',
        storage_box_type => 'bx20',
        password         => 'secret',
    );
    my $action = $created->action;

C<list> preserves the Storage API's single-page response. C<list_all>, from
L<WWW::Hetzner::Role::Pagination>, follows pagination metadata without changing
the supplied filters. It is available on Storage Boxes, Storage Box Types, and
both global and Storage-Box-bound action controllers; subaccount and snapshot
lists are not paginated by the API.

Storage Box objects expose C<subaccounts>, C<snapshots>, and C<actions>
controllers bound to their own ID. Storage actions always refresh through the
global C</storage_boxes/actions/{id}> endpoint.

=over 4

=item * L<WWW::Hetzner::Storage> - Storage Box client

=item * L<WWW::Hetzner::Storage::API::StorageBoxes> - Storage Box controller

=item * L<WWW::Hetzner::Storage::API::StorageBoxTypes> - Storage Box Type controller

=item * L<WWW::Hetzner::Storage::API::Actions> - Storage action controller

=item * L<WWW::Hetzner::Storage::API::Subaccounts> - Nested subaccount controller

=item * L<WWW::Hetzner::Storage::API::Snapshots> - Nested snapshot controller

=item * L<WWW::Hetzner::Storage::StorageBox> - Storage Box entity

=item * L<WWW::Hetzner::Storage::StorageBoxType> - Storage Box Type entity

=item * L<WWW::Hetzner::Storage::Subaccount> - Subaccount entity

=item * L<WWW::Hetzner::Storage::Snapshot> - Snapshot entity

=item * L<WWW::Hetzner::Role::Pagination> - Shared paginated-list helper

=back

=head1 ROBOT API (Dedicated Servers)

    use WWW::Hetzner::Robot;

    my $robot = WWW::Hetzner::Robot->new(
        user     => $ENV{HETZNER_ROBOT_USER},
        password => $ENV{HETZNER_ROBOT_PASSWORD},
    );

=head2 Robot API Classes

=over 4

=item * L<WWW::Hetzner::Robot> - Main client class

=item * L<WWW::Hetzner::Robot::API::Servers> - Server management

=item * L<WWW::Hetzner::Robot::API::Keys> - SSH key management

=item * L<WWW::Hetzner::Robot::API::IPs> - IP address management

=item * L<WWW::Hetzner::Robot::API::Reset> - Server reset and WOL

=item * L<WWW::Hetzner::Robot::API::Traffic> - Traffic statistics

=item * L<WWW::Hetzner::Robot::API::Boot> - Boot configuration (rescue system, installations)

=item * L<WWW::Hetzner::Robot::API::RDNS> - Reverse DNS entries

=item * L<WWW::Hetzner::Robot::API::Failover> - Failover IP routing

=back

=head2 Robot Entity Classes

=over 4

=item * L<WWW::Hetzner::Robot::Server> - Server object

=item * L<WWW::Hetzner::Robot::Key> - SSH key object

=item * L<WWW::Hetzner::Robot::IP> - IP address object

=item * L<WWW::Hetzner::Robot::RDNS> - Reverse DNS entry object

=item * L<WWW::Hetzner::Robot::Failover> - Failover IP object

=back

=head2 Robot Servers

    $robot->servers->list
    $robot->servers->get($server_number)
    $robot->servers->update($server_number, %params)

Server objects:

    $server->server_number
    $server->server_name
    $server->server_ip
    $server->product
    $server->dc
    $server->status
    $server->reset($type)
    $server->update
    $server->refresh

=head2 Robot SSH Keys

    $robot->keys->list
    $robot->keys->get($fingerprint)
    $robot->keys->create(name => 'key', data => 'ssh-ed25519 ...')
    $robot->keys->delete($fingerprint)

=head2 Robot IPs

    $robot->ips->list
    $robot->ips->get($ip_address)

IP objects:

    $ip->ip
    $ip->server_number
    $ip->server_ip
    $ip->locked
    $ip->separate_mac
    $ip->traffic_warnings
    $ip->traffic_hourly
    $ip->traffic_daily
    $ip->traffic_monthly
    $ip->update

=head2 Robot Reset and WOL

    $robot->reset->get($server_number)
    $robot->reset->execute($server_number, 'sw')  # software reset
    $robot->reset->execute($server_number, 'hw')  # hardware reset
    $robot->reset->execute($server_number, 'man') # manual reset
    $robot->reset->software($server_number)
    $robot->reset->hardware($server_number)
    $robot->reset->wol($server_number)            # wake-on-lan

=head2 Robot Traffic

    $robot->traffic->query(
        type => 'day',                            # day, month, year
        from => '2024-01-01T00',
        to   => '2024-01-02T00',
        ip   => '1.2.3.4',                        # or an arrayref of IPs
    )

See L<WWW::Hetzner::Robot::API::Traffic>

=head2 Robot Boot Configuration

    $robot->boot->get($server_number)             # status of all four options

    $robot->boot->rescue($server_number)
    $robot->boot->enable_rescue($server_number, os => 'linux')
    $robot->boot->disable_rescue($server_number)

    $robot->boot->linux($server_number)
    $robot->boot->enable_linux($server_number, dist => 'Debian 12 minimal', lang => 'en')
    $robot->boot->disable_linux($server_number)

    $robot->boot->vnc($server_number)
    $robot->boot->enable_vnc($server_number, dist => 'centOS-5.0', lang => 'en_US')
    $robot->boot->disable_vnc($server_number)

    $robot->boot->windows($server_number)
    $robot->boot->enable_windows($server_number, os => '...', lang => 'en')
    $robot->boot->disable_windows($server_number)

Boot options are per-server state rather than entities, so these return raw
hashrefs. The generated root C<password> is only in the response of the
activating call. Activating an option does not reboot the server - a reset
does.

See L<WWW::Hetzner::Robot::API::Boot>

=head2 Robot Reverse DNS

    $robot->rdns->list
    $robot->rdns->get($ip_address)
    $robot->rdns->create($ip_address, 'mail.example.com')
    $robot->rdns->update($ip_address, 'www.example.com')
    $robot->rdns->delete($ip_address)

RDNS objects:

    $entry->ip
    $entry->ptr
    $entry->ptr('mail.example.com')               # set, then write it back
    $entry->update
    $entry->delete

See L<WWW::Hetzner::Robot::API::RDNS>, L<WWW::Hetzner::Robot::RDNS>

=head2 Robot Failover IPs

    $robot->failover->list
    $robot->failover->get($failover_ip)
    $robot->failover->switch($failover_ip, $target_server_ip)
    $robot->failover->delete($failover_ip)

Failover objects:

    $failover->ip
    $failover->netmask
    $failover->server_ip
    $failover->server_ipv6_net
    $failover->server_number
    $failover->active_server_ip
    $failover->switch($target_server_ip)
    $failover->delete

C<delete> drops the routing, not the IP itself. Hetzner rate limits switching
to 50 requests per hour - a failover switch is not a health check.

See L<WWW::Hetzner::Robot::API::Failover>, L<WWW::Hetzner::Robot::Failover>

=head1 HTTP TRANSPORT

Both clients build their requests with L<WWW::Hetzner::Role::HTTP> and hand
them to a pluggable IO backend, so the same request and response objects
serve the synchronous client, the asynchronous L<Net::Async::Hetzner> and the
test harness.

    my $cloud = WWW::Hetzner::Cloud->new(
        token => $ENV{HETZNER_API_TOKEN},
        io    => My::CustomIO->new,
    );

=over 4

=item * L<WWW::Hetzner::Role::HTTP> - Builds requests, parses responses, holds the C<io> attribute

=item * L<WWW::Hetzner::Role::IO> - Interface role a backend consumes; requires C<call($req)>

=item * L<WWW::Hetzner::LWPIO> - Default synchronous backend (L<LWP::UserAgent>)

=item * L<WWW::Hetzner::HTTPRequest> - Transport independent request object

=item * L<WWW::Hetzner::HTTPResponse> - Transport independent response object

=back

=head1 LOGGING

Uses L<Log::Any> for flexible logging. See L<WWW::Hetzner::Cloud/LOGGING>.

    use Log::Any::Adapter ('Stderr', log_level => 'debug');

=head1 CLI

=head2 hcloud.pl - Cloud CLI

1:1 replica of the official C<hcloud> CLI from Hetzner:

    hcloud.pl server list
    hcloud.pl server create --name test --type cx22 --image debian-12
    hcloud.pl zone list
    hcloud.pl ssh-key list
    hcloud.pl iso
    hcloud.pl load-balancer-type
    hcloud.pl pricing

L<WWW::Hetzner::CLI> lists every command. Subcommands whose call returns an
Action wait for it to finish unless C<--no-wait> is given, see
L<WWW::Hetzner::CLI::Role::WaitsForAction>.

=head2 hrobot.pl - Robot CLI

CLI for dedicated server management:

    hrobot.pl server list
    hrobot.pl server describe 123456
    hrobot.pl key list
    hrobot.pl reset 123456 --type sw
    hrobot.pl wol 123456
    hrobot.pl boot 123456
    hrobot.pl boot rescue 123456 --enable --os linux
    hrobot.pl rdns 203.0.113.50 --ptr mail.example.com
    hrobot.pl failover 203.0.113.60 --to 198.51.100.10

L<WWW::Hetzner::Robot::CLI> lists every command.

=head1 SEE ALSO

=over 4

=item * L<https://docs.hetzner.cloud/> - Cloud API documentation

=item * L<https://docs.hetzner.com/> - Hetzner API documentation

=item * L<https://robot.hetzner.com/doc/webservice/en.html> - Robot API documentation

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
