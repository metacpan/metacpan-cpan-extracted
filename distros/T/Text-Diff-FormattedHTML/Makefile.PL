use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Diff::FormattedHTML',
    AUTHOR              => q{Alberto Simoes <ambs@cpan.org>},
    VERSION_FROM        => 'lib/Text/Diff/FormattedHTML.pm',
    ABSTRACT_FROM       => 'lib/Text/Diff/FormattedHTML.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More'      => '0',
                  'Algorithm::Diff' => '1.1900',
                  'File::Slurp'     => '0',
                  'String::Diff'    => '0.04',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Diff-FormattedHTML-*' },
);
