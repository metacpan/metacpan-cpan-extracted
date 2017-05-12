use inc::Module::Install;

name     'WKHTMLTOPDF';
all_from 'lib/WKHTMLTOPDF.pm';

requires 'Moose' => 0.60;
requires 'MooseX::Role::Cmd' => 0.06;

auto_install;
WriteAll;
