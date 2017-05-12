use strict;
use Module::Build;

Module::Build
  ->new( module_name => "WebService::Google::Sets",
         license     => 'perl',
         script_files => [ 'bin/get_gset' ],
         build_requires => {
             'Test::More' => 0,
         },
         requires => {
             'CGI' => 0,
             'LWP' => 0,
         },
   create_makefile_pl => 'traditional',
       )
  ->create_build_script;
