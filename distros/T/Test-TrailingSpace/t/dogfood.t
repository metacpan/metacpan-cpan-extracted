use strict;
use warnings;

use Test::More tests => 1;

use Test::TrailingSpace ();

my $finder = Test::TrailingSpace->new(
    {
        find_cr           => 1,
        find_tabs         => 1,
        root              => '.',
        filename_regex    => qr/(?:\.(?:t|pm|pl|PL|yml|json))|README|Changes\z/,
        abs_path_prune_re => qr/(?i:(?:(?:MYMETA\.(json|yml)\z)|sample-data))/,
    },
);

# TEST
$finder->no_trailing_space("No trailing space was found.");
