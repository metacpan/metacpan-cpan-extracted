use strict;
use warnings;
use utf8;
use Test::More;

use Test::Requires::Scanner;

my $content = do {
    local $/;
    <DATA>
};

my $ret = Test::Requires::Scanner->scan_string($content);

is_deeply $ret, {
    'DBI'               => undef,
    'App::RunCron'      => undef,
    'Puncheur'          => undef,
    'Riji'              => '1.0.0',
    'DBIx::Schema::DSL' => '0.05',
    'Config::PL'        => undef,
    'Config::Env'       => undef,
};

done_testing;

__DATA__
use strict
use warnings;
use Test::More 0.98
use Test::Requires 'DBI', 'App::RunCron';
use Test::Requires 0.07 qw/Puncheur Riji/;
use Test::Requires {
    'DBIx::Schema::DSL' => '0.05',
    'Riji'              => '1.0.0',
};
use Test::Requires ('Config::PL', 'Config::Env');
use Test::Requires::Dummy ('Config::Dummy');

pass;
ok 1;

done_testing;
