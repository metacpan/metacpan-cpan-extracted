use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WWW/FieldValidator.pm',
    'lib/WWW/Form.pm',
    't/00-compile.t',
    't/00-load.t',
    't/distro_integrity.t',
    't/dummy.t',
    't/get_field.t',
    't/hidden-elements.t',
    't/html-form-gen.t',
    't/html-gen.t',
    't/lib/CondTestMore.pm',
    't/pod-coverage.t',
    't/pod.t',
    't/regex.t',
    't/render_attributes.t',
    't/set_fields.t',
    't/validate-email.t'
);

notabs_ok($_) foreach @files;
done_testing;
