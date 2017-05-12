use strict;
use Data::Dumper;
use Encode;
use Test::More;
use File::Temp;
use IO::File;
use File::Basename qw(dirname);
use File::Spec;
use WebService::Dropbox;

if (!$ENV{'DROPBOX_APP_KEY'} or !$ENV{'DROPBOX_APP_SECRET'} or !$ENV{'DROPBOX_ACCESS_TOKEN'}) {
    plan skip_all => 'missing App Key or App Secret';
}

my $dropbox = WebService::Dropbox->new({
    key => $ENV{'DROPBOX_APP_KEY'},
    secret => $ENV{'DROPBOX_APP_SECRET'},
    access_token => $ENV{'DROPBOX_ACCESS_TOKEN'},
    env_proxy => 1,
});

$dropbox->debug;
$dropbox->verbose;

$dropbox->list_folder('/work', {
	recursive => JSON::true,
});

my $get_latest_cursor = $dropbox->list_folder_get_latest_cursor('/work', {
	recursive => JSON::true,
});

is $dropbox->res->code, 200;

# $dropbox->list_folder_continue($get_latest_cursor->{cursor});

# is $dropbox->res->code, 200;

$dropbox->list_folder_longpoll($get_latest_cursor->{cursor}, {
	timeout => 30
});

is $dropbox->res->code, 200;

done_testing();
