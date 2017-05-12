use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'WoW::Armory::API',
    AUTHOR          => 'Aleksandr Aleshin <silencer@cpan.org>',
    LICENSE         => 'perl_5',
    VERSION_FROM    => 'lib/WoW/Armory/API.pm',
    ABSTRACT_FROM   => 'lib/WoW/Armory/API.pm',
    PREREQ_PM       => {
        'URI::Escape'       => 0,
        'LWP::UserAgent'    => 0,
        'JSON::XS'          => 0,
        'Class::Accessor'   => 0,
    },
);
