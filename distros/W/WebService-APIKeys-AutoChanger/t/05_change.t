use strict;
use warnings;
use WebService::APIKeys::AutoChanger;
use Test::More tests => 1;

my $changer = WebService::APIKeys::AutoChanger->new;

$changer->set(
    api_keys =>
      [ 'aaaaaaaaaaaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbb', 'ccccccccccccccccccc', ],
    throttle_config => {
        max_items => 3,
        interval  => 5,
    }
);

my @keys;
diag("sleeping for 10 seconds...");
for ( 1 .. 10 ) {
    sleep 1;
    my $key = $changer->get_available;
    push( @keys, $key );
}

my $correct = [
    'aaaaaaaaaaaaaaaaaaa', 'aaaaaaaaaaaaaaaaaaa',
    'aaaaaaaaaaaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbb',
    'bbbbbbbbbbbbbbbbbbb', 'bbbbbbbbbbbbbbbbbbb',
    'ccccccccccccccccccc', 'ccccccccccccccccccc',
    'ccccccccccccccccccc', 'aaaaaaaaaaaaaaaaaaa'
];

is_deeply( \@keys, $correct );