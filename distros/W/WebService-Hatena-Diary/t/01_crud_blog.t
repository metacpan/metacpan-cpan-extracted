use strict;
use warnings;
use Test::More;

# From WWW::HatenaDiary's test
my $username  = $ENV{WEBSERVICE_HATENA_DIARY_TEST_USERNAME};
my $dusername = $ENV{WEBSERVICE_HATENA_DIARY_TEST_DUSERNAME} || $username;
my $password  = $ENV{WEBSERVICE_HATENA_DIARY_TEST_PASSWORD};

if ($username && $password) {
    plan tests => 20;
}
else {
    plan skip_all => "Set ENV:WEBSERVICE_HATENA_DIARY_TEST_USERNAME/PASSWORD";
}

use_ok qw(WebService::Hatena::Diary);

my $diary = WebService::Hatena::Diary->new({
    username  => $username,
    dusername => $dusername,
    password  => $password,
    mode      => 'blog',
});

isa_ok($diary, qw(WebService::Hatena::Diary));

my $now = DateTime->now(time_zone => 'local');
my $edit_uri;
my $entry;
my $input_data = {
    title   => 'test title',
    content => 'test content',
    date    => '2010-01-01',
};

# create
$edit_uri = $diary->create({
    title   => $input_data->{title},
    content => $input_data->{content},
});
#retrieve
$entry = $diary->retrieve($edit_uri);

is($entry->{title},         $input_data->{title});
is($entry->{hatena_syntax}, $input_data->{content});
ok($entry->{content});
is($entry->{date},          $now->ymd);


# update
$input_data->{title}   .= ' updated';
$input_data->{content} .= ' updated';
$diary->update($edit_uri, {
    title   => $input_data->{title},
    content => $input_data->{content},
});
$entry = $diary->retrieve($edit_uri);

is($entry->{title},         $input_data->{title});
is($entry->{hatena_syntax}, $input_data->{content});
ok($entry->{content});
is($entry->{date},          $now->ymd);


# delete
$diary->delete($edit_uri);
$entry = $diary->retrieve($edit_uri);
ok(!$entry);
$diary->client->{_errstr} = ''; # errorをクリア


# create with date
$edit_uri = $diary->create({
    title   => $input_data->{title},
    content => $input_data->{content},
    date    => $input_data->{date},
});
$entry = $diary->retrieve($edit_uri);

is($entry->{title},         $input_data->{title});
is($entry->{hatena_syntax}, $input_data->{content});
ok($entry->{content});
is($entry->{date},          $input_data->{date});

# list
sleep 3; # wait for create
my @entries = $diary->list;
$entry = $entries[0];
is($entry->{edit_uri}, $edit_uri);
is($entry->{title},    $input_data->{title});
ok($entry->{content});
is($entry->{date},     $input_data->{date});


# delete
$diary->delete($edit_uri);
$entry = $diary->retrieve($edit_uri);
ok(!$entry);
$diary->client->{_errstr} = ''; # errorをクリア
