use inc::Module::Install;

perl_version    '5.008001';
name            'WWW-Mechanize-TreeBuilder';
all_from        'lib/WWW/Mechanize/TreeBuilder.pm';
license         'perl';

resources repository => 'http://github.com/ashb/WWW-Mechanize-TreeBuilder',
          bugtracker => 'https://github.com/ashb/WWW-Mechanize-TreeBuilder/issues';

requires        'Moose'                          => '2.1200';
requires        'HTML::TreeBuilder';
requires        'Scalar::Util';
requires        'MooseX::Role::Parameterized';

build_requires  'Test::More';
build_requires  'Test::WWW::Mechanize';

no_index        directory => 't/lib';

WriteAll;
