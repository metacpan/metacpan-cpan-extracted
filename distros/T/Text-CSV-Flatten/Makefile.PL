use 5.014;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Text::CSV::Flatten',
    VERSION_FROM      => 'lib/Text/CSV/Flatten.pm',
    PREREQ_PM         => {
        'JSON'      => '2.19',
        'Text::CSV' => '1.32',
    },
    ABSTRACT_FROM     => 'lib/Text/CSV/Flatten.pm',
    AUTHOR            => 'Timo Kluck <tkluck@infty.nl>',
    LICENSE           => 'perl',
);
