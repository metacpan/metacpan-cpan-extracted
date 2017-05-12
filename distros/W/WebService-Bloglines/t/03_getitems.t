use strict;
use Test::More;
use WebService::Bloglines;

unless ($ENV{BLOGLINES_USERNAME}) {
    Test::More->import(skip_all => "no username set, skipped.");
    exit;
}

Test::More->import("no_plan");
binmode Test::More->builder->output, ":utf8";

my $bloglines = WebService::Bloglines->new(
    username => $ENV{BLOGLINES_USERNAME},
    password => $ENV{BLOGLINES_PASSWORD},
);

# list subscriptions
my $subscription = $bloglines->listsubs();

# list all feeds
my @feeds = $subscription->feeds();
my $feed = (grep { $_->{BloglinesUnread} > 0 } @feeds)[0];

my $update = $bloglines->getitems($feed->{BloglinesSubId});

$feed = $update->feed();

ok length($feed->{title}), $feed->{title};
like $feed->{link}, qr!^https?://!, $feed->{link};
ok defined($feed->{description}), $feed->{description};
like $feed->{bloglines}->{siteid}, qr/^\d+$/, "siteid: $feed->{bloglines}->{siteid}";
ok $feed->{language}, $feed->{language};

for my $item ($update->items) {
    ok length($item->{title}), $item->{title};
    ok $item->{dc}->{creator}, $item->{dc}->{creator};
    like $item->{link}, qr!^https?://!, $item->{link};
    like $item->{guid}, qr!^https?://!, $item->{guid};
    ok $item->{description}, "description";
    ok $item->{pubDate}, $item->{pubDate};
    like $item->{bloglines}->{itemid}, qr/^\d+$/, "itemid: $item->{bloglines}->{itemid}";
}

# Try non-modified feed
$feed = (grep { $_->{BloglinesUnread} == 0 } @feeds)[0];
my $foo = $bloglines->getitems($feed->{BloglinesSubId});
is $foo, undef;

# fetch all in single getitems
my @updates = $bloglines->getitems(0);
for my $update (@updates) {
    ok defined($update->feed->{title}), $update->feed->{title};
    my $item = ($update->items)[0];
    ok defined($item->{link}), "link: $item->{link}";
}

