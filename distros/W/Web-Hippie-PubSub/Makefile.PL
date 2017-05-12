sub author_tests  { }
sub readme_from   { }
sub auto_set_repository { }

use inc::Module::Install;
perl_version('5.008');
name 'Web-Hippie-PubSub';
all_from 'lib/Web/Hippie/PubSub.pm';
readme_from 'lib/Web/Hippie/PubSub.pm';
build_requires 'Test::More';
test_requires 'Test::Requires';
requires 'Plack';
requires 'AnyMQ' => '0.34';
requires 'JSON';
requires 'Web::Hippie';

auto_include_deps;
auto_set_repository;
WriteAll;
