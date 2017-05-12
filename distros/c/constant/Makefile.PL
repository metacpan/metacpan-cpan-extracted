use 5.006;
use strict;
use ExtUtils::MakeMaker;

my %prereq = (
    "Test::More" => 0,
);

WriteMakefile(
    NAME            => 'constant',
    LICENSE         => 'perl',
    AUTHOR          => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM    => 'lib/constant.pm',
    ABSTRACT_FROM   => 'lib/constant.pm',
    INSTALLDIRS     => ($] >= 5.012 ? 'site' : 'perl'),
    PL_FILES        => {},
    PREREQ_PM       => \%prereq,
    META_MERGE          => {
        resources       => {
            repository  => "git://perl5.git.perl.org/perl.git",
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'https://metacpan.org/module/constant',
            irc         => 'irc://irc.perl.org/#p5p',
            mailinglist => 'http://lists.perl.org/list/perl5-porters.html',
            bugtracker  => "https://rt.perl.org/rt3/Search/Results.html?Query=Queue='perl5' AND Content LIKE 'module=constant' AND (Status='open' OR Status='new' OR Status='stalled')",
        },
    },
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean           => { FILES => 'constant-*' },
);
