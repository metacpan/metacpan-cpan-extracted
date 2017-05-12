use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Web::Dash::Lens;

my @test_cases = (
    {
        lens_file => '/usr/share/unity/lenses/applications/applications.lens',
    },
    {
        lens_file => '/usr/share/unity/lenses/files/files.lens',
    },
    {
        lens_file => '/usr/share/unity/lenses/extras-unity-lens-github/extras-unity-lens-github.lens',
    },
);

my $CATEGORY_INDEX_MAX = 1000;

foreach my $case (@test_cases) {
    note("---- case: $case->{lens_file}");
    my $lens = new_ok('Web::Dash::Lens', [lens_file => $case->{lens_file}]);
    my @categories = ();
    try {
        my $index = 0;
        while(1) {
            if($index >= $CATEGORY_INDEX_MAX) {
                fail("Too large category index");
                last;
            }
            push(@categories, $lens->category_sync($index));
            $index++;
        }
    } catch {
        pass("Done loop with exception");
    };
    cmp_ok(int(@categories), ">", 0, "there is at least one category");
    foreach my $category (@categories) {
        foreach my $key (qw(name icon_hint renderer)) {
            ok(exists($category->{$key}), "key $key exists");
        }
    }
    note(explain @categories);
}

done_testing();


