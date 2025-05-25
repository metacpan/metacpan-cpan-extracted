# -*- perl -*-
BEGIN
{
    use lib qw( ./blib/lib ./blib/arch ./lib ./t/lib );
    use Test::More;
    unless( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} )
    {
        plan(skip_all => 'These tests are for author or release candidate testing');
    }
}

eval { require Test::Kwalitee; Test::Kwalitee->import() };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
