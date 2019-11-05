use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'dbedia::blob',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'lib/dbedia/blob.pm',

    build_requires => {'Test::Most' => 0,},
    requires       => {
        'Moose'                      => 0,
        'MooseX::Types::Path::Class' => 0,
        'MooseX::Types::URI'         => 0,
        'namespace::autoclean'       => 0,
        'Digest::SHA'                => 0,
        'URI'                        => 0,
        'Path::Class'                => 0,
        'YAML::Syck'                 => 0,
        'File::MimeInfo'             => 0,
        'File::MimeInfo::Magic'      => 0,
        'Net::SCP'                   => 0,
        'File::Temp'                 => 0,
    },
    configure_requires => {'Module::Build' => '0.38'},
    script_files       => ['bin/dbedia-blob',],
    add_to_cleanup     => ['dbedia-blob-*'],
    create_readme      => 1,
    meta_merge         => {
        resources => {
            repository => 'http://github.com/meon/dbedia-blob/',
            bugtracker => 'http://github.com/meon/dbedia-blob/issues',
        },
        keywords => [qw/ perl blob server /],
    },
);

$builder->create_build_script();
