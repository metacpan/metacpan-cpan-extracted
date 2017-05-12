use inc::Module::Install;

name         'Text-RecordParser';
abstract     'Parse record-oriented data in a text file';
version_from 'lib/Text/RecordParser.pm';
author       'Ken Youens-Clark <kclark@cpan.org>';
license      'gpl';

requires 'IO::Scalar';
requires 'Class::Accessor';
requires 'Readonly';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'Text::Autoformat';

build_requires 'Test::More';
build_requires 'Test::Exception';

recommends 'Text::TabularDisplay' => '1.22';
recommends 'GraphViz'             => 0;

install_script 'bin/tablify'; 
install_script 'bin/tabmerge';
install_script 'bin/tab2graph';

WriteAll;
