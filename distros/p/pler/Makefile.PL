use inc::Module::Install::DSL 0.99;

all_from       lib/pler.pm
requires_from  lib/pler.pm
requires       blib         0
test_requires  Test::More   0.47
test_requires  Test::Script 1.02
install_script pler
