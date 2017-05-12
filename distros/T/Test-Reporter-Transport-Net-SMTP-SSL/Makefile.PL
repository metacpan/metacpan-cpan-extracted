use inc::Module::Install;

name     'Test-Reporter-Transport-Net-SMTP-SSL';
all_from 'lib/Test/Reporter/Transport/Net/SMTP/SSL.pm';
author   q{Theodore Robert Campbell Jr <trcjr@cpan.org>};
license  'perl';

version_from 'lib/Test/Reporter/Transport/Net/SMTP/SSL.pm';

build_requires 'Test::More';
build_requires 'Test::Reporter';
build_requires 'Net::SMTP::SSL';

auto_install;

WriteAll;

