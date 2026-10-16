use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'ZX81::Tape',
    AUTHOR          => 'Paulo Custodio <pauloscustodio@gmail.com>',
    VERSION_FROM    => 'lib/ZX81/Tape.pm',
    ABSTRACT_FROM   => 'lib/ZX81/Tape.pm',
    LICENSE         => 'perl_5',
    PREREQ_PM       => {
        'Modern::Perl'          => 1.20250607,
        'Object::Tiny::RW'      => 1.07,
        'Path::Tiny'            => 0.150,
        'Test::HexDifferences'  => 1.001,
        'Test::More'            => 1.302225,
        'Text::Diff'            => 1.46,
        'ZX81'                  => 0.001,
        'ZX81::Tokenize'        => 0.004,
    },
);

sub MY::postamble {
    return <<'END' =~ s/^\\t/\t/grm;
# --- perltidy ---
perltidy:
\tfind lib -name '*.pm' -o -name '*.pl' -o -name '*.t' | xargs perltidy -b

# --- readme ---
readme:
\tperl -MPod::Markdown -e "Pod::Markdown->new->filter(qw(lib/ZX81/Tape.pm))" > README.md

# --- inittests ---
inittests:
\t$(MAKE) -C t

END
}
