use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'reform',
    VERSION_FROM => 'lib/reform.pm', # finds $VERSION
    AUTHOR       => 'Henning Koch (jaz@netalive.org)',
    ABSTRACT     => 'Third millenium syntax for Perl 5 OOP',
    PREREQ_PM    => { 'Filter::Simple' => '0' }
);
