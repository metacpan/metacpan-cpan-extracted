use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Text::XmlMatch',
    VERSION_FROM => 'lib/Text/XmlMatch.pm', # finds $VERSION
    AUTHOR       => 'Jason Lee (leeja@cpan.org)',
    ABSTRACT     => 'Pattern matching and grouping via XML Configuration file',
    PREREQ_PM    => {
                     	'Test::Simple' => 0.44,
                        'XML::Simple' => 2.14
                    },
);
