use Module::Build 0.11;

Module::Build->new( module_name => 'Thesaurus',
                    dist_version_from => 'lib/Thesaurus.pm',
                    license => 'perl',
                    requires =>
                    { Params::Validate => 0.24,
                    },
                    recommends =>
                    { BerkeleyDB => 0.19,
                      Text::CSV_XS => 0,
                    },
                    build_requires =>
                    { Test::More => 0.46,
                    },
                    sign => 1,
                    create_readme => 1,
                    create_makefile_pl => 'passthrough',
                  )->create_build_script;
