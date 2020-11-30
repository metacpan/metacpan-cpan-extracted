
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit;
    }
}

use Test::More;
use Test::MinimumVersion;
all_minimum_version_ok('5.014000');
