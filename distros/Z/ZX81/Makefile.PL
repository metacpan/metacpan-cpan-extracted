use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'ZX81',
    AUTHOR			=> 'Paulo Custodio <pauloscustodio@gmail.com>',
    VERSION_FROM	=> 'lib/ZX81.pm',
    ABSTRACT_FROM	=> 'lib/ZX81.pm',
	LICENSE 		=> 'perl_5',
    PREREQ_PM		=> {
		'Modern::Perl'			=> 1.20250607,
    },
);


sub MY::postamble {
    return <<'END' =~ s/^\\t/\t/grm;
# --- perltidy ---
perltidy:
\tfind lib -name '*.pm' -o -name '*.pl' -o -name '*.t' | xargs perltidy -b

# --- readme ---
readme:
\tperl -MPod::Markdown -e "Pod::Markdown->new->filter(qw(lib/ZX81.pm))" > README.md

END
}
