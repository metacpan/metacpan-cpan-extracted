use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::PerlInheritanceTree',
    VERSION_FROM      => 'lib/Tk/PerlInheritanceTree.pm', # finds $VERSION
    PREREQ_PM         => {Tk                        => '804.027',
                          Tk::NumEntry              => '2.06',
                          Tk::GraphItems::TextBox   => '0.01',
                          Tk::GraphItems::Connector => '0.01',
                          Tk::PerlMethodList        => '0.01',
                          Class::Inspector          => '1.17',
                          },
              ($ExtUtils::MakeMaker::VERSION >= 6.3001 ?
               (LICENSE      => "perl") : (),
           ),
      ABSTRACT_FROM   => 'lib/Tk/PerlInheritanceTree.pm', 
       AUTHOR         => 'Christoph Lamprecht <lamprecht@cpan.org>');
