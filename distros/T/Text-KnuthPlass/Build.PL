use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::KnuthPlass',
    license             => 'Perl',
    dist_author         => q{Phil Perry},
    dist_version_from   => 'lib/Text/KnuthPlass.pm',
    include_dirs        => ['.'],
    build_requires => {
        'Test::More' => 0,  # for t-test
        'Text::Hyphen' => 0,
        'Class::Accessor' => 0,
	'JSON::Syck' => 0,  # for t-test
    },
    add_to_cleanup      => [ 'Text-KnuthPlass-*' ],
    meta_merge => {
        resources      => {
	    'repository' => 'https://github.com/PhilterPaper/Text-KnuthPlass',
	    'bugtracker' => 'https://github.com/PhilterPaper/Text-KnuthPlass/issues',
	    'homepage'   => 'https://metacpan.org/pod/Text::KnuthPlass',
        },
    },
);

$builder->create_build_script();
