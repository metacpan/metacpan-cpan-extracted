
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/XML/Ant/BuildFile/Element/Arg.pm',
    'lib/XML/Ant/BuildFile/Project.pm',
    'lib/XML/Ant/BuildFile/Resource.pm',
    'lib/XML/Ant/BuildFile/Resource/FileList.pm',
    'lib/XML/Ant/BuildFile/Resource/Path.pm',
    'lib/XML/Ant/BuildFile/ResourceContainer.pm',
    'lib/XML/Ant/BuildFile/Role/HasProjects.pm',
    'lib/XML/Ant/BuildFile/Role/InProject.pm',
    'lib/XML/Ant/BuildFile/Target.pm',
    'lib/XML/Ant/BuildFile/Task.pm',
    'lib/XML/Ant/BuildFile/Task/Concat.pm',
    'lib/XML/Ant/BuildFile/Task/Copy.pm',
    'lib/XML/Ant/BuildFile/Task/Java.pm',
    'lib/XML/Ant/BuildFile/TaskContainer.pm',
    'lib/XML/Ant/Properties.pm',
    't/00-compile.t',
    't/000-report-versions.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/concat.t',
    't/copy_filelist.t',
    't/filelist.t',
    't/filelist.xml',
    't/java.t',
    't/java.xml',
    't/java_args.t',
    't/path.t',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-portability.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-unused-vars.t',
    't/yui-build.xml'
);

notabs_ok($_) foreach @files;
done_testing;
