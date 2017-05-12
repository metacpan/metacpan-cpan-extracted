use strict;
use warnings;

use lib 't/lib';

use List::Util qw( first );
use Test::More 0.96;
use Test::Fatal;

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

    my $git_project = first { $_->id eq 'TeamCityPluginsByJetBrains_Git' }
    @{ $client->projects };
    my $build_type = first {
        $_->id eq
            'TeamCityPluginsByJetBrains_Git_JetBrainsGitPluginTeamCity91x'
    }
    @{ $git_project->build_types };

    my $builds_iter = $build_type->builds;
    my $build;
    while ( my $t = $builds_iter->next ) {
        if ( $t->id eq '661984' ) {
            $build = $t;
            last;
        }
    }

    my $artifacts = $build->artifacts_dir;

    ok(
        $artifacts->is_dir,
        'got a directory (that exists) from artifacts_dir'
    );

    my @children = $artifacts->children;
    is(
        scalar @children, 1,
        'unzipped artifacts dir has 1 child'
    );
    is(
        $children[0]->basename, 'test-results',
        'unzipped artifacts dir has a test-results subdir'
    );

    my %files = map { $_->basename => $_ } $children[0]->children;
    is(
        scalar keys %files, 2,
        'test-results dir has 2 files'
    );
    is_deeply(
        [ sort keys %files ],
        [qw( result-1.json result-2.txt )],
        'files have the expected names'
    );
    is(
        $files{'result-2.txt'}->slurp,
        "Some text in a file\n",
        'result-2.txt contains the expected content'
    );
}

done_testing();
