use inc::Module::Install::DSL 1.01;

all_from      lib/Test/POE/Stopping.pm
requires_from lib/Test/POE/Stopping.pm
requires      POE::API::Peek 2.17
