use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::NumericData',
    license             => 'perl',
    dist_author         => q{Thomas Orgis <thomas@orgis.org>},
    dist_version_from   => 'lib/Text/NumericData.pm',
    build_requires => {
         'Test::More' => 0
        ,'File::Compare' => 0
    },
    requires => {
         'perl' => 5.006
        ,'Math::Spline' => 0
        ,'Text::ASCIIPipe' => 1.001000
        ,'Config::Param' => 3.000000
        ,'Storable' => 0
    },
    resources => {
        repository => {
             url => 'svn://scm.orgis.org/thor/text-numericdata'
            ,web => 'http://scm.orgis.org/view/thor/text-numericdata'
            ,type => 'svn'
        }
    },
    add_to_cleanup      => [ 'Text-NumericData-*' ],
    create_makefile_pl => 'traditional',
    script_files => [ glob('script/txd*') ]
);

$builder->create_build_script();
