use v5.14;
use warnings;
use Test::More;
use t::Builder;

subtest 'urls' => sub {
    my $entity = onevent(
        {   target_object => {
                user   => { screen_name => 'nekokak', },
                id_str => '134608526650777603',
            }
        }
    );
    my @urls = $entity->urls;
    is_deeply \@urls,
        ['https://twitter.com/#!/nekokak/status/134608526650777603'];

};

done_testing;
