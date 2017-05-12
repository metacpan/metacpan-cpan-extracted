use 5.006;
use strict;
use warnings;
use inc::Module::Install;

name     'Tk-PlotDataset';
all_from 'lib/Tk/PlotDataset.pm';
author   q{I.T. Dev Ltd. <Contact via website - http://www.itdev.co.uk>};
license  'perl';

perl_version 5.006;

tests_recursive('t');

resources (
   homepage   => 'http://www.itdev.co.uk',
   license    => 'http://dev.perl.org/licenses/',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-PlotDataset',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
   'Test::Pod' => '1.22',
   'Test::Pod::Coverage' => '1.08',
   'Pod::Coverage' => '0.18'
);

requires (
   'Carp' => 0,
   'POSIX' => 0,
   'Tk::Canvas' => 0,
   'Tk::Balloon' => 0
);

recommends (
   'Tk::LineGraphDataset' => 0
);

install_as_cpan;
auto_install;
WriteAll;
