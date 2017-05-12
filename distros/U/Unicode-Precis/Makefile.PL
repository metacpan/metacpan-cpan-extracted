use 5.008;

package MY;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Unicode::Precis',
    VERSION_FROM       => 'lib/Unicode/Precis.pm',
    MIN_PERL_VERSION   => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.26',
        'Test::More'          => '0.45',
    },
    BUILD_REQUIRES => {
        'Encode'       => '0',
        'Unicode::UCD' => '0',
    },
    PREREQ_PM => {
        'Encode'                       => '0',
        'Exporter'                     => '0',
        'Unicode::BiDiRule'            => '0.02',
        'Unicode::Normalize'           => '1.23',
        'Unicode::Precis::Preparation' => '0.01',
        'XSLoader'                     => '0',
    },
    ABSTRACT_FROM => 'lib/Unicode/Precis.pm',
    AUTHOR        => 'Hatuka*nezumi - IKEDA Soji <hatuka@nezumi.nu>',
    LICENSE       => 'perl',
    META_MERGE    => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            repository => 'https://github.com/hatukanezumi/Unicode-Precis/',
        },
    },
    dist => {PREOP => '$(MAKE) preop',},
);

sub postamble {
    my $self = shift;

    my $preop =
        $self->cd('Utils', '$(MAKE) preop DISTVNAME=../$(DISTVNAME)/Utils');
    return "preop:\n\t$preop\n";
}
