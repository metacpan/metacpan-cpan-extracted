#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;
use Config::AutoConf;

my $builder = Module::Build->new
  (
   license => 'perl',
   module_name => 'Tie::Ispell',
   dist_author => 'Alberto Simoes <ambs@cpan.org>',
   configure_requires => {
                      'Config::AutoConf' => '0.16',
                     },
   requires => {
                'Test::More' => 0,
               },
   add_to_cleanup => [ 'Tie-Ispell-*' ],
  );


my $ispell = Config::AutoConf->check_progs("ispell", "aspell", "hunspell");

unless ($ispell) {
    print STDERR "No ispell compatible binary available\n";
    exit 0;
}

$builder->config_data("ispell" => $ispell);

$builder->create_build_script;
