use lib "./buildlib";

use Test::Run::Builder;

use strict;
use warnings;

my $build = Test::Run::Builder->new(
    module_name => "Test::WWW::Mechanize::Mojo",
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    test_requires =>
    {
        'Test::Exception'=> '0',
        'Test::More' => '0',
        'Test::Mojo' => 0,
    },
    requires =>
    {
        'base' => 0,
        'Carp' => 0,
        'Encode' => 0,
        'HTML::Entities'                           => 0,
        'LWP'                                      => '5.816',
        'Mojolicious::Lite' => 0,
        'Mojolicious' => '4.75',
        'perl' => '5.012',
        'strict' => 0,
        'Test::WWW::Mechanize'                     => '1.14',
        'utf8' => 0,
        'warnings' => 0,
        'WWW::Mechanize'                           => '1.50',
    },
    dist_version_from => "lib/Test/WWW/Mechanize/Mojo.pm",
    license => "perl",
    create_makefile_pl => 'traditional',
    meta_merge =>
    {
        resources =>
        {
            repository => "http://bitbucket.org/shlomif/perl-test-www-mechanize-mojo",
            homepage => "http://web-cpan.berlios.de/modules/Test-WWW-Mechanize-Mojo/",
        },
        keywords =>
        [
        ],
    },

);

$build->create_build_script;
