use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'GCrypt',
    'VERSION_FROM'	=> 'GCrypt.pm',
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'GCrypt.pm',
       AUTHOR     => 'Robert Bihlmeyer <robbe@orcus.priv.at>') : ()),
    'LIBS'		=> ['-lgcrypt'],
    'DEFINE'		=> '',
    'INC'		=> '-I.',
);
