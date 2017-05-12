
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use Test::Whitespaces {
    dirs => [qw(
        example
        lib
        t
        xt
    )],
    files => [qw(
        Changes
        README
        dist.ini
    )],
};
