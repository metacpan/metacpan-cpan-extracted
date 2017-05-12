use strict;
use Module::Build;

Module::Build->new(
    module_name => 'Wx::Perl::BrowseButton',
    license     => 'perl',
    requires    => { 'Wx'         => 0.26,
                     'Test::More' => 0.50,
                     },
)->create_build_script;
