#!/usr/bin/env perl

use inc::Module::Install 0.75;

name 'Vitacilina';
all_from 'lib/Vitacilina.pm';

requires 'XML::Feed' => '0.41';
requires 'URI' => '0';
requires 'Template' => '0';
requires 'YAML::Syck' => '0';
requires 'Data::Dumper' => '0';
requires 'LWP::UserAgent' => '0';
requires 'DateTime' => '0';
build_requires 'Test::More' => '0';

no_index directory => 'examples';
# license_from 'LICENSE';

repository 'http://github.com/damog/vitacilina/tree';

WriteAll;
