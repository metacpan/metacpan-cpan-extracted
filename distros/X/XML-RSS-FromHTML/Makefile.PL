use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'XML::RSS::FromHTML',
    VERSION_FROM => 'lib/XML/RSS/FromHTML.pm', # finds \$VERSION
    AUTHOR       => 'Toshimasa Ishibashi (bashi@cpan.org)',
    ABSTRACT     => 'simple framework for creating RSS out of HTML',
    PREREQ_PM    => {
        'XML::RSS'       => 1.48,
        'XML::Parser'    => 2.36,
        'LWP::UserAgent' => 0,
        'HTTP::Cookies'  => 0,
        'HTML::Parser'   => 3.68,
        'HTTP::Date'     => 0,
        'Test::Simple'   => 0.44,
        'Test::More'     => 0,
        'File::Temp'     => 0,
        'Class::Accessor::Fast' => 0,
    },
);
