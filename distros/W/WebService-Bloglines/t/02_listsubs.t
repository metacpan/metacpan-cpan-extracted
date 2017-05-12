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

my $num = scalar @feeds;
ok $num, "$num feeds";

for my $feed (@feeds) {
    ok length($feed->{title}), $feed->{title};
    like $feed->{htmlUrl}, qr!^https?://!, $feed->{htmlUrl} if $feed->{htmlUrl};
    is $feed->{type}, "rss", $feed->{type};
    like $feed->{xmlUrl}, qr!^https?://!, $feed->{xmlUrl} if $feed->{xmlUrl};
    like $feed->{BloglinesSubId}, qr/^\d+$/,  "subId: $feed->{BloglinesSubId}";
    like $feed->{BloglinesUnread}, qr/^\d+$/, "unread:$feed->{BloglinesUnread}";
    like $feed->{BloglinesIgnore}, qr/^\d+$/, "ignore: $feed->{BloglinesIgnore}";
}

# list folders
my @folders = $subscription->folders();
for my $folder (@folders) {
    ok length($folder->{title}), $folder->{title};
    like $folder->{BloglinesSubId}, qr/^\d+$/,  "subId: $folder->{BloglinesSubId}";
    like $folder->{BloglinesIgnore}, qr/^\d+$/, "ignore: $folder->{BloglinesIgnore}";
    my @feeds  = $subscription->feeds_in_folder($folder->{BloglinesSubId});
    my $num = scalar @feeds;
    ok $num, "$num feeds";
}

# list feeds in root folder
my @root_feeds = $subscription->feeds_in_folder(); # no args
my $num_root = scalar @root_feeds;
ok $num_root, "$num_root feeds";
