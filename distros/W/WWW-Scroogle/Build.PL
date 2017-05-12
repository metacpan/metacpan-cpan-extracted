use strict;
use warnings;
require 5.006001;
use Module::Build;

my $build = Module::Build->new(
     create_makefile_pl => 'traditional',
     license            => 'perl',
     module_name        => 'WWW::Scroogle',
     dist_author        => 'Lars Hartmann',
     requires           => {
                            'perl'      => '5.6.1',
                            'Carp'      => 0,
                            'strict'    => 0,
                            'warnings'  => 0,
                            'LWP'       => 5.808,
                           },
     build_requires     => {
                            'Test::More'=> 0,
                           },
     create_readme      => 0,
     sign               => 1,
);
$build->create_build_script;
