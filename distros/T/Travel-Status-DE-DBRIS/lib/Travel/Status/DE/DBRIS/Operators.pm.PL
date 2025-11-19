#!/usr/bin/env perl

use strict;
use warnings;
use 5.020;
use utf8;
use File::Slurp qw(read_file write_file);
use JSON;

my $json_str  = read_file('share/admin-id-to-operator.json');
my $adm_to_op = JSON->new->utf8->decode($json_str);

my $buf = <<'EOF';
package Travel::Status::DE::DBRIS::Operators;

# vim:readonly
# This module has been automatically generated from share/admin-id-to-operator.json
# by lib/Travel/Status/DE/DBRIS/Operators.pm.PL.
# Do not edit, changes will be lost.

use strict;
use warnings;
use 5.020;
use utf8;

our $VERSION = '0.18';

# Automatically generated, see share/stations.json
my %admin_id_to_operator = (
EOF

while ( my ( $k, $v ) = each %{$adm_to_op} ) {
	if ( $k =~ m{'} or $v->[0] =~ m{'} or $v->[1] =~ m{'} ) {
		die("Unsupported entry: $k");
	}
	$buf .= sprintf( "'%s' => ['%s', '%s'],\n", $k, @{$v} );
}

$buf .= <<'EOF';
);

sub get_operator {
	my ($id) = @_;
	return $admin_id_to_operator{$id};
}

sub get_operator_abbr {
	my ($id) = @_;
	if (my $op = $admin_id_to_operator{$id}) {
		return $op->[0];
	}
	return;
}

sub get_operator_name {
	my ($id) = @_;
	if (my $op = $admin_id_to_operator{$id}) {
		return $op->[1];
	}
	return;
}

1;
EOF

write_file( $ARGV[0], { binmode => ':utf8' }, $buf );
