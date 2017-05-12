use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'textrender',
  
   VERSION_FROM   => 'bin/textrender',
   
   ABSTRACT_FROM  => 'bin/textrender',      
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   EXE_FILES => [qw(bin/textrender bin/findfont bin/imgtile)],
   
   # gen /usr/bin/pmused by Thu Mar 18 14:54:43 EDT 2010 
   PREREQ_PM => {
      'Cache::File'                       => '2.04',
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'Getopt::Std::Strict'               => '1.01',
      'Smart::Comments'                   => '1',
      'String::ShellQuote'                => '1.03',
      'Test::Simple'                      => '0',
   },
);

