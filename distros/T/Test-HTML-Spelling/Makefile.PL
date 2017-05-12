use v5.10;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Test-HTML-Spelling';
all_from 'lib/Test/HTML/Spelling.pm';
license  'artistic_2';

perl_version 5.010;

tests_recursive('t');
# tests_recursive('xt');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git://github.com/robrwo/Test-HTML-Spelling.git',
   bugtracker => 'https://github.com/robrwo/Test-HTML-Spelling/issues',
);

configure_requires ();

build_requires (
   'Test::More' => 0,
);

requires (
    'Const::Fast'          => 0,
    'curry'                => 0,
    'Encode'               => 0,
    'HTML::Parser'         => 0,
    'List::Util'           => 0,
    'Moose'                => 0,
    'MooseX::NonMoose'     => 0,
    'namespace::autoclean' => 0,
    'Scalar::Util'         => 0,
    'Search::Tokenizer'    => 0,
    'Test::Builder'        => 0,
    'Text::Aspell'         => 0,
    'version'              => 0.77,
);

test_requires (
    'File::Slurp'	=> 0,
    'Test::Builder::Tester' => 0,
    'Test::Pod::Spelling' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
