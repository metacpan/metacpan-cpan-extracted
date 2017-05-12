use inc::Module::Install::DSL 0.83;

all_from      lib/Test/SubCalls.pm
requires_from lib/Test/SubCalls.pm
test_requires Test::Builder::Tester 1.02
