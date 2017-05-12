use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'WWW::HtmlUnit',
    AUTHOR           => 'awwaiid <awwaiid@thelackthereof.org>',
    ABSTRACT_FROM    => 'lib/WWW/HtmlUnit.pm', # retrieve abstract from module
    VERSION_FROM     => 'lib/WWW/HtmlUnit.pm', # finds $VERSION
    PREREQ_PM        => {
      'Inline::Java' => 0.53,
    },
);

