use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Blog::Metadata::Language',
    license             => 'perl',
    dist_author         => 'Darko Obradovic <dobradovic@gmx.de>',
    dist_version_from   => 'lib/WWW/Blog/Metadata/Language.pm',
    requires => {
        'Test::More'            => 0,
        'version'               => 0,
		'WWW::Blog::Metadata'   => 0,
		'Text::Language::Guess' => 0,
    },
    add_to_cleanup      => [ 'WWW-Blog-Metadata-Language-*' ],
);

$builder->create_build_script();
