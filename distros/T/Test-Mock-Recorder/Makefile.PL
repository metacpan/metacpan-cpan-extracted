#! perl
use inc::Module::Install;

name 'Test-Mock-Recorder';
all_from 'lib/Test/Mock/Recorder.pm';

requires 'Test::MockObject' >= 0;
requires 'Class::Accessor::Fast' => 0;
requires 'Data::Compare' => 0;
requires 'Test::Builder' => 0;

test_requires 'Test::More' => 0;

WriteAll;
