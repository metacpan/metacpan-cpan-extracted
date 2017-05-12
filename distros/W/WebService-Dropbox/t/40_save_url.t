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

my $save_url = $dropbox->save_url('/make_test_folder/copy.5.html', 'https://aska.pw');

is $dropbox->res->code, 200;

$dropbox->save_url_check_job_status($save_url->{async_job_id});

is $dropbox->res->code, 200;

done_testing();