use ExtUtils::MakeMaker;

WriteMakefile(

   NAME => 'WordPress-CLI',
   
   VERSION_FROM   => 'lib/WordPress/CLI.pm',
   ABSTRACT_FROM  => 'lib/WordPress/CLI.pm',
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   EXE_FILES => [qw(bin/wordpress-upload-post bin/wordpress-info bin/wordpress-upload-media)],

   
   # gen /usr/bin/pmused by Sat Jun 26 20:29:59 EDT 2010 
   PREREQ_PM => {
      'Date::Manip'                       => '5.48',
      'Getopt::Std::Strict'               => '1.01',
      'String::ShellQuote' => 0,
      'LEOCHARRE::Strings'                => '1.02',
      'Test::Simple'                      => '0',
      'WordPress::XMLRPC'                 => '1.23',
      'Smart::Comments' => 0,
   },

);


