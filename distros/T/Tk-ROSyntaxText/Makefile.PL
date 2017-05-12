use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tk::ROSyntaxText',
    AUTHOR              => 'Ken Cotterill <kcott@cpan.org>',
    VERSION_FROM        => 'lib/Tk/ROSyntaxText.pm',
    ABSTRACT_FROM       => 'lib/Tk/ROSyntaxText.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Syntax::Highlight::Engine::Kate' => 0.06,
        'Test::More' => 0.94,
        'Tk' => 0,
        'Tk::Derived' => 0,
        'Tk::ROText' => 0,
        'Tk::Widget' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tk-ROSyntaxText-*' },
);
