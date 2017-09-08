use Test::More;

BEGIN {
    use_ok 'WebService::NextEpisode';
}

my $content = WebService::NextEpisode::of("Better Call Saul");

ok $content;

done_testing;


