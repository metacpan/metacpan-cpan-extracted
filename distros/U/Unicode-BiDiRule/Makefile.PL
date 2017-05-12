use 5.008;

package MY;
use ExtUtils::MakeMaker;
use Unicode::UCD;

WriteMakefile(
    NAME               => 'Unicode::BiDiRule',
    VERSION_FROM       => 'lib/Unicode/BiDiRule.pm',
    MIN_PERL_VERSION   => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.26',
        'Test::More'          => '0.45',
        'Unicode::UCD'        => '0',
    },
    PREREQ_PM => {
        Exporter => '0',
        XSLoader => '0',
    },
    ABSTRACT_FROM => 'lib/Unicode/BiDiRule.pm',
    AUTHOR        => 'Hatuka*nezumi - IKEDA Soji <hatuka@nezumi.nu>',
    LICENSE       => 'perl',
    LIBS          => [''],
    DEFINE        => '',
    INC           => '-I.',
    dist          => {PREOP => '$(MAKE) preop',},
    META_MERGE    => {
        resources => {
            license => 'http://dev.perl.org/licenses/',
            repository =>
                'https://github.com/hatukanezumi/Unicode-BiDiRule/',
        },
    },
);

sub clean {
    my $inherited = shift->SUPER::clean(@_);
    $inherited =~ s/(:+[ \t]*)/${1}clean-c /;
    $inherited;
}

sub test {
    my $inherited = shift->SUPER::test(@_);
    $inherited =~ s/^(test[ \t]*:+[ \t]*)/${1}unidata /m;
    $inherited;
}

sub postamble {
    my $UnicodeVersion = Unicode::UCD::UnicodeVersion();

    return <<"EOF";
BiDiRule.c: stamp-c

stamp-c: data\$(DIRFILESEP)bidirule.pl unicode_bidirule.c
\t\$(PERL) data\$(DIRFILESEP)bidirule.pl unicode_bidirule.c
\t\$(TOUCH) stamp-c

clean-c:
\t\$(PERL) data\$(DIRFILESEP)bidirule.pl --init unicode_bidirule.c
\t\$(RM_F) stamp-c

preop:
\t\$(PERL) data\$(DIRFILESEP)bidirule.pl --init \$(DISTVNAME)/unicode_bidirule.c
\t\$(RM_F) \$(DISTVNAME)/unicode_bidirule.c.old

unidata:
\tcd t; \\
\t[ -f IdnaTest-$UnicodeVersion.txt ] || \\
\twget -q -N -O IdnaTest-$UnicodeVersion.txt \\
\tftp://unicode.org/Public/idna/$UnicodeVersion/IdnaTest*.txt \\
\t|| \$(NOOP)

EOF
}
