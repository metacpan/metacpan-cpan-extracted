use strict;
use warnings;
use WebService::ChatWork::Message;
use Test::More tests => 2;

my $qt = WebService::ChatWork::Message->new(
    qt => (
        account_id => 3,
        message    => "asdf",
    ),
);
is( "$qt", "[qt][qtmeta aid=3]asdf[/qt]" );

my $qt_time = WebService::ChatWork::Message->new(
    qt => (
        account_id => 4,
        message    => "fdsa",
        time       => "10",
    ),
);
is( "$qt_time", "[qt][qtmeta aid=4 time=10]fdsa[/qt]" );
