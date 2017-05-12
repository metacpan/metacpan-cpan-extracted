use strict;
use warnings;
use Test::More;
use WWW::HatenaDiary;

my $username = $ENV{WWW_HATENADIARY_TEST_USERNAME};
my $password = $ENV{WWW_HATENADIARY_TEST_PASSWORD};
my $group    = $ENV{WWW_HATENADIARY_TEST_GROUP};

if ($username && $password) {
    plan tests => 7 * ($group ? 2 : 1);
}
else {
    plan skip_all => "Set ENV:WWW_HATENADIARY_TEST_USERNAME/PASSWORD";
}

crud_entry();

if ($group) {
    crud_entry($group);
}
else {
    diag "Set ENV:WWW_HATENADIARY_TEST_GROUP to give also Hatena::Group tests";
}

sub crud_entry {
    my $group = shift;
    my $title = 'test title';
    my $body  = 'test body';
    my $d;

    isa_ok(($d = WWW::HatenaDiary->new({
        group  => $group,
    })), 'WWW::HatenaDiary');

    $d->login({
        username => $username,
        password => $password,
    }) if !$d->is_loggedin;

    my $uri;
    my $entry;

    $uri = $d->create({
        title => $title,
        body  => $body,
    });

    $entry = $d->retrieve({
        uri => $uri,
    });

    is($title, $entry->{title}, 'Creates a new entry with a new title');
    is($body , $entry->{body},  'Creates a new entry with a new body');

    $title .= '(updated)';
    $body  .= '(updated)';

    $uri = $d->update({
        uri   => $uri,
        title => $title,
        body  => $body,
    });

    $entry = $d->retrieve({
        uri => $uri,
    });

    is($title, $entry->{title}, 'Updates the entry with a new title');
    is($body , $entry->{body},  'Updates the entry with a new body');

    $d->delete({
        uri => $uri,
    });

    $entry = $d->retrieve({
        uri => $uri,
    });

    ok(!$entry->{title}, 'Deletes the entry which has the title');
    ok(!$entry->{body},  'Deletes the entry which has the body');
}
