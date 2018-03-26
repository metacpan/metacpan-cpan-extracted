use strict;
use inc::Module::Install;

name 'Test-PostgreSQL';
all_from 'lib/Test/PostgreSQL.pm';

requires 'File::Spec';
requires 'File::Which';
requires 'DBI';
requires 'DBD::Pg';
requires 'Try::Tiny';
requires 'Function::Parameters';
requires 'Types::Standard';
requires 'Moo';
requires 'POSIX';
requires 'User::pwent';
requires 'Tie::Hash::Method';
test_requires 'DBD::Pg';
test_requires 'Test::SharedFork' => 0.06;

repository 'https://github.com/TJC/Test-postgresql';

license 'artistic_2';

add_metadata x_contributors => [
    'Toby Corkindale',
    'Kazuho Oku',
    'Peter Mottram',
    'Alex Tokarev <tokarev@cpan.org>',
];

WriteAll;
