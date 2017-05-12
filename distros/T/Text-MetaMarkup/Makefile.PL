use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Text::MetaMarkup',
    VERSION_FROM  => 'MetaMarkup.pm',
    PREREQ_PM     => {},
    ABSTRACT_FROM => 'MetaMarkup.pm',
    AUTHOR        => 'Juerd <juerd@cpan.org>'
);
