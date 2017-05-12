use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::RobotRules::DBIC',
    license             => 'perl',
    dist_author         => 'Tomohiro IKEBE <ikebe@shebang.jp>',
    dist_version_from   => 'lib/WWW/RobotRules/DBIC.pm',
    requires => {
        'Test::More' => 0,
        'DBIx::Class' => 0.07,
        'WWW::RobotRules' => 1.33,
    },
    add_to_cleanup      => [ 'WWW-RobotRules-DBIC-*' ],
);

$builder->create_build_script();
