use inc::Module::Install;
name 'Test-Groonga';
all_from 'lib/Test/Groonga.pm';

requires 'File::Spec';
requires 'File::Temp';
requires 'File::Which';
requires 'Test::TCP' => 1.10;

test_requires 'File::Temp';
test_requires 'Path::Class';
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'LWP::UserAgent';

WriteAll;
