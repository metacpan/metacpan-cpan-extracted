use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Tie::Filehandle::Preempt::Stdin',
    VERSION_FROM => 'lib/Tie/Filehandle/Preempt/Stdin.pm', # finds $VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Preempt STDIN during testing.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
