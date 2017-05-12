use inc::Module::Install;

name        'WWW-Dict-TWMOE-Phrase';
all_from    'lib/WWW/Dict/TWMOE/Phrase.pm';

requires
    'WWW::Dict'    => '0.0.1',
    'Class::Field' => 0,
    'WWW::Mechanize' => 0,
    'Encode' => 0,
    'HTML::TagParser' =>0,
    'HTML::TableExtract' => 0;

build_requires 'Test::More' => 0;

install_script  'bin/dict-twmoe';

auto_install;
WriteAll;

