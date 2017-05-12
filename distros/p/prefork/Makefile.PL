use inc::Module::Install::DSL 0.91;

all_from      lib/prefork.pm
requires_from lib/prefork.pm
test_requires Test::More 0.47
test_requires File::Spec 0.80
