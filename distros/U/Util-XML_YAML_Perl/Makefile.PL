use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Util::XML_YAML_Perl',
    AUTHOR              => q{Ravi Chandra. M <rchandram\@cpan.org>},
    VERSION_FROM        => 'lib/Util/XML_YAML_Perl.pm',
    ABSTRACT_FROM       => 'lib/Util/XML_YAML_Perl.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::Simple' => 2.18,
        'YAML'=>0.68,
        'YAML::AppConfig'=>0.16
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Util-XML_YAML_Perl-*' },
);
