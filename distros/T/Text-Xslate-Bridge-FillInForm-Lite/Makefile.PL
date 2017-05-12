use 5.008_001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Text::Xslate::Bridge::FillInForm::Lite',
    VERSION_FROM => 'lib/Text/Xslate/Bridge/FillInForm/Lite.pm',
    PREREQ_PM    => {
        'Text::Xslate'           => 0,
        'HTML::FillInForm::Lite' => 0,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            bugtracker => 'https://github.com/ysasaki/p5-text-xslate-bridge-fillinform-lite/issues',
            repository => 'git://github.com/ysasaki/p5-text-xslate-bridge-fillinform-lite.git',
        },
    },
    LICENSE => 'perl',
    (   $] >= 5.005
        ? ( ABSTRACT_FROM => 'lib/Text/Xslate/Bridge/FillInForm/Lite.pm',
            AUTHOR        => 'Yoshihiro Sasaki <ysasaki at cpan.org>'
            )
        : ()
    ),
);
