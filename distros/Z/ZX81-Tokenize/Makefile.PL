use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'ZX81::Tokenize',
    AUTHOR          => 'Paulo Custodio <pauloscustodio@gmail.com>',
    VERSION_FROM    => 'lib/ZX81/Tokenize.pm',
    ABSTRACT_FROM   => 'lib/ZX81/Tokenize.pm',
    LICENSE         => 'perl_5',
    PREREQ_PM       => {
        'Modern::Perl'          => 1.20250607,
        'Test::HexDifferences'  => 1.001,
        'Test::More'            => 1.302225,
        'ZX81'                  => 0.001,
    },
);


sub MY::postamble {
    return <<'END' =~ s/^\\t/\t/grm;
# --- perltidy ---
perltidy:
\tfind lib -name '*.pm' -o -name '*.pl' -o -name '*.t' | xargs perltidy -b

# --- readme ---
readme:
\tperl -MPod::Markdown -e "Pod::Markdown->new->filter(qw(lib/ZX81/Tokenize.pm))" > README.md

# --- test ---
mytest:
\t$(MAKE) perltidy
\t$(MAKE) all
\t$(MAKE) readme
\t$(MAKE) test

# --- clean ---
myclean:
\t$(MAKE) clean
\tfind . -name '*.bak' -exec rm -f {} \;

END
}
