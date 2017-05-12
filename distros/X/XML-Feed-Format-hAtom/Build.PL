use Module::Build;

my $build = Module::Build
  ->new( module_name   => "XML::Feed::Format::hAtom",
         dist_abstract => "hAtom Syndication Feed Support", 
         license       => 'perl',
         script_files  => [ ],
         requires      => {
                          'Data::Microformat'          => '0.04',
                          'HTML::Entities'             => 0,
                          'XML::Feed'                  => '0.3',
                          'Test::More'                 => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;


