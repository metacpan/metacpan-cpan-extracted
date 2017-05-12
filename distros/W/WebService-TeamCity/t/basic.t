use strict;
use warnings;

use lib 't/lib';

use Test::More 0.96;
use Test::Fatal;

use DateTime;
use Test::UA qw( ua );
use WebService::TeamCity;

my $ua = ua();

{
    my $client = WebService::TeamCity->new(
        host     => 'example.com',
        user     => 'u',
        password => 'p',
        ua       => $ua,
    );

    my $git   = test_projects($client);
    my $build = test_build_types($git);
    my $test  = test_build($build);
    test_test_occurrence($test);
}

{
    my $client = WebService::TeamCity->new(
        host     => 'example.com',
        user     => 'u',
        password => 'p',
        ua       => $ua,
    );

    subtest(
        'all build types',
        sub {
            my $build_types = $client->build_types;
            is(
                scalar @{$build_types},
                536,
                'got 536 build types'
            );
        }
    );

    subtest(
        'all builds',
        sub {
            my $builds = $client->builds;
            my @builds;
            while ( my $build = $builds->next ) {
                push @builds, $build;
            }
            is(
                scalar @builds,
                200,
                'found 200 builds'
            );
        }
    );

    subtest(
        'iterator for empty result',
        sub {
            my $builds = $client->builds( id => 'has-no-builds' );
            my $build;
            is(
                exception { $build = $builds->next },
                undef,
                'can call next on iterator'
            );
            is( $b, undef, 'next returns undef' );
        }
    );
}

done_testing();

sub test_projects {
    my $client = shift;

    my $projects = $client->projects;
    is(
        scalar @{$projects},
        159,
        'got 159 projects'
    );

    my %by_id = map { $_->id => $_ } @{$projects};
    ok( $by_id{_Root}, 'found a project where id = _Root' );
    ok(
        $by_id{TeamCityPluginsByJetBrains_Git},
        'found a project where id = TeamCityPluginsByJetBrains_Git'
    );

    my $root = $by_id{_Root};
    subtest(
        '_Root project attributes',
        sub {
            test_attr(
                $root,
                name        => '<Root project>',
                description => 'Contains all other projects',
                href        => '/httpAuth/app/rest/projects/id:_Root',
                web_url =>
                    'https://teamcity.jetbrains.com/project.html?projectId=_Root',
            );
        }
    );

    is(
        $root->parent_project,
        undef,
        'root has no parent project'
    );

    my $children = $root->child_projects;
    is(
        scalar @{$children},
        45,
        'root has 45 child projects'
    );
    isa_ok(
        $children->[0],
        'WebService::TeamCity::Entity::Project',
        'first project'
    );

    my $git = $by_id{TeamCityPluginsByJetBrains_Git};
    is(
        $git->parent_project->id,
        'TeamCityPluginsByJetBrains',
        'parent project for git plugin project is TeamCityPluginsByJetBrains'
    );

    is_deeply(
        $git->child_projects,
        [],
        'git plugin project has no child projects',
    );

    return $git;
}

sub test_build_types {
    my $git = shift;

    my $build_types = $git->build_types;
    is(
        scalar @{$build_types},
        5,
        'git project has 5 build types'
    );

    my $git_build_91 = $build_types->[0];
    isa_ok(
        $git_build_91,
        'WebService::TeamCity::Entity::BuildType',
        'first build type'
    );

    subtest(
        'build type for git plugin with TC 9.1',
        sub {
            test_attr(
                $git_build_91,
                href =>
                    '/httpAuth/app/rest/buildTypes/id:TeamCityPluginsByJetBrains_Git_JetBrainsGitPluginTeamCity91x',
                id =>
                    'TeamCityPluginsByJetBrains_Git_JetBrainsGitPluginTeamCity91x',
                web_url =>
                    'https://teamcity.jetbrains.com/viewType.html?buildTypeId=TeamCityPluginsByJetBrains_Git_JetBrainsGitPluginTeamCity91x',
            );
        }
    );

    is(
        $git_build_91->project->id,
        'TeamCityPluginsByJetBrains_Git',
        'git build type returns expected project'
    );

    my $builds_iter = $git_build_91->builds;
    my @builds;
    while ( my $build = $builds_iter->next ) {
        push @builds, $build;
    }
    is(
        scalar @builds,
        22,
        'found 22 builds for build type'
    );

    return $builds[0];
}

sub test_build {
    my $build = shift;

    subtest(
        'first build for git build type',
        sub {
            test_attr(
                $build,
                branch_name => 'refs/heads/Hajipur-9.1.x',
                finish_date => DateTime->new(
                    year      => 2016,
                    month     => 1,
                    day       => 13,
                    hour      => 17,
                    minute    => 38,
                    second    => 56,
                    time_zone => '+0300',
                ),
                href        => '/httpAuth/app/rest/builds/id:667885',
                id          => 667885,
                number      => 'snapshot-43',
                queued_date => DateTime->new(
                    year      => 2016,
                    month     => 1,
                    day       => 13,
                    hour      => 17,
                    minute    => 29,
                    second    => 16,
                    time_zone => '+0300',
                ),
                start_date => DateTime->new(
                    year      => 2016,
                    month     => 1,
                    day       => 13,
                    hour      => 17,
                    minute    => 29,
                    second    => 19,
                    time_zone => '+0300',
                ),
                state  => 'finished',
                status => 'SUCCESS',
                web_url =>
                    'https://teamcity.jetbrains.com/viewLog.html?buildId=667885&buildTypeId=TeamCityPluginsByJetBrains_Git_JetBrainsGitPluginTeamCity91x',
            );
            test_bool_attr(
                $build,
                default_branch => 1,
                passed         => 1,
                failed         => 0,
            );
        }
    );

    is(
        $build->build_type->id,
        'TeamCityPluginsByJetBrains_Git_JetBrainsGitPluginTeamCity91x',
        'build has expected build type'
    );

    my $occurrences = $build->test_occurrences;
    isa_ok(
        $occurrences,
        'WebService::TeamCity::Iterator',
        '$build->test_occurrences'
    );

    my @tests;
    while ( my $t = $occurrences->next ) {
        push @tests, $t;
    }
    is(
        scalar @tests,
        224,
        'found 224 test occurrences for build'
    );

    return $tests[0];
}

sub test_test_occurrence {
    my $test = shift;

    subtest(
        'first test occurrence',
        sub {
            test_attr(
                $test,
                details => q{},
                href =>
                    '/httpAuth/app/rest/testOccurrences/id:677,build:(id:667885)',
                name =>
                    'Git Suite: jetbrains.buildServer.buildTriggers.vcs.git.tests.AuthSettingsTest.auth_uri_for_anonymous_protocol_should_not_have_user_and_password',
                status => 'SUCCESS',
            );
            test_bool_attr(
                $test,
                passed => 1,
                failed => 0,
            );
        }
    );

    my $build_from_test = $test->build;
    isa_ok(
        $build_from_test,
        'WebService::TeamCity::Entity::Build',
        '$test->build'
    );
    is(
        $build_from_test->id,
        667885,
        'got expected build from test occurrence'
    );
}

sub test_attr {
    my $entity = shift;
    my %expect = @_;

    for my $attr ( sort keys %expect ) {
        is(
            $entity->$attr,
            $expect{$attr},
            $attr
        );
    }
}

sub test_bool_attr {
    my $entity = shift;
    my %expect = @_;

    for my $attr ( sort keys %expect ) {
        if ( $expect{$attr} ) {
            ok(
                $entity->$attr,
                $attr
            );
        }
        else {
            ok(
                !$entity->$attr,
                $attr
            );
        }
    }
}

