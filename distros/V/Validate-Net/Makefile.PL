use inc::Module::Install 0.75;

all_from 'lib/Validate/Net.pm';
requires 'Class::Default' => '0.02';
requires 'Test::More'     => '0.42';

WriteAll;
