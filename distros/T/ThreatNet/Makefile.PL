use inc::Module::Install 0.75;

all_from       'lib/ThreatNet.pm';
requires       'Fcntl'                                  => 0;
requires       'Params::Util'                           => '0.05';
requires       'Config::Tiny'                           => '2.00';
requires       'Class::Inspector'                       => '1.06';
requires       'Getopt::Long'                           => 0;
requires       'File::Basename'                         => 0;
requires       'POE'                                    => 0;
requires       'POE::Wheel::FollowTail'                 => 0;
requires       'POE::Component::IRC'                    => 0;
requires       'POE::Component::IRC::Plugin::Connector' => 0;
requires       'Net::IP'                                => 0;
requires       'Net::IP::Match::XS'                     => '0.03';
test_requires  'Test::More'                             => '0.47';
test_requires  'File::Spec'                             => '0.82';
install_script 'ammobot';

WriteAll;
