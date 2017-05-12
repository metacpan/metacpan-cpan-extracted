use strict;
use warnings;

use Test::More tests => 1;

use XML::SemanticDiff;

my $first_item_is_t = <<"EOF";
<s>
    <p>
        T
    </p>
    <p>
        G
    </p>
</s>
EOF

my $first_item_is_f = <<"EOF";
<s>
    <p>
        F
    </p>
    <p>
        G
    </p>
</s>
EOF

my $diff = XML::SemanticDiff->new();

my @results = $diff->compare($first_item_is_t, $first_item_is_f);

# TEST
is (scalar(@results), 1, "Making sure there's one difference in the XML");

1;


