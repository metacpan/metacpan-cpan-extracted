#!/usr/bin/env perl

use strict;
use warnings;
use 5.014;
use utf8;
use Data::Dumper;
use Encode      qw(encode);
use File::Slurp qw(read_file write_file);
use JSON;

my $json = JSON->new->utf8;

sub load_instance {
	my ( $path, %opt ) = @_;

	my $data = $json->decode(
		scalar read_file("ext/transport-apis/data/${path}-efa.json") );
	my %ret = (
		name      => $opt{name} // $data->{name} =~ s{ *[(][^)]+[)]}{}r,
		homepage  => $data->{attribution}{homepage},
		url       => $opt{url} // $data->{options}{endpoint} =~ s{ / $ }{}rx,
		time_zone => $data->{timezone},
		languages => $data->{supportedLanguages},
		coverage  => {
			area    => $data->{coverage}{realtimeCoverage}{area},
			regions => $data->{coverage}{realtimeCoverage}{region} // []
		},
	);

	return %ret;
}

# GVH: 403
# VRT: Encoding issues
# VVSt: NXDOMAIN
my %efa_instance = (
	BSVG => {
		url  => 'https://bsvg.efa.de/bsvagstd',
		name => 'Braunschweiger Verkehrs-GmbH',
	},
	bwegt => { load_instance('de/bwegt') },
	DING  => {
		url  => 'https://www.ding.eu/ding3',
		name => 'Donau-Iller Nahverkehrsverbund',
	},
	KVV    => { load_instance('de/kvv') },
	LinzAG => {
		url      => 'https://www.linzag.at/static',
		name     => 'Linz AG',
		encoding => 'iso-8859-15',
	},
	MVV  => { load_instance('de/mvv') },
	NVBW => {
		url  => 'https://www.efa-bw.de/nvbw',
		name => 'Nahverkehrsgesellschaft Baden-Württemberg',
	},
	NWL => {
		url  => 'https://westfalenfahrplan.de/nwl-efa',
		name => 'Nahverkehr Westfalen-Lippe',
	},
	Rolph => { load_instance('de/rolph') },
	VAG => {
		url  => 'https://efa.vagfr.de/vagfr3',
		name => 'Freiburger Verkehrs AG',
	},
	VGN =>
	  { load_instance( 'de/vgn', url => 'https://efa.vgn.de/vgnExt_oeffi' ) },
	VMV => { load_instance('de/vmv') },
	VRN => {
		url  => 'https://www.vrn.de/mngvrn/',
		name => 'Verkehrsverbund Rhein-Neckar',
	},
	VRR => {
		load_instance(
			'de/vrr',
			url => 'https://efa.vrr.de/vrr',
		),
	},
	VRR2 => { load_instance('de/vrr') },
	VRR3 => { load_instance( 'de/vrr', url => 'https://efa.vrr.de/rbgstd3' ) },
	VVO  => {
		url  => 'https://efa.vvo-online.de/VMSSL3',
		name => 'Verkehrsverbund Oberelbe',
	},
	VVS => { load_instance('de/vvs') },

);

my $buf = <<'__EOF__';
package Travel::Status::DE::EFA::Services;

# vim:readonly
# This package has been automatically generated
# by lib/Travel/Status/DE/EFA/Services.pm.PL.
# Do not edit, changes will be lost.

use strict;
use warnings;
use 5.014;
use utf8;

our $VERSION = '3.09';

# Most of these have been adapted from
# <https://github.com/public-transport/transport-apis> and
# <https://github.com/public-transport/hafas-client/tree/main/p>.
# Many thanks to Jannis R / @derhuerst and all contributors for maintaining
# these resources.

__EOF__

my $perlobj = Data::Dumper->new( [ \%efa_instance ], ['efa_instance'] );

$buf .= 'my ' . $perlobj->Sortkeys(1)->Indent(0)->Dump;

$buf .= <<'__EOF__';

sub get_service_ids {
	return sort keys %{$efa_instance};
}

sub get_service {
	my ($service) = @_;
	return $efa_instance->{$service};
}

sub get_service_ref {
	return $efa_instance;
}

sub get_service_map {
	return %{$efa_instance};
}

1;
__EOF__

write_file( $ARGV[0], { binmode => ':utf8' }, $buf );
