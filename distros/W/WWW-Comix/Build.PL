use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
   module_name       => 'WWW::Comix',
   license           => 'perl',
   dist_author       => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   dist_version_from => 'lib/WWW/Comix.pm',
   requires          => {
      'perl'                     => '5.8.0',
      'Test::More'               => 0,
      'version'                  => 0,
      'Moose'                    => 0,
      'Moose::Policy::FollowPBP' => 0,
      'Path::Class'              => 0,
      'WWW::Mechanize'           => 0,
      'Module::Pluggable'        => 0,
      'HTML::Entities'           => 0,
      'List::MoreUtils'          => 0,
      'Readonly'                 => 0,
      'URI'                      => 0,
      'HTML::LinkExtor'          => 0,
   },
   add_to_cleanup => ['WWW-Comix-*'],
);

$builder->create_build_script();
