use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Text::BibTeX::BibStyle',
    AUTHOR          => 'Mark Nodine <mnodine@alum.mit.edu>',
    VERSION_FROM    => 'lib/Text/BibTeX/BibStyle.pm',
    ABSTRACT        => 'Format Text::BibTeX::Entry items using .bst',
    PL_FILES        => {},
    PREREQ_PM 	    => { 'Text::BibTeX' => 0,
			 'HTML::Entities' => 0,
			 'Text::ASCIIMathML' => 0.7,
		     },
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean           => { FILES => 'Text-BibTeX-BibStyle-*' },
);
