use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Chord::Piano',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/Text/Chord/Piano.pm',
    build_requires      => {
        'Test::More'  => 0.88,
    },
    requires => {
        'perl' => '5.6.2',
        'Carp'                  => 0,
        'Class::Accessor::Fast' => 0,
        'Music::Chord::Note'    => '0.07',
    },
    script_files        => [ 'bin/piano_chord' ],
    add_to_cleanup      => [ 'Text-Chord-Piano-*' ],
);

$builder->create_build_script();
