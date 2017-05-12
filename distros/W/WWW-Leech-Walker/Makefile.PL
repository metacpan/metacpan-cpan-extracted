

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::Leech::Walker',
    VERSION_FROM => 'lib/WWW/Leech/Walker.pm', # finds \$VERSION
    AUTHOR       => 'Dmitry Selverstov ( jaredspb@cpan.org)',
    ABSTRACT     => 'WWW parsing micro framework',
    PREREQ_PM    => {
                    'Test::Simple' => 0.44,
					'LWP' => 6.08,
					'URI::URL' => 5.04,
					'WWW::Leech::Parser' => 0.01
                    },
);
