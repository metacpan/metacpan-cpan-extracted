use ExtUtils::MakeMaker;

WriteMakefile(

   NAME => 'yamltk',
   
   VERSION_FROM   => 'bin/yamltk',
   
   ABSTRACT_FROM  => 'bin/yamltk',      
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   EXE_FILES => [qw(bin/csv2yaml bin/yaml2csv bin/yamltk bin/yamltk-tools)],

   
   # gen /usr/bin/pmused by Thu Mar 25 11:17:09 EDT 2010 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Data::Dumper'                      => '2.121_08',
      'Exporter'                          => '5',
      'Getopt::Std::Strict'               => '1.01',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
      'Text::CSV'                         => '0',
      'Text::CSV::Slurp'                  => '0',
      'XML::Dumper'                       => '0.81',
      'YAML'                              => '0.66',
   },

);


