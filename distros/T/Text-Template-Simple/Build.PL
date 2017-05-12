#!/usr/bin/env perl
# This file was created automatically
use 5.006;
use strict;
use warnings;
use lib qw( builder/lib );
use Build;
my $mb = Build->new;

$mb->copyright_first_year( 2004 );
$mb->monolith_add_to_top( [ qw( Constants.pm Util.pm ) ] );
$mb->build_monolith( 1 );
$mb->change_versions( 1 );
$mb->add_pod_author_copyright_license( 1 );
$mb->taint_mode_tests( 1 );

$mb->create_build_script;

1;
