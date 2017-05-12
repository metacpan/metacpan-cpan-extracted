use strict;
use Test::More;
use WebService::Bloglines;

unless ($ENV{BLOGLINES_USERNAME}) {
    Test::More->import(skip_all => "no username set, skipped.");
    exit;
}

plan tests => 2;

my $bloglines = WebService::Bloglines->new(
    username => $ENV{BLOGLINES_USERNAME},
);

# get number of new items
my $notifier = $bloglines->notify();
like $notifier, qr/^\d+$/, "unread: $notifier";

# try malformed username
$bloglines = WebService::Bloglines->new(username => "...@%%%");
eval {
    $bloglines->notify();
};
like $@, qr/Bad username:/, $@;
