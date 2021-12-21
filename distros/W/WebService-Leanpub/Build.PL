use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup      => [ 'WebService-Leanpub-*' ],
    configure_requires  => { 'Module::Build' => 0.38, },
    create_makefile_pl  => 'small',
    dist_abstract       => 'Access the Leanpub API.',
    dist_author         => 'Mathias Weidner <mamawe@cpan.org>',
    dist_version_from   => 'lib/WebService/Leanpub.pm',
    license             => 'perl',
    meta_merge => {
        resources => {
            repository => 'https://github.com/matwei-perl/WebService-Leanpub',
            bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=WebService-Leanpub',
        }
    },
    module_name         => 'WebService::Leanpub',
    requires => {
	'HTTP::Request::Common'	=> 0,
	'JSON'			=> 0,
	'LWP::UserAgent'	=> 0,
        'Test::More'		=> 0,
	'URI::Escape'		=> 0,
        'version'		=> 0,
    },
    script_files	=> [ 'bin/leanpub', ],
);

$builder->create_build_script();
