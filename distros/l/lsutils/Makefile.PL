use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'lsutils',
   VERSION_FROM => 'lib/LEOCHARRE/Dir/Lsutils.pm',
   

   # gen /usr/bin/pmused by Wed Oct 28 21:34:14 EDT 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'File::Find::Rule'                  => '0.30',
      'Getopt::Std::Strict'               => '1.01',
      'LEOCHARRE::CLI2'                   => '1.14',
      'LEOCHARRE::Debug'                  => '1.02',
      'LEOCHARRE::Dir'                    => '1.07',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
      'Time::Format'                      => '1.09',
   },

   
   LICENSE => 'perl',
   AUTHOR => 'Leo Charre leocharre at cpan dot org', 
   
   EXE_FILES => [qw(bin/findirs
		bin/findnewest
		bin/lsas
      bin/lsf
      bin/lsd
      bin/lscount
		bin/lsdcounts
		bin/lsdu)],
);


