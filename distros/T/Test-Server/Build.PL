#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Test::Server',
	license             => 'perl',
	dist_author         => 'Jozef Kutej <jozef@kutej.net>',
	dist_version_from   => 'lib/Test/Server.pm',
	build_requires      => {
    },
	requires            => {
		'Test::More'            => 0,
		'Test::Differences'     => 0,
		'Test::Exception'       => 0,
    	'YAML::Syck'            => 0,
    	'Socket'                => 0,
    	'List::MoreUtils'       => 0,
    	'Carp::Clan'            => 0,
    	'Class::Accessor::Fast' => 0,
    	'File::Slurp'           => 0,
	# Sys::Net dependecies
    	'IO::Socket::INET'      => 0,
    },
    recommends          => {
    	'Net::DNS::Resolver'   => 0,
    	'Test::WWW::Mechanize' => 0,
    	'Proc::ProcessTable'   => 0,
    	'Net::NTP'             => 0,
    	'Time::HiRes'          => 0,
    	'Filesys::DiskSpace'   => 0,
    	'Filesys::DiskUsage'   => 0,
    },
    add_to_cleanup      => [ 'Test-Server-*' ],
    create_makefile_pl  => 'traditional',
    sign                => 1,
    create_readme       => 1,
);

=cut    

    server_testing_files => {
		'examples/01_hostname-and-interfaces.t' => '01_hostname-and-interfaces.t',
		'examples/01_running-processes.t'       => '01_running-processes.t',
		'examples/02_disk-free.t'               => '02_disk-free.t',
		'examples/02_dns-resolution.t'          => '02_dns-resolution.t',
		'examples/02_resolv.conf.t'             => '02_resolv.conf.t',
		'examples/02_time-sync.t'               => '02_time-sync.t',
		'examples/03_cmd-output.t'              => '03_cmd-output.t',
		'examples/03_find-huge-files.t'         => '03_find-huge-files.t',
		'examples/03_folder-file.t'             => '03_folder-file.t',
		'examples/03_open-ports.t'              => '03_open-ports.t',
		'examples/03_sites-ok.t'                => '03_sites-ok.t',
	},
	
	install_path => {
		'server_testing' => '/etc/t',
	}

=cut

$builder->create_build_script();
