use strict;
use warnings;
use Test::More 0.82 tests => 3;

BEGIN {
    use_ok('WWW::Hashbang::Pastebin::Client');
}

my $app = new_ok('WWW::Hashbang::Pastebin::Client', [url => 'http://0.0.0.0:3000']);
can_ok($app, qw(new paste put get retrieve));
