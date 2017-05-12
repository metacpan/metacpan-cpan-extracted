use inc::Module::Install;

name 'Test-Pod-Coverage-Permissive';
all_from 'lib/Test/Pod/Coverage/Permissive.pm';
requires 'Test::More' => 0.88;
requires 'YAML::Syck';
requires 'File::Spec';
requires 'Pod::Coverage';
auto_provides;
auto_install;
WriteAll();
