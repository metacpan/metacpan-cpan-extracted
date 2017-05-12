use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Text::InHTML',
    VERSION_FROM      => 'lib/Text/InHTML.pm',
    PREREQ_PM         => {
        'version'                      => 0,
        'HTML::Entities'               => 0,
    },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Text/InHTML.pm', # retrieve abstract from module
       AUTHOR         => 'Daniel Muey  <http://drmuey.com/cpan_contact.pl>') : ()),
);
