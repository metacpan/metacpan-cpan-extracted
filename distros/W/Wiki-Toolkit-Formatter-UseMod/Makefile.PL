use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME         => "Wiki::Toolkit::Formatter::UseMod",
    VERSION_FROM => "lib/Wiki/Toolkit/Formatter/UseMod.pm",
    PREREQ_PM    => { 'Text::WikiFormat'     => '0.71', # 0.7 buggy
                      'HTML::PullParser'     => 0,
                      'Test::More'           => 0,
                      'URI::Escape'          => 0,
                      'URI::Find::Delimited' => '0.02', # earlier buggy
                      'Wiki::Toolkit'        => 0,
                    },
    clean        => { FILES => "t/*.db" },
);
