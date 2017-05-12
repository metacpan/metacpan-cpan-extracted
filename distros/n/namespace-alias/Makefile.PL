use strict;
use warnings;
use inc::Module::Install;
use ExtUtils::Depends;

name 'namespace-alias';
all_from 'lib/namespace/alias.pm';

requires 'XSLoader';
requires 'Class::MOP';
requires 'B::Hooks::EndOfScope';
requires 'B::Hooks::OP::Check' => '0.11';

configure_requires 'ExtUtils::Depends';
configure_requires 'B::Hooks::OP::Check' => '0.11';

build_requires 'B::Hooks::OP::Check' => '0.11';

test_requires 'Test::More' => '0.88';

my $pkg = ExtUtils::Depends->new('namespace::alias', 'B::Hooks::OP::Check');
$pkg->add_xs('alias.xs');
$pkg->add_pm('lib/namespace/alias.pm' => '$(INST_LIB)/namespace/alias.pm');

makemaker_args($pkg->get_makefile_vars);

WriteAll;
