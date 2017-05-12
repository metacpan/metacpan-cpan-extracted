use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::KnuthPlass',
    license             => 'Perl',
    dist_author         => q{Simon Cozens <simon@cpan.org>},
    dist_version_from   => 'lib/Text/KnuthPlass.pm',
    include_dirs        => ['.'],
    build_requires => {
        'Test::More' => 0,
        'Text::Hyphen' => 0,
        'Class::Accessor' => 0,
    },
    add_to_cleanup      => [ 'Text-KnuthPlass-*' ],
);

$builder->create_build_script();
