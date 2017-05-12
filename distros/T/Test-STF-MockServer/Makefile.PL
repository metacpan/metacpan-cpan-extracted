use inc::Module::Install;

name 'Test-STF-MockServer';
all_from 'lib/Test/STF/MockServer.pm';

requires 'Class::Accessor::Lite';
requires 'Plack';
requires 'STF::Dispatcher::PSGI';
requires 'Test::TCP';
requires 'URI';

WriteAll;