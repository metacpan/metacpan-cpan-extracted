use ExtUtils::MakeMaker;

WriteMakefile(
   NAME           => 'YAML::DBH',
   VERSION_FROM   => 'lib/YAML/DBH.pm',
   ABSTRACT_FROM  => 'lib/YAML/DBH.pm',

   # gen /usr/bin/pmused by Mon Dec  1 17:04:41 EST 2008 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'DBD::SQLite'                       => '1.14',
      'DBD::mysql'                        => '4.008',
      'DBI'                               => '1.607',
      'Exporter'                          => '5',
      'Test::Simple'                      => '0',
      'YAML'                              => '0.66',
   },
   LICENSE        => 'perl',
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',

);


