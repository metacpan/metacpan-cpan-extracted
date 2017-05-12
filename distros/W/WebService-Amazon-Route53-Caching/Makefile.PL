
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (

    NAME         => 'WebService::Amazon::Route53::Caching',
    VERSION_FROM => 'lib/WebService/Amazon/Route53/Caching.pm',
    ABSTRACT     => 'Caching layer on top of WebService::Amazon::Route53.',
    AUTHOR       => 'Steve Kemp <steve@steve.org.uk>',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.008',

    PREREQ_PM    => {
                     'DB_File'                     => 0,
                     'JSON'                        => 0,
                     'Redis'                       => 0,
                     'WebService::Amazon::Route53' => 0,
                    },

    TEST_REQUIRES => {
                      'Test::More'     => 0,
                      'Test::NoTabs'   => 0,
                      'Test::Pod'     => 0,
                      'Test::Strict'  => 0,
                      'Test::CheckManifest' => 0,
                      },

    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://github.com/skx/WebService--Amazon--Route53--Caching/',
            bugtracker => 'https://github.com/skx/WebService--Amazon--Route53--Caching/issues',
            repository => 'https://github.com/skx/WebService--Amazon--Route53--Caching.git',
                     },
                  },
             );



unless ( eval {ExtUtils::MakeMaker->VERSION(6.56)} )
{
    my $br = delete $WriteMakefileArgs{ BUILD_REQUIRES };
    my $pp = $WriteMakefileArgs{ PREREQ_PM };
    for my $mod ( keys %$br )
    {
        if ( exists $pp->{ $mod } )
        {
            $pp->{ $mod } = $br->{ $mod } if $br->{ $mod } > $pp->{ $mod };
        }
        else
        {
            $pp->{ $mod } = $br->{ $mod };
        }
    }
}

delete $WriteMakefileArgs{ CONFIGURE_REQUIRES }
  unless eval {ExtUtils::MakeMaker->VERSION(6.52)};

WriteMakefile(%WriteMakefileArgs);
