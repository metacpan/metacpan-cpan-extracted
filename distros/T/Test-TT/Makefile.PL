use inc::Module::Install;

name          'Test-TT';
all_from      'lib/Test/TT.pm';

requires 'Template';

WriteAll;

