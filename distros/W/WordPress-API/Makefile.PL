use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'WordPress::API',
   VERSION_FROM => 'lib/WordPress/API.pm',


   # gen /usr/bin/pmused by Mon Jul 28 19:42:18 EDT 2008 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Date::Manip'                       => '5',
      'Exporter'                          => '5',
      'File::Type'                        => '0.22',
      'LEOCHARRE::DEBUG'                  => '1',
      'MIME::Base64'                      => '3',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
      'WordPress::XMLRPC'                 => '1.17',
      'YAML'                              => '0',
   },


   EXE_FILES => [],
);


