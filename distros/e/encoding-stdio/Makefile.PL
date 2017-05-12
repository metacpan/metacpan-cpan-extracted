use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'encoding::stdio',
    VERSION_FROM      => 'lib/encoding/stdio.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/encoding/stdio.pm',
    AUTHOR            => 'Juerd Waalboer <juerd@cpan.org>',
);
