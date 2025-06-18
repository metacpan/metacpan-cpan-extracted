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
		scalar read_file("ext/transport-apis/data/${path}.json") );
	my %ret = (
		name      => $data->{name} =~ s{ *[(][^)]+[)]}{}r,
		license   => $data->{attribution}{license},
		homepage  => $data->{attribution}{homepage},
		languages => $data->{supportedLanguages},
		endpoint  => $data->{options}{endpoint},
		coverage  => {
			area    => $data->{coverage}{realtimeCoverage}{area},
			regions => $data->{coverage}{realtimeCoverage}{region} // []
		},
	);

	my %bitmask_to_product;
	for my $product ( @{ $data->{options}{products} // [] } ) {
		for my $bitmask ( @{ $product->{bitmasks} // [] } ) {
			$bitmask_to_product{$bitmask} = $product;
		}
	}

	my $skipped = 0;
	for my $bit ( 0 .. 15 ) {
		if ( my $p = $bitmask_to_product{ 2**$bit } ) {
			for ( 1 .. $skipped ) {
				push( @{ $ret{productbits} }, [ "_", undef ] );
			}
			if ( $p->{name} ) {
				push( @{ $ret{productbits} }, [ $p->{id}, $p->{name} ] );
			}
			else {
				push( @{ $ret{productbits} }, $p->{id} );
			}
		}
		else {
			$skipped += 1;
		}
	}

	if ( $data->{options}{ext} ) {
		$ret{request}{ext} = $data->{options}{ext};
	}
	if ( $data->{options}{ver} ) {
		$ret{request}{ver} = $data->{options}{ver};
	}
	elsif ( $data->{options}{version} ) {
		$ret{request}{ver} = $data->{options}{version};
	}

	if ( $opt{geoip_lock} ) {
		$ret{geoip_lock} = $opt{geoip_lock};
	}

	if ( $opt{lang} ) {
		$ret{request}{lang} = $opt{lang};
	}
	if ( $opt{ua_string} ) {
		$ret{ua_string} = $opt{ua_string};
	}
	if ( $opt{ver} ) {
		$ret{request}{ver} = $opt{ver};
	}

	return %ret;
}

my %motis_instance = (
	RNV        => { load_instance('de/rnv-motis') },
	transitous => { load_instance('un/transitous') },
);

my $perlobj = Data::Dumper->new( [ \%motis_instance ], ['motis_instance'] );

my $buf = <<'__EOF__';
package Travel::Status::MOTIS::Services;

# vim:readonly
# This module has been automatically generated
# by lib/Travel/Status/MOTIS/Services.pm.PL.
# Do not edit, changes will be lost.

use strict;
use warnings;
use 5.014;
use utf8;

our $VERSION = '0.02';

# Source <https://github.com/public-transport/transport-apis>.
# Many thanks to Jannis R / @derhuerst and all contributors for maintaining
# these resources.

__EOF__

$buf .= 'my ' . $perlobj->Sortkeys(1)->Indent(0)->Dump;

$buf =~ s{\Q\x{d6}\E}{Ö}g;
$buf =~ s{\Q\x{c9}\E}{É}g;
$buf =~ s{\Q\x{f3}\E}{ó}g;
$buf =~ s{\Q\x{f6}\E}{ö}g;
$buf =~ s{\Q\x{fc}\E}{ü}g;

$buf .= <<'__EOF__';

sub get_service_ref {
	return $motis_instance;
}

sub get_service_map {
	return %{$motis_instance};
}

1;
__EOF__

write_file( $ARGV[0], { binmode => ':utf8' }, $buf );
