use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Environment',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Test/Environment.pm',
    requires => {
        'Carp::Clan'         => 0,
        'Test::More'         => 0,
        'Test::Differences'  => 0,
        'File::Slurp'        => 0,
        'String::ShellQuote' => 0,
        'File::Basename'     => 0,
        'List::MoreUtils'    => 0,
        'DBI'                => 0,
        'Log::Log4perl'      => 0,
        'APR::Pool'          => 0,
        'APR::Table'         => 0,
        'Class::Accessor::Fast'
                             => 0,
        'IO::String'         => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires  => { 'Module::Build' => 0.38 },
    add_to_cleanup      => [ 'Test-Environment-*' ],
    create_readme       => 1,
);

$builder->create_build_script();
