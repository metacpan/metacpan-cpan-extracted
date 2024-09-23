use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Text::CSV::Track',
    license            => 'perl',
    dist_author        => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from  => 'lib/Text/CSV/Track.pm',
    configure_requires => {'Module::Build' => '0.3607',},
    requires           => {
    	'Class::Accessor::Fast' => 0,
		'Text::CSV_XS'          => 0,
		'Carp::Clan'            => 0,
		'List::MoreUtils'       => 0,
		'IO::Handle'            => 0,
		'File::Slurp'           => 0,
    },
    build_requires => {
        'File::Temp'       => 0,
    },
    add_to_cleanup => ['Text-CSV-Track-*'],
    create_readme  => 1,
    meta_merge     => {
        resources => {
            repository => 'https://github.com/jozef/perl-Text-CSV-Track',
            bugtracker => 'https://github.com/jozef/perl-Text-CSV-Track/issues',
        },
        keywords => [qw/ csv /],
    },
);

$builder->create_build_script();
