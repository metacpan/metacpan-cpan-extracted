use inc::Module::Install;

# Define metadata
name           'YAHC';
all_from       'lib/YAHC.pm';
license        'perl';

# Specific dependencies
requires       'EV'                                 => '0';
requires       'POSIX'                              => '0';
requires       'Fcntl'                              => '0';
requires       'Socket'                             => '0';
requires       'IO::Socket::SSL'                    => '0';
requires       'Scalar::Util'                       => '0';
requires       'Time::HiRes'                        => '0';

test_requires  'Test::More'                         => '0.88';
test_requires  'Test::Exception'                    => '0';
test_requires  'Test::Memory::Cycle'                => '0';
test_requires  'Plack::Handler::Starman'            => '0';
test_requires  'IO::Socket::INET'                   => '0';
test_requires  'Data::Dumper'                       => '0';
test_requires  'Time::HiRes'                        => '0';
test_requires  'HTTP::Tiny'                         => '0';
test_requires  'Net::Ping'                          => '2.41';
test_requires  'List::Util'                         => '0';
test_requires  'FindBin'                            => '0';
test_requires  'Plack'                              => '0';
test_requires  'JSON'                               => '0';

# metadata for the github repo
repository 'https://github.com/ikruglov/YAHC';

WriteAll;
