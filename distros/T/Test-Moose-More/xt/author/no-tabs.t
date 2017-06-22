use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Test/Moose/More.pm',
    'lib/Test/Moose/More/Utils.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/attribute_options_ok/basic.t',
    't/attribute_options_ok/subtest-wrapper.t',
    't/check_sugar.t',
    't/does_metaroles_ok.t',
    't/does_not_metaroles_ok.t',
    't/does_not_ok.t',
    't/does_ok.t',
    't/has_attribute_ok.t',
    't/is_anon_ok.t',
    't/is_class_ok/basic.t',
    't/is_class_ok/moose-meta-attribute-should-be-moosey.t',
    't/is_immutable_ok.t',
    't/is_not_anon_ok.t',
    't/is_role_ok.t',
    't/meta_ok.t',
    't/method_from_pkg_ok.t',
    't/method_is_accessor_ok.t',
    't/method_is_not_accessor_ok.t',
    't/method_not_from_pkg_ok.t',
    't/method_ok.t',
    't/no_meta_ok.t',
    't/pristine_ok.t',
    't/requires_method_ok.t',
    't/subtest-1.t',
    't/validate_attribute/basic.t',
    't/validate_attribute/coerce.t',
    't/validate_attribute/in_roles.t',
    't/validate_attribute/lazy.t',
    't/validate_attribute/required.t',
    't/validate_class/basic.t',
    't/validate_class/metaclasses.t',
    't/validate_class/metaroles.t',
    't/validate_class/methods.t',
    't/validate_role/basic.t',
    't/validate_role/compose.t',
    't/validate_role/metaclasses.t',
    't/validate_role/metaroles.t',
    't/validate_thing/metaclasses.t',
    't/validate_thing/methods.t',
    't/validate_thing/sugar.t',
    't/wrapped/in_roles.t'
);

notabs_ok($_) foreach @files;
done_testing;
