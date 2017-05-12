#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use Test::More;
use WebService::Beeminder;

# TODO: Move all the author/file sniffing into its own library.

if (not $ENV{AUTHOR_TESTING} ) {
    plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run author tests.'
}

my $token_file = "$ENV{HOME}/.webservice-beeminder.token";
my $token;

eval {
    open(my $fh, '<', $token_file);
    chomp($token = <$fh>);
};

if (not $token) {
    plan skip_all => "Cannot read $token_file";
}

# Retrieving user data can be done both with and without a dry-run,
# since it only reads.

my $wet_bee = WebService::Beeminder->new(token => $token);
my $dry_bee = WebService::Beeminder->new(token => $token, dryrun => 1);

foreach my $bee ($wet_bee, $dry_bee) {

    # This test assumes our beeminder username is the same as our
    # unix username.  We'll also try testing with 'me' and an empty
    # username.

    foreach my $user ($ENV{USER}, "", "me") {
        my $data = $bee->user();

        is(  $data->{username}, $ENV{USER}, "username ($user)");
        like($data->{timezone}, qr{^\w+/\w+$}, "timezone ($user)"); # Eg: Australia/Melbourne
        like($data->{updated_at}, qr{^\d+$}, "updated ($user)");
        ok('floss' ~~ $data->{goals}, "Floss is a goal ($user)");
    }
}

done_testing;
