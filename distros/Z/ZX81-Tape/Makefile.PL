use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'ZX81::Tape',
    AUTHOR        => 'Paulo Custodio <pauloscustodio@gmail.com>',
    VERSION_FROM  => 'lib/ZX81/Tape.pm',
    ABSTRACT_FROM => 'lib/ZX81/Tape.pm',
    EXE_FILES => [ 'bin/zx81_make_p', 'bin/zx81_dump_p', 'bin/zx81_list_p' ],
    LICENSE   => 'perl_5',
    PREREQ_PM => {
        'Modern::Perl'         => 1.20250607,
        'Object::Tiny::RW'     => 1.07,
        'Path::Tiny'           => 0.150,
        'Test::HexDifferences' => 1.001,
        'Test::More'           => 1.302225,
        'Text::Diff'           => 1.46,
        'ZX81'                 => 0.001,
        'ZX81::Tokenize'       => 0.004,
    },
);

sub MY::postamble {
    return <<'END' =~ s/^\\t/\t/grm;
# --- perltidy ---
perltidy:
\tfind lib t -name '*.pm' -o -name '*.pl' -o -name '*.t' | xargs perltidy -b

# --- readme ---
readme:
\tperl -MPod::Markdown -e "Pod::Markdown->new->filter(qw(lib/ZX81/Tape.pm))" > README.md

# --- inittests ---
inittests:
\t$(MAKE) -C t

# --- test ---
mytest:
\t$(MAKE) perltidy
\t$(MAKE) all
\t$(MAKE) readme
\t$(MAKE) inittests
\t$(MAKE) test

# --- clean ---
myclean:
\t$(MAKE) clean
\tfind . -name '*.bak' -exec rm -f {} \;

END
}
