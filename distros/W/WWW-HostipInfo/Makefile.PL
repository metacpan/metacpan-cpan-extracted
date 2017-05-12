

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::HostipInfo',
    VERSION_FROM => 'lib/WWW/HostipInfo.pm', # finds \$VERSION
    AUTHOR       => 'Makamaka Hannyaharamitu (makamaka[at]cpan.org)',
    ABSTRACT     => 'access to hostip.info API',
    PREREQ_PM    => {
                     'Test::More' => 0,
                     'LWP'        => 0,
                    },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE' => 'gpl', ) : () ),

    ( $ExtUtils::MakeMaker::VERSION >= 6.46 ? (
        'META_MERGE' => {
            resources => {
                repository  =>      'http://github.com/makamaka/WWW-HostipInfo',
            },
        } ) : ()
    ),

);
