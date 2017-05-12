use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Test::WWW::Mechanize::LibXML',
    license             => 'mit',
    dist_author         => q{Shlomi Fish <shlomif@insurgentsoftware.com>},
    dist_version_from   => 'lib/Test/WWW/Mechanize/LibXML.pm',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    build_requires =>
    {
        'Test::More' => 0,
    },
    requires =>
    {
        'HTML::TreeBuilder::LibXML' => 0,
        'MRO::Compat' => 0,
        'Test::WWW::Mechanize' => 0,
        'strict' => 0,
        'warnings' => 0,
        'perl' => '5.008',
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Test-WWW-Mechanize-LibXML-*' ],
    create_makefile_pl => 'traditional',
    meta_merge =>
    {
        resources =>
        {
            repository => "https://github.com/shlomif/perl-Test-WWW-Mechanize-LibXML",
        },
    },
);

$builder->create_build_script();
