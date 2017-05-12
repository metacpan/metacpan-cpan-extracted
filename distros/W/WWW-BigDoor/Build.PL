use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::BigDoor',
    license             => 'restrictive', #FIXME
    dist_author         => 'Alex L. Demidov <alexeydemidov@gmail.com>',
    dist_version_from   => 'lib/WWW/BigDoor.pm',
    requires => {
        'version'            => 0,
        'Class::Accessor'    => 0,
        'Digest::SHA'        => 0,
        'File::Slurp'        => 0,
        'JSON'               => 0,
        'Hook::LexWrap'      => 0,
        'REST::Client'       => 0,
#        'Smart::Comments'    => 0,
#        'Test::Kwalitee'     => 0,
        'Test::MockModule'   => 0,
        'Test::MockObject'   => 0,
        'Test::Most'         => 0,
        'Test::NoWarnings'   => 0,
#        'Test::Perl::Critic' => 0,
        'URI'                => 0,
        'UUID::Tiny'         => 0,
    },
    add_to_cleanup      => [ 'BigDoor-*' ],
);

$builder->create_build_script();
