use strict;
use warnings;
use Test::More;

# From WWW::HatenaDiary's test
my $username  = $ENV{WEBSERVICE_HATENA_DIARY_TEST_USERNAME};
my $dusername = $ENV{WEBSERVICE_HATENA_DIARY_TEST_DUSERNAME} || $username;
my $password  = $ENV{WEBSERVICE_HATENA_DIARY_TEST_PASSWORD};

if ($username && $password) {
    plan tests => 17;
}
else {
    plan skip_all => "Set ENV:WEBSERVICE_HATENA_DIARY_TEST_USERNAME/PASSWORD";
}

use_ok qw(WebService::Hatena::Diary);

my $diary = WebService::Hatena::Diary->new({
    username  => $username,
    dusername => $dusername,
    password  => $password,
    mode      => 'draft',
});

isa_ok($diary, qw(WebService::Hatena::Diary));

my $now = DateTime->now(time_zone => 'local');
my $edit_uri;
my $entry;
my $input_data = {
    title   => 'test title',
    content => 'test content',
};

# create
$edit_uri = $diary->create({
    title   => $input_data->{title},
    content => $input_data->{content},
});
# retrieve
$entry = $diary->retrieve($edit_uri);

is($entry->{title},   $input_data->{title});
is($entry->{content}, $input_data->{content});
is($entry->{date},    $now->ymd);


# update
$input_data->{title}   .= ' updated';
$input_data->{content} .= ' updated';
$diary->update($edit_uri, {
    title   => $input_data->{title},
    content => $input_data->{content},
});
$entry = $diary->retrieve($edit_uri);

is($entry->{title},   $input_data->{title});
is($entry->{content}, $input_data->{content});
is($entry->{date},    $now->ymd);


# list
sleep 3; # wait for create
my @entries = $diary->list;
$entry = $entries[0];
is($entry->{edit_uri}, $edit_uri);
is($entry->{title},    $input_data->{title});
is($entry->{content},  $input_data->{content});
is($entry->{date},     $now->ymd);


# delete
$diary->delete($edit_uri);
$entry = $diary->retrieve($edit_uri);
ok(!$entry);
$diary->client->{_errstr} = ''; # errorをクリア


# create for publish
$edit_uri = $diary->create({
    title   => $input_data->{title},
    content => $input_data->{content},
});

# publish
sleep 3; # wait for create
$diary->publish($edit_uri);

$diary->{mode} = 'blog'; # blogモード

sleep 3; # wait for publish
$entry = ($diary->list)[0];
is($entry->{title},     $input_data->{title});
like($entry->{content}, qr/$input_data->{content}/);
is($entry->{date},      $now->ymd);

## delete
$edit_uri = $entry->{edit_uri};
$diary->delete($edit_uri);
$entry = $diary->retrieve($edit_uri);
ok(!$entry);
$diary->client->{_errstr} = ''; # errorをクリア


$diary->{mode} = 'draft'; # draftモード

