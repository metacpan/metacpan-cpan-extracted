use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use autobox::Core;

use lib "lib";
use autobox::Transform;

use lib "t/lib";
use Literature;

my $literature = Literature::literature();
my $authors    = $literature->{authors};

subtest uniq_by => sub {
    note "ArrayRef call, list context result";
    eq_or_diff(
        [ map { $_->name } $authors->uniq_by("is_prolific") ],
        [
            "James A. Corey", # true
            "Cixin Liu",      # false
        ],
        "uniq_by simple method call works",
    );

    eq_or_diff(
        [ map { $_->name } $authors->uniq_by([ "is_prolific" ]) ],
        [
            "James A. Corey", # true
            "Cixin Liu",      # false
        ],
        "uniq_by simple method call works",
    );
};



done_testing();
