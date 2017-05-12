use 5.008;

package MY;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Unicode::Precis::Utils',
    VERSION_FROM       => 'Utils.pm',
    MIN_PERL_VERSION   => 5.008,
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => 0,},
    BUILD_REQUIRES     => {
        'Encode'       => '0',
        'Unicode::UCD' => '0',
    },
    PREREQ_PM => {
        'Exporter' => '0',
        'XSLoader' => '0',
    },
    ABSTRACT_FROM => 'Utils.pm',
    AUTHOR        => 'Hatuka*nezumi - IKEDA Soji <hatuka@nezumi.nu>',
    LIBS          => [''],
    DEFINE        => '',
    INC           => '-I.',
    dist          => {PREOP => '$(MAKE) preop'},
);

sub clean {
    my $inherited = shift->SUPER::clean(@_);
    $inherited =~ s/(:+[ \t]*)/${1}clean-c /;
    $inherited;
}

#sub test {
#    my $inherited = shift->SUPER::test(@_);
#    $inherited =~ s/^(test[ \t]*:+[ \t]*)/${1}unidata /m;
#    $inherited;
#}

sub postamble {
#    my $UnicodeVersion = Unicode::UCD::UnicodeVersion();

    return <<"EOF";
Utils.c: stamp-c

stamp-c: data/utils.pl precis_utils.c
\t\$(PERL) data/utils.pl precis_utils.c
\t\$(TOUCH) stamp-c

clean-c:
\t\$(PERL) data/utils.pl --init precis_utils.c
\t\$(RM_F) stamp-c

preop:
\t\$(PERL) data/utils.pl --init \$(DISTVNAME)/precis_utils.c
\t\$(RM_F) \$(DISTVNAME)/precis_utils.c.old

#unidata:
#\tcd t; \\
#\t[ -f IdnaTest-$UnicodeVersion.txt ] || \\
#\twget -q -N -O IdnaTest-$UnicodeVersion.txt \\
#\tftp://unicode.org/Public/idna/$UnicodeVersion/IdnaTest*.txt \\
#\t|| \$(NOOP)

EOF
}
