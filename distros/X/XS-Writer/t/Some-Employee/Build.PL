#!/usr/bin/perl -w

use Module::Build;

my $build = Module::Build->new(
    module_name     => 'Some::Employee',

    include_dirs    => ['.'],
);
$build->create_build_script;


use XS::Writer;

my $writer = XS::Writer->new(
    package   => 'Some::Employee',
    include   => '#include "employee.h"',
);

$writer->struct(<<'END');
    typedef struct employee {
        char *      name;
        double      salary;
        int         id;
    };
END

$writer->write_xs;
