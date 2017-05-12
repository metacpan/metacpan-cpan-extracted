use inc::Module::Install;

name     'Tree-Navigator';
all_from 'lib/Tree/Navigator.pm';
author   q{Laurent Dami <dami@cpan.org>};
license  'perl';

requires 'namespace::autoclean';
requires 'Alien::GvaScript';
requires 'DBI';
requires 'DBIx::DataModel';
requires 'Devel::StackTrace::WithLexicals';
requires 'Devel::StackTrace::AsHTML';
requires 'Devel::Symdump';
requires 'HTTP::Date';
requires 'List::MoreUtils';
requires 'List::Util';
requires 'Moose';
requires 'MooseX::NonMoose';
requires 'MooseX::Params::Validate';
requires 'Params::Validate';
requires 'Plack' => 1.0004;
requires 'Plack::Component';
requires 'Plack::MIME';
requires 'Plack::Request';
requires 'Plack::Util';
requires 'Scalar::Util';
requires 'Template';
requires 'URI::Escape';
# requires 'Win32API::Registry';

build_requires 'Test::More';

auto_install;

WriteAll;

