use inc::Module::Install;

name     'Tie-JCR';
all_from 'lib/Tie/JCR.pm';

requires 'Java::JCR';

auto_install;
WriteAll;
