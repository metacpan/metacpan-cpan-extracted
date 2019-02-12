use inc::Module::Install;

all_from 'lib/Test/TCM/Role/API.pm';
repository 'https://github.com/ichesnokov/p5-test-tcm-role-api';

requires 'HTTP::Message'     => 0;
requires 'JSON'              => 0;
requires 'Moose'             => 0;
requires 'Plack::Test'       => 0;
requires 'Test::Deep'        => 0;
requires 'Test::Differences' => 0;
requires 'Test::More'        => 0;

WriteAll(meta => 1);
