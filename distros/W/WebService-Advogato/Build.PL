#!/usr/bin/perl -w
#
# $Id: Build.PL,v 1.1 2004/04/04 05:46:21 jaldhar Exp $
#

use strict;
use warnings;
use Module::Build;

# accomodate with CPAN autoinstall
shift(@ARGV) if $ARGV[0] && $ARGV[0] eq 'Build';    

Module::Build->new(
	module_name        => 'WebService::Advogato',
	license            => 'perl',
	dist_version_from  => 'lib/WebService/Advogato.pm',
	dist_author        => 'Jaldhar H. Vyas <jaldhar@braincells.com>',
	requires           => { 'RPC::XML' => '0.53', },
	create_makefile_pl => 'traditional',
	sign => 1,
)->create_build_script;
