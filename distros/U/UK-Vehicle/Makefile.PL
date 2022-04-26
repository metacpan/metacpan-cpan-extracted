use 5.030000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'UK::Vehicle',
    VERSION_FROM      => 'lib/UK/Vehicle.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'HTTP::Request'			=> 0,
        'JSON'					=> 0,
        'Mozilla::CA'			=> 0,
        'DateTime'				=> 0,
        'LWP::Protocol::https'	=> 0,
        'Scalar::Util'			=> 0,
        'Try::Tiny'				=> 0,
        'LWP::UserAgent'		=> 0,
        'Class::Tiny'			=> 0,
	},
    ABSTRACT_FROM     => 'lib/UK/Vehicle.pm', # retrieve abstract from module
    AUTHOR            => 'Ian Gibbs <igibbs@cpan.org>',
    LICENSE           => 'gpl',
    TEST_REQUIRES => {
        'Test::More'				=> 0.88,
        'Test2::Tools::Exception'	=> 0,
        'Test::Pod'					=> 1.00,
        'Config::Tiny' 				=> 0,
        'JSON'						=> 0,
        'DateTime'					=> 0,
	}
);
