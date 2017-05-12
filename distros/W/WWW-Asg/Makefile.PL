use inc::Module::Install;

# Define metadata
name 'WWW-Asg';
all_from 'lib/WWW/Asg.pm';

perl_version '5.008';

requires 'LWP::UserAgent'             => '6.04';
requires 'Carp'                       => '1.25';
requires 'Digest::MD5'                => '2.39';
requires 'HTML::TreeBuilder::XPath'   => '0.14';
requires 'Encode'                     => '2.35';
requires 'URI'                        => '1.59';
requires 'DateTime::Format::ISO8601'  => '0.08';
requires 'DateTime::Format::Strptime' => '1.5000';

test_requires 'Test::More' => '0.80';

WriteAll;
