use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'XML::Perl',
    VERSION_FROM      => 'lib/XML/Perl.pm', # finds $VERSION
	LICENSE           => "perl",
    PREREQ_PM         => { 'HTML::Parser' => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/Perl.pm', # retrieve abstract from module
       AUTHOR         => 'Nick Kostirya <nick@ToDo.org>') : ()),
);
