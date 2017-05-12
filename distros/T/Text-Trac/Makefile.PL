use inc::Module::Install;

name('Text-Trac');
all_from('lib/Text/Trac.pm');
license 'perl';

test_requires('Test::Base');
test_requires('Test::More');

#test_requires('Test::Differences');

requires('UNIVERSAL::require');
requires('Class::Accessor::Fast');
requires('Class::Data::Inheritable');
requires('Tie::IxHash');
requires('List::MoreUtils');
requires('HTML::Entities');
requires('Path::Tiny');

no_index( package => 'TestMacro' );

install_script 'script/trac2html';

auto_install;

repository 'https://github.com/szabgab/Text-Trac';

WriteAll;
