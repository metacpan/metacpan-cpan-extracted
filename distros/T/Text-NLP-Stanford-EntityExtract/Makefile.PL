use inc::Module::Install;

name     'Text-NLP-Stanford-EntityExtract';
all_from 'lib/Text/NLP/Stanford/EntityExtract.pm';
author   'Kieren Diment <zarquon@cpan.org>';
license  'GPL';

build_requires 'Test::More';
requires 'Mouse';
requires 'Text::Unidecode';

auto_install;

WriteAll;

