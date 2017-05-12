use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::PerlMethodList',
    VERSION_FROM      => 'lib/Tk/PerlMethodList.pm',
    PREREQ_PM         => {Tk          =>'8.4',
                          Tk::LabEntry=>'4.006',
                          Tk::NumEntry=>'2.06',
                          Tk::ROText  =>'4.010',
                          File::Slurp =>'9999.08',
                          Devel::Peek =>'0.96',
                          B           =>'1.01',
                          Class::Inspector    =>'1.17',
                          MRO::Compat =>'0.02',

                      } ,
              ($ExtUtils::MakeMaker::VERSION >= 6.3001 ?
               (LICENSE      => "perl") : ()
           ),
      ABSTRACT_FROM   => 'lib/Tk/PerlMethodList.pm', 
      AUTHOR          => 'Christoph Lamprecht <lamprecht@cpan.org>') ;



