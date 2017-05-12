use 5.006;
use strict;
use warnings;
use Module::Build::Pluggable qw(
    ReadmeMarkdownFromPod
    Repository
);

my $builder = Module::Build::Pluggable->new(
    module_name       => 'WebService::Pushover',
    license           => 'perl',
    dist_author       => 'Steve Huff <shuff@cpan.org>',
    dist_version_from => 'lib/WebService/Pushover.pm',
    requires => {
        'perl'                                 => 5.008,
        'version'                              => 0,
        'DateTime'                             => 0,
        'DateTime::Format::Strptime'           => 0,
        'File::Spec'                           => 0,
        'Moo'                                  => 0,
        'WebService::Simple'                   => 0,
        'WebService::Simple::Parser::JSON'     => 0,
        'Params::Validate'                     => 0,
        'Readonly'                             => 0,
        'URI'                                  => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'JSON'                => 0,
        'Test::Deep'          => 0,
        'Test::Fake::HTTPD'   => 0,
        'Test::More'          => 0,
    },
    meta_merge => {
        resources => {
            homepage   => 'http://github.com/hakamadare/webservice-pushover/',
            bugtracker => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Pushover',
        },
    },
    add_to_cleanup     => [ 'WebService-Pushover-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
