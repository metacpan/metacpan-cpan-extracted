use 5.006;
use inc::Module::Install;

all_from 'lib/Text/Quoted.pm';
readme_from 'lib/Text/Quoted.pm';

requires 'Text::Autoformat';
requires 'Text::Tabs';

sign;
WriteAll;
