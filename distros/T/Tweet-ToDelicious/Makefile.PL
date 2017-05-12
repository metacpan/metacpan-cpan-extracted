use 5.014002;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'Tweet::ToDelicious',
    VERSION_FROM  => 'lib/Tweet/ToDelicious.pm',    # finds $VERSION
    ABSTRACT_FROM => 'lib/Tweet/ToDelicious.pm',
    PREREQ_PM     => {
        'Class::Accessor::Lite'     => '0.05',
        'Config::Any'               => '0.23',
        'YAML::XS'                  => '0.37',
        'Net::Delicious'            => '1.14',
        'LWP::Protocol::https'      => '6.02',
        'Coro'                      => '6.06',
        'AnyEvent::Twitter::Stream' => '0.22',
        'Net::OAuth'                => '0.27',
        'Net::SSLeay'               => '1.42',
        'List::MoreUtils'           => '0.33',
        'Log::Minimal'              => '0.09',
        'Sub::Retry'                => '0.04',
    },
    BUILD_REQUIRES => { 'Test::TCP' => '1.13', },
    EXE_FILES      => ['bin/t2delicious.pl'],
    AUTHOR         => 'Yoshihiro Sasaki <ysasaki at cpan.org>',
    test           => {
        TESTS =>
            't/000_ToDelicious/*.t t/001_Interface/*.t t/002_OnTweet/*.t t/003_OnEvent/*.t t/004_Entity/*.t'
    }
);
