use ExtUtils::MakeMaker;

use strict;
use warnings;

WriteMakefile(
    NAME         => 'XML-FeedPP',
    VERSION_FROM => 'lib/XML/FeedPP.pm',
    PREREQ_PM    => {
        'Test::More'        => '0',
        'XML::TreePP'       => '0.39',
    },
    LICENSE      => 'perl_5',

    META_MERGE   => {
        'meta-spec' => { version => 2 },
        resources  =>
          { repository => {
                type => 'git',
                url  => 'https://github.com/kawanet/XML-FeedPP.git',
                web  => 'https://github.com/kawanet/XML-FeedPP',
            },
            homepage => 'http://perl.overmeer.net/CPAN/',
            license  => [ 'http://dev.perl.org/licenses/' ],
          },
      },
);

