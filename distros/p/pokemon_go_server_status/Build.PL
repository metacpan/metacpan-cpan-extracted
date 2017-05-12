#!/usr/bin/env perl
use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name        => 'pokemon_go_server_status',
    dist_abstract      => 'Pokemon Go Server Status',
    license            => 'perl',
    dist_author        => 'Ayrat <Ayrat.Salavatovich@analyst.mx>',
    dist_version_from  => 'lib/pokemon_go_server_status.pm',
    script_files       => [ 'bin/pokemon_go_server_status.pl' ],
    configure_require  => { 'Module::Build' => '0.42', },
    requires => {
	'WWW::Mechanize::Timed' => 0.44,
    },
    meta_merge => {
	resources => {
	    repository => 'https://github.com/Ayrat-Salavatovich/pokemon-go-server-status',
	},
    },
 )->create_build_script;
