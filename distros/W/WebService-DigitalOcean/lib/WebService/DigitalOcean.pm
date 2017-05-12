package WebService::DigitalOcean;
# ABSTRACT: Access the DigitalOcean RESTful API (v2)
use Moo;
use Types::Standard qw/Str/;
use LWP::UserAgent;
use JSON ();
use DateTime;
use utf8;

with
    'WebService::DigitalOcean::Role::UserAgent',
    'WebService::DigitalOcean::Role::Domains',
    'WebService::DigitalOcean::Role::DomainRecords',
    'WebService::DigitalOcean::Role::Droplets',
    'WebService::DigitalOcean::Role::DropletActions',
    'WebService::DigitalOcean::Role::Keys',
    'WebService::DigitalOcean::Role::Regions',
    'WebService::DigitalOcean::Role::Sizes',
    'WebService::DigitalOcean::Role::Images';

our $VERSION = '0.026'; # VERSION

has api_base_url => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'https://api.digitalocean.com/v2' }
);

has token => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::DigitalOcean - Access the DigitalOcean RESTful API (v2)

=head1 VERSION

version 0.026

=head1 SYNOPSIS

    use WebService::DigitalOcean;

    my $do = WebService::DigitalOcean->new({ token => $TOKEN });

    ###
    ## Upload your public ssh key
    ###

    open my $fh, '<', $ENV{HOME} . '/.ssh/id_rsa.pub';
    my $key = $do->key_create({
        name       => 'Andre Walker',
        public_key => do { local $/ = <$fh> },
    });
    close $fh;

    ###
    ## Select a random available region to create a droplet
    ###

    my @regions = grep { $_->{available} } @{ $do->region_list->{content} };
    my $random_region = $regions[rand @regions];

    ###
    ## Create droplets!
    ###

    my $droplet1_res = $do->droplet_create({
        name               => 'server1.example.com',
        region             => $random_region->{slug},
        size               => '1gb',
        image              => 'ubuntu-14-04-x64',
        ssh_keys           => [ $key->{content}{fingerprint} ],
    });

    die "Could not create droplet 1" unless $droplet1_res->{is_success};

    my $droplet2_res = $do->droplet_create({
        name               => 'server2.example.com',
        region             => $random_region->{slug},
        size               => '1gb',
        image              => 'ubuntu-14-04-x64',
        ssh_keys           => [ $key->{content}{fingerprint} ],
    });

    die "Could not create droplet 2" unless $droplet2_res->{is_success};

    ###
    ## Create domains
    ###

    my $subdomain1_res = $do->domain_record_create({
        domain => 'example.com',
        type   => 'A',
        name   => 'server1',
        data   => $droplet1_res->{content}{networks}{v4}{ip_address},
    });

    die "Could not create subdomain server1" unless $subdomain1_res->{is_success};

    my $subdomain2_res = $do->domain_create({
        domain => 'example.com',
        type   => 'A',
        name   => 'server2',
        data   => $droplet2_res->{content}{networks}{v4}{ip_address},
    });

    die "Could not create subdomain server2" unless $subdomain2_res->{is_success};

=head1 DESCRIPTION

This module implements DigitalOceans new RESTful API.

=head1 ATTRIBUTES

=head2 api_base_url

A string prepended to all API endpoints. By default, it's
https://api.digitalocean.com/v2. This can be adjusted to facilitate tests.

=head2 token

The authorization token. It can be retrieved by logging into one's DigitalOcean
account, and generating a personal token here:
L<< https://cloud.digitalocean.com/settings/applications >>.

=head1 METHODS

=head2 domain_create

    my $res = $do->domain_create({
        name       => 'example.com',
        ip_address => '12.34.56.78',
    });

B<Arguments:>

=over

=item C<Str> $args{name}

The domain name.

=item C<Str> $args{ip_address}

The IP address the domain will point to.

=back

Creates a new top level domain.

More info: L<< https://developers.digitalocean.com/documentation/v2/#create-a-new-domain >>.

=head2 domain_delete

    $do->domain_delete('example.com');

B<Arguments:>

=over

=item C<Str> $domain

The domain name.

=back

Deletes the specified domain.

More info: L<< https://developers.digitalocean.com/documentation/v2/#delete-a-domain >>.

=head2 domain_get

    my $response = $do->domain_get('example.com');

B<Arguments:>

=over

=item C<Str> $domain

The domain name.

=back

Retrieves the specified domain.

More info: L<< https://developers.digitalocean.com/documentation/v2/#retrieve-an-existing-domain >>.

=head2 domain_list

    my $response = $do->domain_list();

    for (@{ $response->{content} }) {
        say $_->{id};
    }

Lists all domains for this account.

More info: L<< https://developers.digitalocean.com/documentation/v2/#list-all-domains >>.

=head2 domain_record_create

    my $response = $do->domain_record_create({
        domain => 'example.com',
        type   => 'A',
        name   => 'www2',
        data   => '12.34.56.78',
    });

    my $id = $response->{content}{id};

B<Arguments:>

=over

=item C<Str> $args{domain}

The domain under which the record will be created.

=item C<Str> $args{type}

The type of the record (eg MX, CNAME, A, etc).

=item C<Str> $args{name} (optional)

The name of the record.

=item C<Str> $args{data} (optional)

The data (such as the IP address) of the record.

=item C<Int> $args{priority} (optional)

Priority, for MX or SRV records.

=item C<Int> $args{port} (optional)

The port, for SRV records.

=item C<Int> $args{weight} (optional)

The weight, for SRV records.

=back

Creates a new record for a domain.

More info: L<< https://developers.digitalocean.com/documentation/v2/#create-a-new-domain-record >>.

=head2 domain_record_delete

    $do->domain_record_delete({
        domain => 'example.com',
        id     => 1215,
    });

B<Arguments:>

=over

=item C<Str> $args{domain}

The domain to which the record belongs.

=item C<Int> $args{id}

The id of the record.

=back

Deletes the specified record.

More info: L<< https://developers.digitalocean.com/documentation/v2/#delete-a-domain-record >>.

=head2 domain_record_get

    my $response = $do->domain_record_get({
        domain => 'example.com',
        id     => 1215,
    });

    my $ip = $response->{content}{data};

B<Arguments:>

=over

=item C<Str> $args{domain}

The domain to which the record belongs.

=item C<Int> $args{id}

The id of the record.

=back

Retrieves details about a particular record, identified by id.

More info: L<< https://developers.digitalocean.com/documentation/v2/#retrieve-an-existing-domain-record >>.

=head2 domain_record_list

    my $response = $do->domain_record_list('example.com');

    for (@{ $response->{content} }) {
        print "$_->{name} => $_->{data}\n";
    }

B<Arguments:>

=over

=item C<Str> $domain

The domain to which the records belong.

=back

Retrieves all the records for a particular domain.

More info: L<< https://developers.digitalocean.com/documentation/v2/#list-all-domain-records >>.

=head2 droplet_create

    $do->droplet_create(
        name               => "My-Droplet",
        region             => "nyc1",
        size               => "512mb",
        image              => 449676389,
        ssh_keys           => [ 52341234, 215124, 64325534 ],
        backups            => 0,
        ipv6               => 1,
        private_networking => 0,
    );

B<Arguments:>

=over

=item C<Str> $args{name}

=item C<Str> $args{region}

=item C<Str> $args{size}

=item C<Str> $args{image}

=item C<Str> $args{user_data} (optional)

=item C<ArrayRef> $args{ssh_keys} (optional)

=item C<Bool> $args{backups} (optional)

=item C<Bool> $args{ipv6} (optional)

=item C<Bool> $args{private_networking} (optional)

=back

Creates a new droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#create-a-new-droplet >>.

=head2 droplet_delete

    $do->droplet_delete(1250928);

B<Arguments:>

=over

=item C<Int> $id

=back

Deletes the specified droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#delete-a-droplet >>.

=head2 droplet_get

    my $response = $do->droplet_get(15314123);

B<Arguments:>

=over

=item C<Int> $id

=back

Retrieves the specified droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#retrieve-an-existing-droplet-by-id >>.

=head2 droplet_list

    my $response = $do->droplet_list();

    for (@{ $response->{content} }) {
        print $_->{id};
    }

Lists all droplets for this account.

More info: L<< https://developers.digitalocean.com/documentation/v2/#list-all-droplets >>.

=head2 droplet_resize

    $do->droplet_resize({
        droplet => 123456,
        disk    => 1,
        size    => '1gb',
    });

B<Arguments:>

=over

=item C<Int> $args{droplet}

=item C<Bool> $args{disk}

=item C<Str> $args{size}

=back

Resizes a droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#resize-a-droplet >>.

=head2 droplet_change_kernel

    $do->droplet_change_kernel({
        droplet => 123456,
        kernel  => 654321,
    });

B<Arguments:>

=over

=item C<Int> $args{droplet}

=item C<Int> $args{kernel}

=back

Changes the kernel of a droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#change-the-kernel >>.

=head2 droplet_rebuild

    $do->droplet_rebuild({
        droplet => 123456,
        image   => 654321,
    });

B<Arguments:>

=over

=item C<Int> $args{droplet}

=item C<Str> $args{image}

=back

Rebuilds a droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#rebuild-a-droplet >>.

=head2 droplet_restore

    $do->droplet_rebuild({
        droplet => 123456,
        image   => 654321,
    });

B<Arguments:>

=over

=item C<Int> $args{droplet}

=item C<Str> $args{image}

=back

Restores a droplet to an image backup.

More info: L<< https://developers.digitalocean.com/documentation/v2/#restore-a-droplet >>.

=head2 droplet_rename

    $do->droplet_rename({
        droplet => 123456,
        name    => 'new-name',
    });

B<Arguments:>

=over

=item C<Int> $args{droplet}

=item C<Str> $args{name}

=back

Renames a droplet, thus setting the reverse DNS.

More info: L<< https://developers.digitalocean.com/documentation/v2/#rename-a-droplet >>.

=head2 droplet_snapshot

    $do->droplet_rebuild({
        droplet => 123456,
        name    => 'snapshot-name',
    });

B<Arguments:>

=over

=item C<Int> $args{droplet}

=item C<Str> $args{name}

=back

Saves a snapshopt of the droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#rebuild-a-droplet >>.

=head2 droplet_reboot

    $do->droplet_reboot(123456);

B<Arguments:>

=over

=item C<Int> $droplet_id

=back

Reboots droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#reboot-a-droplet >>.

=head2 droplet_power_cycle

    $do->droplet_power_cycle(123456);

B<Arguments:>

=over

=item C<Int> $droplet_id

=back

Power cycles droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#power-cycle-a-droplet >>.

=head2 droplet_power_on

    $do->droplet_power_on(123456);

B<Arguments:>

=over

=item C<Int> $droplet_id

=back

Powers on droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#power-on-a-droplet >>.

=head2 droplet_power_off

    $do->droplet_power_off(123456);

B<Arguments:>

=over

=item C<Int> $droplet_id

=back

Powers off droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#power-off-a-droplet >>.

=head2 droplet_password_reset

    $do->droplet_password_reset(123456);

B<Arguments:>

=over

=item C<Int> $droplet_id

=back

Resets the root password of the droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#password-reset-a-droplet >>.

=head2 droplet_shutdown

    $do->droplet_shutdown(123456);

B<Arguments:>

=over

=item C<Int> $droplet_id

=back

Shuts down a droplet

More info: L<< https://developers.digitalocean.com/documentation/v2/#shutdown-a-droplet >>.

=head2 droplet_enable_ipv6

    $do->droplet_enable_ipv6(123456);

B<Arguments:>

=over

=item C<Int> $droplet_id

=back

Enables IPv6 in a droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#enable-ipv6 >>.

=head2 droplet_enable_private_networking

    $do->droplet_enable_private_networking(123456);

B<Arguments:>

=over

=item C<Int> $droplet_id

=back

Enables private networking for a droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#enable-private-networking >>.

=head2 droplet_disable_backups

    $do->droplet_disable_backups(123456);

B<Arguments:>

=over

=item C<Int> $droplet_id

=back

Disables backups for the droplet.

More info: L<< https://developers.digitalocean.com/documentation/v2/#disable-backups >>.

=head2 droplet_action_get

    $do->droplet_action_get({
        droplet => 123456,
        action  => 53,
    });

B<Arguments:>

=over

=item C<Int> $args{droplet}

=item C<Int> $args{action}

=back

Retrieve details from a specific action.

More info: L<< https://developers.digitalocean.com/documentation/v2/#retrieve-a-droplet-action >>.

=head2 key_create

    my $response = $do->key_create({
        name       => 'my public key',
        public_key => <$public_key_fh>,
    });

B<Arguments:>

=over

=item C<Str> $args{name}

=item C<Str> $args{public_key}

=back

Creates a new ssh key for this account.

More info: L<< https://developers.digitalocean.com/documentation/v2/#create-a-new-key >>.

=head2 key_delete

    $do->key_delete({ id => 146432 });

B<Arguments:>

=over

=item C<Int> $args{id} I<OR>

=item C<Str> $args{fingerprint}

=back

Deletes the specified ssh key.

More info: L<< https://developers.digitalocean.com/documentation/v2/#destroy-a-key >>.

=head2 key_get

    my $response = $do->key_get({ id => 1215 });

B<Arguments:>

=over

=item C<Int> $args{id} I<OR>

=item C<Str> $args{fingerprint}

=back

Retrieves details about a particular ssh key, identified by id or fingerprint (pick one).

More info: L<< https://developers.digitalocean.com/documentation/v2/#retrieve-an-existing-key >>.

=head2 key_list

Retrieves all the keys for this account.

More info: L<< https://developers.digitalocean.com/documentation/v2/#list-all-keys >>.

=head2 region_list

    my $regions = $do->region_list();

    for my $r (@{ $regions->{content} }) {
        if ($r->{available}) {
            say "$r->{name} is available";
        }
    }

Retrieves all the regions available in Digital Ocean.

More info: L<< https://developers.digitalocean.com/documentation/v2/#list-all-regions >>.

=head2 size_list

Retrieves all the sizes available in Digital Ocean.

    my $sizes = $do->size_list();

    for my $s (@{ $sizes->{content} }) {
        say "Size $s->{slug} costs $s->{price_hourly} per hour.";
    }

More info: L<< https://developers.digitalocean.com/documentation/v2/#list-all-sizes >>.

=head2 image_list

Retrieves all the images available in Digital Ocean.

    my $images = $do->image_list();

    for my $i (@{ $images->{content} }) {
        say join "\t", $i->{distribution}, $i->{id}, $i->{name};
    }

More info: L<< https://developers.digitalocean.com/documentation/v2/#list-all-images >>.

=head1 SEE ALSO

=over

=item L<DigitalOcean>

First DigitalOcean module, uses v1 API. It has a more OO
approach than this module, and might have a more stable interface at the
moment.

=item L<< https://developers.digitalocean.com/documentation/v2/ >>

Documentation for API v2, in DigitalOcean's website.

=back

=head1 AUTHOR

André Walker <andre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by André Walker.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
