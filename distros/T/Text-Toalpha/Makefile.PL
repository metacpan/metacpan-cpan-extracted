use 5.008001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Text::Toalpha',
    VERSION_FROM      => 'Toalpha.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'Toalpha.pm',
    AUTHOR            => 'Sam Lauber <samuell@cpan.org>',
);
