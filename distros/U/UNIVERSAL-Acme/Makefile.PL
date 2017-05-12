use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'UNIVERSAL::Acme',
    VERSION_FROM      => 'Acme.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT => 'Whatever "it" is, it\'s a METHOD.  Hoser.',
       AUTHOR         => 'Sean O\'Rourke <seano@cpan.org>') : ()),
);
