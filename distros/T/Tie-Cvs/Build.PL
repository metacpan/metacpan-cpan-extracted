#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;
use Config::AutoConf;

my $builder = Module::Build->new
  (
   license => 'perl',
   module_name => 'Tie::Cvs',
   dist_author => 'Alberto Simoes <ambs@cpan.org>',
   configure_requires => {
                      'Config::AutoConf' => '0.16',
                      'Module::Build' => '0.42',
                     },
   test_requires => {
                'File::Temp' => 0,
                'Test::More' => 0,
               },
   add_to_cleanup => [ 'Tie-Cvs-*' ],
  );


my $cvs = Config::AutoConf->check_progs("cvs");

unless ($cvs) {
    print STDERR "No cvs compatible binary available\n";
    exit 0;
}

$builder->config_data("cvs" => $cvs);

$builder->create_build_script;
