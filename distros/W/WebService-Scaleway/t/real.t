#!/usr/bin/perl
use strict;
use warnings;

use WebService::Scaleway;

use Test::More;

BEGIN {
	plan skip_all => 't/api_key file missing' unless -f 't/api_key';
	plan tests => 7;
}

open my $akf, '<', 't/api_key';
my $token = <$akf>;
chomp $token;
close $akf;
my $sw = WebService::Scaleway->new($token);

my $org = $sw->organizations;
my $user = $sw->user($org->users->[0]->{id});
note 'This token belongs to ', $user->fullname, ' <', $user->email, '>';

my $ip = $sw->create_ip($org);
note "Created new ip $ip with address ", $ip->address;
is $sw->ip($ip)->address, $ip->address, 'get_ip';
my @ips = $sw->ips;
ok grep ({$_->address eq $ip->address} @ips), 'list_ips';

my $vol = $sw->create_volume('testvol', $org, 'l_ssd', 50_000_000_000);
note "Created new volume $vol with name ", $vol->name;
is $sw->volume($vol)->name, $vol->name, 'get_volume';
my @vols = $sw->volumes;
ok grep ({$_->name eq $vol->name} @vols), 'list_volumes';

my ($debian) = grep { $_->name =~ /debian jessie/i } $sw->images;
my $srv = $sw->create_server('mysrv', $org, $debian, {1 => $vol->id});
note "Created new server $srv with name ", $srv->name;
is $sw->server($srv)->name, $srv->name, 'get_server';
$srv->{name} = 'testsrv';
$sw->update_server($srv);
is $sw->server($srv)->name, $srv->name, 'update_server';
my @srvs = $sw->servers;
ok grep ({$_->name eq $srv->name} @srvs), 'list_servers';
note "This server can: ", join ' ', $sw->server_actions($srv);

## Snapshots are quite expensive
#my $snp = $sw->create_snapshot('mysnap', $org, $vol);
#note "Created new snapshot $snp with name ", $snp->name;
#is $sw->snapshot($snp)->name, $snp->name, 'get_snapshot';
#$snp->{name} = 'testsnap';
#$sw->update_snapshot($snp);
#is $sw->snapshot($snp)->name, $snp->name, 'update_snapshot';

@vols = map { $_->{id} } values %{$srv->volumes};
$sw->delete_server($srv);
$sw->delete_ip($ip);
$sw->delete_volume($_) for @vols;
