use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->
    new( module_name         => 'Tree::Easy',
         license             => 'perl',
         dist_author         => 'Justin Davis <jrcd83@gmail.com>',
         dist_version_from   => 'lib/Tree/Easy.pm',
         build_requires      => { 'Test::More' => 0, },
         requires            => { 'Scalar::Util' => 0,
                                  'List::Util'   => 0,
                                  'Carp'         => 0,
                                  'Data::Dumper' => 0,
                                  'Text::Wrap'   => 0,
                                 },
         add_to_cleanup      => [ 'Tree-Easy-*' ],
         create_makefile_pl  => 'traditional',
        );

$builder->create_build_script();
