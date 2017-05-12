use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'first',
    VERSION_FROM      => 'lib/first.pm',
    PREREQ_PM         => {
        'version'            => 0,
        # 'UNIVERSAL::require' => 0,
    }, 
    ($] >= 5.005 ?  
      (ABSTRACT_FROM  => 'lib/first.pm', 
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl') : ()),
);
