# in a separate test file
 
BEGIN {
    unless ($ENV{RELEASE_TESTING})
    {
        use Test::More;
        plan(skip_all => 'these tests are for release candidate testing');
    }
}
 
use Test::Kwalitee;
