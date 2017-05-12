#!/usr/bin/perl
# $Id: Build.PL,v 1.4 2003/04/08 01:12:23 cwest Exp $
use strict;
$^W = 1;
use Module::Build;

Module::Build->new(
	dist_name         => 'poest',
	dist_version_from => 'bin/poest',
	dist_version      => do { # for pre releases only
		my @l  = localtime;
		$l[5] += 1900;
		$l[4]++;
		sprintf "0.%4d%02d%02d", @l[5,4,3];
	},
	license           => 'perl',
	requires          => {
		'perl'                         => '5.5.3',
		'POE'                          => '0.25',
		'POE::Component::Server::SMTP' => 1.4,
		'POE::Session::MultiDispatch'  => 0,
	},
	recommends        => {
		'Config::General'              => 0,
	},
	build_requires    => {
		'Test::More'                   => 0,
	},
	scripts                            => [ qw[
		bin/poest
	] ],
	PL_files          => { qw[bin/poest.PL bin/poest] },
	sign              => 1,
)->create_build_script;

print "Gengerating bin/poest from bin/poest.PL\n";
system($^X, 'bin/poest.PL');
