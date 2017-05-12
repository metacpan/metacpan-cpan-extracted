use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Text::Markup',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.30' },
    build_requires     => {
        'File::Spec::Functions' => 0,
        'Module::Build'         => '0.30',
        'Test::More'            => '0.96',
    },
    requires => {
        'File::BOM'             => '0.14',
        'HTML::Entities'        => 0,
        'HTML::Tagset'          => 0, # Needed by Text::MediawikiFormat
        'IPC::Open3'            => 0,
        'perl'                  => 5.008001,
        'Pod::Simple::XHTML'    => '3.15',
        'Symbol'                => 0,
        'Text::Markdown'        => '1.000004',
        'Text::MultiMarkdown'   => '1.000028',
        'Text::MediawikiFormat' => '1.0',
        'Text::Textile'         => '2.10',
        'Text::Trac'            => '0.10',
        'Parse::BBCode'         => '0.15',
        'Text::WikiCreole'      => '0.07',
    },
    recommends => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Text-Markup/',
            bugtracker => 'http://github.com/theory/text-markup/issues/',
            repository => 'http://github.com/theory/text-markup',
        }
    },
);
$build->add_build_element('py');
$build->create_build_script;
