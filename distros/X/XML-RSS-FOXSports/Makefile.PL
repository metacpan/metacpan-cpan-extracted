use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::RSS::FOXSports',
    'VERSION_FROM'	=> 'lib/XML/RSS/FOXSports.pm',
    'PREREQ_PM'		=> {'XML::RSS::Parser',},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/XML/RSS/FOXSports.pm',
       AUTHOR        => 'Brian Perez <perez@cpan.org>') : ()),
);