use strict;
use warnings;
use Test::More;
use WWW::HatenaDiary;

my $username = $ENV{WWW_HATENADIARY_TEST_USERNAME};
my $password = $ENV{WWW_HATENADIARY_TEST_PASSWORD};
my $group    = $ENV{WWW_HATENADIARY_TEST_GROUP};

if ($username && $password) {
    plan tests => 10 * ($group ? 2 : 1);
}
else {
    plan skip_all => "Set ENV:WWW_HATENADIARY_TEST_USERNAME/PASSWORD";
}

crud_day();

if ($group) {
    crud_day($group);
}
else {
    diag "Set ENV:WWW_HATENADIARY_TEST_GROUP to give also Hatena::Group tests";
}

sub crud_day {
    my $group = shift;
    my $date  = '2100-01-01';
    my $title = 'day title';
    my $body  = "*test* title\ntest body";
    my $d;
    my $day;

    isa_ok(($d = WWW::HatenaDiary->new({
        group  => $group,
    })), 'WWW::HatenaDiary');

    $d->login({
        username => $username,
        password => $password,
    }) if !$d->is_loggedin;

    ok($d->create_day({
        title => $title,
        date  => $date,
        body  => $body,
    }), 'Creates new day');

    $day = $d->retrieve_day({
        date => $date,
    });

    is($title, $day->{title}, 'Creates a new day with a new title');
    is($body,  $day->{body},  'Creates a new day with a new body');

    $title .= '(updated)';
    $body  .= '(updated)';

    ok($d->update_day({
        title => $title,
        date  => $date,
        body  => $body,
    }), 'Updates the day');

    $day = $d->retrieve_day({
        date => $date,
    });

    is($title, $day->{title}, 'Updated the day with a new title');
    is($body,  $day->{body},  'Updated the day with a new body');

    ok($d->delete_day({
        date => $date,
    }), 'Deletes the day');

    $day = $d->retrieve_day({
        date => $date,
    });

    ok(!$day->{title},  'Deletes the day which has the title');
    ok(!$day->{body},   'Deletes the day which has the body');
}
