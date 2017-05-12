use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'lib::restrict',
    VERSION_FROM      => 'lib/lib/restrict.pm',
    ($] >= 5.005 ?    
      (ABSTRACT_FROM  => 'lib/lib/restrict.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
