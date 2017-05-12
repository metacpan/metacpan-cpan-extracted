use ExtUtils::MakeMaker;

WriteMakefile(

   NAME => 'WordPress::Base::MediaObject',
   
   VERSION_FROM   => 'lib/WordPress/Base/MediaObject.pm',
   
   ABSTRACT_FROM  => 'lib/WordPress/Base/MediaObject.pm',      
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   EXE_FILES => [],

   
   # gen /usr/bin/pmused by Sat Jul  3 01:14:45 EDT 2010 
   PREREQ_PM => {
      'Exporter'                          => '5',
      'File::Type'                        => '0.22',
      'MIME::Base64'                      => '3.07',
      'Test::Simple'                      => '0',
   },

);


