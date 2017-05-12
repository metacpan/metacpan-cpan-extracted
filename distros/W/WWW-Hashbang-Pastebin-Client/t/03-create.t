use warnings;
use strict;
use Test::More;
use WWW::Hashbang::Pastebin::Client;

plan ($ENV{'TEST_SITE'}
    ? (tests => 3)
    : (skip_all => q{Specify $ENV{'TEST_SITE'} with a webserver running WWW::Hashbang::Pastebin})
);
my $pastebin = $ENV{'TEST_SITE'};
my $client   = WWW::Hashbang::Pastebin::Client->new(url => $pastebin);
my $text     = rand();
my $url      = $client->paste(paste => $text);
note "Created: $url";

like $url, qr{^\Q$pastebin\E/?(.+)}, 'URL approximately correct';

if ($url =~ m{^\Q$pastebin\E/?(.+)}) {
    my $retrieved_text = $client->get($1);
    is $retrieved_text, $text, '$retrieved eq $submitted';
}
else {
    fail "Couldn't parse URL: $url";
}

my $retrieved_text = $client->get($url);
is $retrieved_text, $text, 'text retrieved via full URL = submitted text';
