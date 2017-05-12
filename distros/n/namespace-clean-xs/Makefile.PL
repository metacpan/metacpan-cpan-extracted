use 5.010000;
use ExtUtils::MakeMaker;

#system 'pod2text lib/namespace/clean/xs.pm > README';

WriteMakefile(
    NAME            => 'namespace::clean::xs',
    VERSION_FROM    => 'lib/namespace/clean/xs.pm',
    AUTHOR          => ['Sergey Aleynikov <randir@cpan.org>'],
    PREREQ_PM       => {
        'XSLoader'    => 0,
    },
    TEST_REQUIRES   => {
        'Test::More'  => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/dur-randir/namespace-clean-xs',
            bugtracker => {web => 'https://github.com/dur-randir/namespace-clean-xs/issues'},
        },
        dynamic_config => 0,
    },
    ABSTRACT_FROM   => 'lib/namespace/clean/xs.pm',
    LICENSE         => 'perl',
    MIN_PERL_VERSION=> 5.010000,
);

{
    package MY;

    sub postamble { '$(OBJECT) : '.join(' ', glob('xs/*.h')) }
}
