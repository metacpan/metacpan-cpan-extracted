use strict;
use warnings;
use Test::More;
use Test::Builder;
use utf8;

BEGIN {
    use_ok("Web::Dash::Lens");
}

my @lenses_destroyed = ();

package Web::Dash::Lens;
use strict;
use warnings;

sub DESTROY {
    my ($self) = @_;
    push(@lenses_destroyed, $self->service_name);
}


package main;

sub test_search_results {
    my ($got_results, $entry_num_cmp, $entry_num_base, $label) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $label ||= "";
    cmp_ok(int(@$got_results), $entry_num_cmp, $entry_num_base, "$label: results num OK");
    foreach my $i (0 .. $#$got_results) {
        my $r = $got_results->[$i];
        foreach my $key (qw(uri icon_hint category_index mimetype name comment dnd_uri)) {
            ok(defined($r->{$key}), "$label: $key defined");
        }
    }
}

my @test_cases = (
    {
        lens_file => '/usr/share/unity/lenses/applications/applications.lens',
        exp_service_name => 'com.canonical.Unity.Lens.Applications',
        exp_object_name => '/com/canonical/unity/lens/applications',
        exp_search_hint => 'アプリケーションの検索',
        search_cases => [
            {query => "term", exp_cmp => ['>', 0]},
            {label => '"term" again', query => 'term', exp_cmp => ['>', 0]},
            {query => 'hoge', exp_cmp => ['==', 0]},
        ]
    },
    {
        lens_file => '/usr/share/unity/lenses/files/files.lens',
        exp_service_name => 'com.canonical.Unity.Lens.Files',
        exp_object_name => '/com/canonical/unity/lens/files',
        exp_search_hint => 'ファイルとフォルダーの検索',
        search_cases => [
            {query => 'a', exp_cmp => ['>=', 0]},
            {query => 'b', exp_cmp => ['>=', 0]},
        ]
    },
    {
        lens_file => '/usr/share/unity/lenses/extras-unity-lens-github/extras-unity-lens-github.lens',
        exp_service_name => 'unity.singlet.lens.github',
        exp_object_name => '/unity/singlet/lens/github',
        exp_search_hint => 'Search Github',
        search_cases => [
            {query => 'web dash', exp_cmp => ['>', 0]},
            {query => 'async queue', exp_cmp => ['>', 0]},
        ]
    },
    {
        lens_file => '/usr/share/unity/lenses/video/video.lens',
        exp_service_name => 'net.launchpad.lens.video',
        exp_object_name => '/net/launchpad/lens/video',
        exp_search_hint => '動画の検索',
        search_cases => [
            {query => 'hoge', exp_cmp => ['>', 0]},
            {query => 'foo', exp_cmp => ['>', 0]},
        ]
    }
);


foreach my $case (@test_cases) {
    note("--- --- case lens_file = $case->{lens_file}");
    @lenses_destroyed = ();
    my $service_name = $case->{exp_service_name};
    {
        note("--- from lens file");
        my $lens = new_ok('Web::Dash::Lens', [lens_file => $case->{lens_file}]);
        is($lens->service_name, $case->{exp_service_name}, 'service name OK');
        is($lens->object_name, $case->{exp_object_name}, 'object name OK');
        is($lens->search_hint_sync, $case->{exp_search_hint}, "search_hint_sync OK");
        is($lens->search_hint_sync, $case->{exp_search_hint}, "search_hint_sync OK again");
    }
    is(int(@lenses_destroyed), 1, "1 lens destroyed.");
    is($lenses_destroyed[0], $service_name, "... and it's $service_name");

    @lenses_destroyed = ();
    {
        note('--- from service_name and object_name');
        my $lens = new_ok('Web::Dash::Lens', [
            service_name => $case->{exp_service_name},
            object_name => $case->{exp_object_name},
        ]);
        is($lens->search_hint_sync, $case->{exp_search_hint}, "search_hint_sync OK");
    }
    is(int(@lenses_destroyed), 1, "1 lens destroyed.");
    is($lenses_destroyed[0], $service_name, "... and it's $service_name");
    
    @lenses_destroyed = ();
    {
        my $lens = new_ok('Web::Dash::Lens', [lens_file => $case->{lens_file}]);
        foreach my $search_case (@{$case->{search_cases}}) {
            my $label = $search_case->{label} || qq{"$search_case->{query}"};
            test_search_results([$lens->search_sync($search_case->{query})], @{$search_case->{exp_cmp}}, $label);
        }
    }
    is(int(@lenses_destroyed), 1, "1 lens destroyed.");
    is($lenses_destroyed[0], $service_name, "... and it's $service_name");
}

done_testing();


