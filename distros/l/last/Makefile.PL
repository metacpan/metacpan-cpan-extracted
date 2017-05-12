use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'last',
    VERSION_FROM      => 'lib/last.pm',
    PREREQ_PM         => {
        'version' => 0,
        'first'   => 0,
    }, 
    ($] >= 5.005 ?  
      (ABSTRACT_FROM  => 'lib/last.pm', 
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl') : ()),
);
