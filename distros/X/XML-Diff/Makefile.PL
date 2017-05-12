use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'		=> 'XML::Diff',
              'VERSION_FROM'	=> 'Diff.pm', # finds $VERSION
              'PREREQ_PM'		=> {
                                            XML::LibXML => 1.56,
                                            Algorithm::Diff => 1.15,
                                           },
              ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               (ABSTRACT => 'XML DOM-Tree based Diff & Patch Module',
                AUTHOR     => 'Arne Claassen <sdether@cpanorg>') : ()),
             );
