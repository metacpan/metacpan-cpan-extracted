# WebService::DigitalOcean

[![Build Status](https://travis-ci.org/andrewalker/p5-webservice-digitalocean.svg?branch=master)](https://travis-ci.org/andrewalker/p5-webservice-digitalocean)

Implements the Perl module for accessing the v2 of the DigitalOcean API.

See main documentation on [MetaCPAN](https://metacpan.org/pod/WebService::DigitalOcean).

Patches welcome!

````perl

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

````
