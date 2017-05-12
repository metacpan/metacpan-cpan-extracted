use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Tie::RangeHash',
     license => 'perl',
     requires => {
       'perl'                       => '5.006',
       'base'                       => 0,
       'Algorithm::SkipList'        => 1.02,
     },
     build_requires => {
       'Test::More'                 => 0,
     },
     recommends => {
     },
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
     sign => 0,
);

$build->create_build_script;
