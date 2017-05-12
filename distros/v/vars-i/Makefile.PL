# perl Makefile.PL && nmake realclean && cls && perl Makefile.PL && nmake test
# cpan-upload -mailto yo@yo.yo -verbose -user podmaster vars-i-1.01.tar.gz


use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'vars::i',
    VERSION_FROM => 'lib/vars/i.pm', # finds \$VERSION
    AUTHOR       => 'D. H. (PodMaster)',
    ABSTRACT     => 'Perl pragma to declare and simultaneously initialize global variables.',
    PREREQ_PM    => {
                     'Test::More' => 0,
                    },
);
