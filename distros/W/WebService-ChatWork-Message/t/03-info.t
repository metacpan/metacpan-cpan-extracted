use strict;
use warnings;
use WebService::ChatWork::Message;
use Test::More tests => 2;

my $info = WebService::ChatWork::Message->new(
    info => "asdf",
);

is( "$info", "[info]asdf[/info]" );

my $titled_info = WebService::ChatWork::Message->new(
    info => (
        title   => "asdf",
        message => "fdsa",
    ),
);
is( "$titled_info", "[info][title]asdf[/title]fdsa[/info]" );
