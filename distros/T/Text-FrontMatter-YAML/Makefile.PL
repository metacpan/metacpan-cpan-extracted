use strict;
use warnings;
use ExtUtils::MakeMaker;

my %MakefileOptions = (
    NAME                => 'Text::FrontMatter::YAML',
    AUTHOR              => 'Aaron Hall <ahall@vitaphone.net>',
    VERSION_FROM        => 'lib/Text/FrontMatter/YAML.pm',
    ABSTRACT_FROM       => 'lib/Text/FrontMatter/YAML.pm',
    MIN_PERL_VERSION    => '5.10.1',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'YAML::Tiny'    => 0,
        'Carp'          => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.88',
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-FrontMatter-YAML-*' },
);


my %Modern_MM_Options = (
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            'repository' => {
                type => 'git',
                web  => 'https://github.com/vitahall/Text-FrontMatter-YAML',
                url  => 'https://github.com/vitahall/Text-FrontMatter-YAML.git',
            },
            'bugtracker' => {
                mailto => 'bug-text-frontmatter-yaml@rt.cpan.org',
                web    => 'https://rt.cpan.org/Public/Bug/Report.html?Queue=Text-FrontMatter-YAML',
            },
        },
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 6.68) {
    %MakefileOptions = (%MakefileOptions, %Modern_MM_Options);
}
WriteMakefile(%MakefileOptions);
