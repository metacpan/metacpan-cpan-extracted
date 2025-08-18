#!/usr/bin/env perl
use Module::Build;

my $home = $ENV{HOME};

my $build = Module::Build->new(
    module_name       => 'Wiki::JSON',
    license           => 'gpl_3',
    dist_version_from => 'lib/Wiki/JSON.pm',
    dist_author       => 'Sergio Iglesias <contact@owlcode.tech>',
    dist_abstract     =>
      'Parse wiki-like articles to a data-structure transformable to JSON.',
    requires => {
        'Module::Build'    => 0,
        'Moo'              => 0,
        'Data::Dumper'     => 0,
        'Test::Most'       => 0,
        'Cpanel::JSON::XS' => 0,
        'Path::Tiny'       => 0,
        'Const::Fast'      => 0,
        'perl'             => 'v5.16.3',
    },
    meta_add => {
        resources => {
            bugtracker => {
                web => 'https://github.com/sergiotarxz/Perl-Wiki-JSON/issues',
                mailto => 'sergioxz@cpan.org',
            },
            repository => {
                url  => 'git://github.com/sergiotarxz/Perl-Wiki-JSON.git',
                web  => 'https://github.com/sergiotarxz/Perl-Wiki-JSON',
                type => 'git',
            },
        }
    },
    script_files => [ 'scripts/wiki2json', ]
);
$build->create_build_script;
