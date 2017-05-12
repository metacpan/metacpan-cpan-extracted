use Module::Build;
Module::Build->new
    ( module_name => 'Tie::UnionHash',
    license => 'perl',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
