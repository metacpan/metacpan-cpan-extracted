#!/usr/bin/env perl

# failing test from [1] when Moo::with (or Moose::with) indirectly `require`s a
# module which a) uses true.pm (and doesn't return a true value)
# and b) defines a function or method with Function::Parameters.
#
# this results in the following error:
#
#     RoleWithMethod.pm did not return a true value at Module/Runtime.pm line 314.
#
# the offending line calls:
#
#     return scalar(CORE::require(&module_notional_filename));
#
# via:
#
#     Moo::with("RoleWithMethod")
#         -> Moo::Role::apply_roles_to_package("Moo::Role", "main", "RoleWithMethod")
#         -> Moo::_Utils::_load_module("RoleWithMethod")
#         -> Module::Runtime::use_package_optimistically("RoleWithMethod")
#         -> eval {...}
#         -> Module::Runtime::require_module("RoleWithMethod")
#
# - the error doesn't occur if the module is `require`d.
# - the error doesn't occur on perl v5.24 and above.
# - the error doesn't occur if returning true is forced (in the XS) in cases
#   where the value is already truthy.
#
# [1] https://rt.cpan.org/Public/Bug/Display.html?id=124745

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More;

use lib (File::Spec->catdir($Bin, 'lib'));

if ($] >= 5.014000) {
    plan tests => 2;
} else {
    plan skip_all => 'Function::Parameters requires perl >= 5.14.0'
}

eval 'use Moo'; # XXX I can't get this to work with require + import
eval { with('RoleWithMethod') };

is $@, '', 'Moo(se)::with: module using Moo::Role and Function::Parameters';
is eval { RoleWithMethod::test() }, 42, 'require: module loaded OK';
