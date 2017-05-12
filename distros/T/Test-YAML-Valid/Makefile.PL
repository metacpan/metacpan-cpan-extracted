use strict;
use warnings;
use inc::Module::Install;

name('Test-YAML-Valid');
author('Jonathan Rockway <jrockway@cpan.org>');
version_from('lib/Test/YAML/Valid.pm');
abstract_from('lib/Test/YAML/Valid.pm');
license('Perl');
include('ExtUtils::AutoInstall');

requires('YAML' => '0.60');
requires('Exporter');
requires('Test::Builder');

build_requires('Test::More');
build_requires('Test::Builder::Tester');
build_requires('File::Spec');

feature('YAML::Syck' => ['YAML::Syck' => '0.60']);
feature('YAML::XS' => ['YAML::XS' => 0]);
feature('YAML::Tiny' => ['YAML::Tiny' => 0]);

auto_install();
WriteAll();
