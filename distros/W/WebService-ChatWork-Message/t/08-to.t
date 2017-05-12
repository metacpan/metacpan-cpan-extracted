use strict;
use warnings;
use WebService::ChatWork::Message;
use Test::More tests => 2;

my $to = WebService::ChatWork::Message->new(
    to => 3,
);
is( "$to", "[To:3]" );

my $to_name = WebService::ChatWork::Message->new(
    to => (
        account_id   => 4,
        account_name => "asdf",
    ),
);
is( "$to_name", "[To:4] asdf" );
