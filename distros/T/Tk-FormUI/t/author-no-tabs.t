
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Tk/FormUI.pm',
    'lib/Tk/FormUI/Choices.pm',
    'lib/Tk/FormUI/Field.pm',
    'lib/Tk/FormUI/Field/Checkbox.pm',
    'lib/Tk/FormUI/Field/Combobox.pm',
    'lib/Tk/FormUI/Field/Directory.pm',
    'lib/Tk/FormUI/Field/Entry.pm',
    'lib/Tk/FormUI/Field/Radiobutton.pm',
    't/00-compile.t',
    't/90-add_fields.t',
    't/91-initialize_form.t',
    't/author-critic.t',
    't/author-no-tabs.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-test-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
