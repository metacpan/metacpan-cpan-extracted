#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name       => 'VM-EC2',
    license           => 'perl',
    dist_version_from => 'lib/VM/EC2.pm',
    dist_author       => 'Lincoln Stein <lincoln.stein@oicr.on.ca>',
    configure_requires => { 'Module::Build' => 0 },
    requires          => {
      'LWP' => 5.835,
      'MIME::Base64' => '3.08',
      'Digest::SHA'  => '5.47',
      'URI::URL'     => '5.03',
      'XML::Simple'  => '2.18',
      'File::Path'   => '2.08',
      'String::Approx' => '3.26',
      'JSON'         => 0,
      'AnyEvent'     => '7.04',
      'AnyEvent::HTTP' => '2.15',
      'AnyEvent::CacheDNS' => '0.08',
    },
    recommends => {
	'AWS::Signature4' => '1.00',
    },
    build_class        => 'Module::Build',
    );


$build->create_build_script;
exit 0;
