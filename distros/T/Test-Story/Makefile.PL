#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'Test-Story';
all_from 'lib/Test/Story.pm';

requires 'Test::FITesque' => '0.03';
requires 'Test::Deep'     => 0;
requires 'Moose'          => '0.33';
requires 'File::Find'     => 0;
requires 'YAML'           => 0;
requires 'Module::Load'   => 0;
requires 'Pod::Usage'     => 0;
requires 'File::Find'     => 0;
requires 'Test::Builder'  => 0;
requires 'Test::More'     => 0;
requires 'WWW::Selenium'  => 0;

install_script glob('script/*');
WriteAll;
