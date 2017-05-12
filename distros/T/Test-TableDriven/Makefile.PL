use strict;
use warnings;
use inc::Module::Install;

name('Test-TableDriven');
all_from('lib/Test/TableDriven.pm');
requires 'Test::More';
requires 'Data::Dumper';
WriteAll();
