use 5.010;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WebService::ReutersConnect',
    license             => 'perl',
    dist_author         => q{Jerome Eteve <jerome@eteve.net>},
    dist_version_from   => 'lib/WebService/ReutersConnect.pm',
    build_requires => {
        'Test::More' => 0, ## perl-modules
        'Test::Fatal' => 0.008, ## libtest-fatal-perl
    },
    share_dir => 'share',
    requires => {
        'perl' => 5.010, ## perl-base
        'DBD::SQLite' => 1.35, ## libdbd-sqlite3-perl
        'DBIx::Class' => 0.08121, ## libdbix-class-perl
        'DateTime' => 0.70, ## libdatetime-perl
        'DateTime::Format::ISO8601' => 0.07, ##  libdatetime-format-iso8601-perl
        'Devel::REPL' => 1.003012, ##  libdevel-repl-perl
        'File::ShareDir' => 0.02, ## libfile-sharedir-perl
        'Getopt::Long' => 2.38, ## perl-base
        'HTTP::Request' => 6.00, ##  libwww-perl
        'HTTP::Response' => 6.01, ##  libwww-perl
        'Log::Log4perl' => 1.29, ##  liblog-log4perl-perl
        'LWP::UserAgent' => 6.03, ## libwww-perl
        'Moose' => 2.0401, ## libmoose-perl
        'Term::ReadKey' => 2.30, ## libterm-readkey-perl
        'URI::Escape' => 3.31, ## liburi-perl
        'XML::LibXML' => 1.89, ## libxml-libxml-perl
    },
    add_to_cleanup      => [ 'WebService-ReutersConnect-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
