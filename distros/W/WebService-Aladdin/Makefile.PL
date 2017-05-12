use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WebService::Aladdin',
    AUTHOR        => 'Jeen Lee <jeen@cpan.org>',
    VERSION_FROM  => 'lib/WebService/Aladdin.pm',
    ABSTRACT_FROM => 'lib/WebService/Aladdin.pm',
    PREREQ_PM => {
        'Test::Base'                => 0,
        'version'                   => 0,
        'Class::Accessor::Fast'     => 0,
        'LWP::UserAgent'            => 0,
        'URI'                       => 0,
        'Carp'                      => 0,
        'XML::FeedPP'               => 0,
    },
    ($ExtUtils::MakeMaker::VERSION >= 6.31
        ? ( LICENSE => 'perl' )
        : ()
    ),
);