use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'any',
    VERSION_FROM      => 'lib/any.pm',
    PREREQ_PM         => {
        'version' => 0,
        'first'   => 0,
    }, 
    ($] >= 5.005 ?  
      (ABSTRACT_FROM  => 'lib/any.pm', 
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl') : ()),
);