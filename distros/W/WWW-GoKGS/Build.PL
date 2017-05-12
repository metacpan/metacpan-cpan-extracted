use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license => 'perl',
    dynamic_config => 0,
    module_name => 'WWW::GoKGS',
    create_readme => 1,
    create_license => 1,
    requires => {
        'perl' => '5.8.9',
        'parent' => 0,
        'Carp' => 0,
        'Exporter' => 0,
        'LWP::RobotUA' => 0,
        'URI' => '1.59',
        'Web::Scraper' => 0,
    },
    test_requires => {
        'Test::Exception' => 0,
        'Test::More' => '0.98',
        'Time::Piece' => 0,
        'Test::Deep' => 0,
        'Test::Base' => 0,
        'Encode' => 0,
    },
    recommends => {
        'HTML::TreeBuilder::LibXML' => 0,
    },
    test_files => [ 't/', 'xt/' ],
    meta_merge => {
        no_index => {
            directory => [ 't', 'xt', 'examples' ],
        },
        resources => {
            repository => 'git://github.com/anazawa/p5-WWW-GoKGS.git',
        },
    },
);

$build->create_build_script;
