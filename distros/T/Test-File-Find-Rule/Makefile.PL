use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Test::File::Find::Rule',
    VERSION_FROM      => 'lib/Test/File/Find/Rule.pm',
    PREREQ_PM         => { 
    	'File::Find::Rule' => 0,
	'File::Spec' => 0,
	'Number::Compare' => 0,
	'Test::Builder' => 0,
    },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Test/File/Find/Rule.pm', 
       AUTHOR         => 'Fabien POTENCIER <fabpot@cpan.org') : ()),
    INSTALLDIRS => 'site',
);
