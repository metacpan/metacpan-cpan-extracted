use inc::Module::Install;
use strict;
use warnings;

name 'Text-EmacsColor';
all_from 'lib/Text/EmacsColor.pm';

requires 'File::ShareDir';
requires 'File::Temp';
requires 'Mouse';
requires 'Path::Class';
requires 'namespace::clean';

#require_if 'XML::LibXML' => 'DOM result support';
#require_if 'CSS::Tiny' => 'Parsed CSS result support';

build_requires 'Devel::Hide';
build_requires 'Test::More';
build_requires 'ok';

install_share 'share';

requires_external_bin 'emacs';

WriteAll();
