use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'cPanel',
    VERSION_FROM      => 'lib/cPanel.pm', 
    PREREQ_PM         => {}, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/cPanel.pm', 
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
