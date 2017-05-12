use inc::Module::Install;
name 'URI-urn-uuid';
all_from 'lib/URI/urn/uuid.pm';
requires 'URI';
requires 'Data::UUID';
build_requires 'Test::More';
auto_include;
WriteAll;
