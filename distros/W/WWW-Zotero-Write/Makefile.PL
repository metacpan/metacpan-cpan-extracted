
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Zotero::Write',
    VERSION_FROM => 'lib/WWW/Zotero/Write.pm', # finds \$VERSION
    AUTHOR       => 'FranE<ccedil>ois Rappaz (rappazf@gmail.com)',
    ABSTRACT     => 'Perl interface to the Zotero Write API',
    PREREQ_PM    => {
                     'Test::More' => 1.001014,
                     'Moo' => 1.0,
                     'Carp' => 0,
                     'JSON' => 0,
                     'URI::Escape' => 0,
                     'WWW::Zotero' => 0.04,
                    },
);
