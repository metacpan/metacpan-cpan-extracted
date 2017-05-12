use strict;
use lib 't', 'inc';
use Test::More tests => 1;
use onlyTemplate;
use onlyTest;
use Cwd;
use File::Spec;

my $cwd = File::Spec->rel2abs(cwd);
write_template('config.pm.template',
               't/lib/only/config.pm',
               {VERSIONLIB => File::Spec->catdir($cwd, 't', 'version')},
              );
ok(-f File::Spec->catfile(qw(t lib only config.pm)));

create_distributions
{
    '_Foo-Bar' =>
    {
        '0.50' =>
        {
            '_Foo::Bar' => '0.50',
        },
        '0.55' =>
        {
            '_Foo::Bar' => ['0.50', 'use _Foo::Baz;'],
            '_Foo::Baz' => '0.55',
        },
        '0.60' =>
        {
            '_Foo::Bar' => '0.60',
            '_Foo::Baz' => '0.60',
        },
        '1.00' =>
        {
            '_Foo::Bar' => '1.00',
            '_Foo::Baz' => '0.98',
        },
    },
};

