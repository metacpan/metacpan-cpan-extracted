use inc::Module::Install;

name     'WebService-XING';
all_from 'lib/WebService/XING.pm';
license  'perl';

perl_version '5.010000';

test_requires 'Test::More';
test_requires 'Test::Exception';

requires 'Encode::StdIO';
requires 'File::HomeDir';
requires 'HTTP::Headers';
requires 'HTTP::Request';
requires 'JSON' => 2;
requires 'LWP::UserAgent';
requires 'Mo' => 0.30;
requires 'Net::OAuth';
requires 'Term::Encoding';
requires 'URI';
requires 'YAML';

resources(
    homepage   => 'https://github.com/augensalat/webservice-xing',
    repository => 'git://github.com/augensalat/webservice-xing.git',
);

install_script 'script/xing';

auto_install;

WriteAll;
