use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Sitebase',
    AUTHOR              => 'Grant Grueninger <grantg@cpan.org>',
    VERSION_FROM        => 'lib/WWW/Sitebase.pm',
    ABSTRACT_FROM       => 'lib/WWW/Sitebase.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Spiffy' => 0.24,             # Sitebase.pm
        'Config::General' => 0,       # Sitebase.pm
        'Params::Validate' => 0,      # Sitebase.pm
        'WWW::Mechanize' => 1.20,     # Navigator.pm
        'YAML' => 0.39,               # Sitebase.pm
        'List::Compare' => 0,         # Poster.pm
        'IO::Prompt' => 0,            # Poster.pm
        'File::Spec::Functions' => 0, # Navigator.pm, Poster.pm
        'Mozilla::CA' => 20130114,    # LWP::UserAgent for SSL
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Sitebase-*' },
);
