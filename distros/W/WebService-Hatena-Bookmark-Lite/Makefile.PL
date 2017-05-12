use inc::Module::Install;
name 'WebService-Hatena-Bookmark-Lite';
all_from 'lib/WebService/Hatena/Bookmark/Lite.pm';

requires (
    'Config::Pit'           => '0.03',
    'Digest::SHA1'          => '2.12',
    'DateTime'              => '0.50',
    'XML::Atom'             => '0.35',
    'Class::Accessor::Fast' => '0.33',
);

tests 't/*.t';
#author_tests 'xt';

build_requires 'Test::More';
auto_include;
WriteAll;
