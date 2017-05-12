#   $Id: Build.PL 99 2014-05-23 12:35:49Z adam $

use 5.010;
use strict;
use Module::Build;

if ($] < 5.0010) {
    print {*STDERR} "\n##########################################",
                    "\n# This module is not supported on Perls  #",
                    "\n# older than 5.10 Patches are welcome.   #",
                    "\n##########################################\n\n";
}

my $build = Module::Build->new(
    module_name => 'XML::RSS::Tools',
    license     => 'lgpl3',
    requires    => {
        'perl'  => '5.10.0',
        'URI'   => '1.58',
        'LWP'   => '6.0',
        'XML::LibXSLT' => '1.70',
        'XML::LibXML'  => '1.70',
        'XML::RSS'     => '1.46'
    },
    configure_requires => {
        'Module::Build'    => '0.4',
    },
    build_requires => {
        'Module::Build'    => '0.4',
        'Pod::Coverage'    => '0.21',
        'URI::file'        => '4.19',
        'Test::Pod'        => '1.0',
        'Test::Warn'       => '0.09',
        'IO::Capture'      => '0.04',
        'YAML'             => '0.60',
    },
);

$build->create_build_script;
