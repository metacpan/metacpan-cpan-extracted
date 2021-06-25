use strict;
use Test::More;
use IO::File;
use File::Basename qw(dirname);
use File::Spec;
use WebService::Dropbox;

if (!$ENV{'DROPBOX_APP_KEY'} or !$ENV{'DROPBOX_APP_SECRET'} or !$ENV{'DROPBOX_ACCESS_TOKEN'}) {
    plan skip_all => 'missing App Key, App Secret, and/or Access Token';
}

my $testfile = File::Spec->catfile(dirname(__FILE__), 'sample.png');
my $path     = '/work/sharing-test-sample.png';

if (! -r $testfile) {
    plan skip_all => 'missing sample.png';
}

my $dropbox = WebService::Dropbox->new({
    key => $ENV{'DROPBOX_APP_KEY'},
    secret => $ENV{'DROPBOX_APP_SECRET'},
    access_token => $ENV{'DROPBOX_ACCESS_TOKEN'},
    env_proxy => 1,
});

$dropbox->debug;
$dropbox->verbose;

my $fh = IO::File->new($testfile, 'r');
$dropbox->upload($path, $fh) or die $dropbox->error;
$fh->close;

## create a shared link to the test file
my $settings = {
	requested_visibility => 'public',
	audience => 'public',
	access => 'viewer'
};
my $result = $dropbox->create_shared_link_with_settings($path, $settings) or die $dropbox->error;
is $dropbox->res->code, 200;

## list the shared links with test file
$result = $dropbox->list_shared_links($path) or die $dropbox->error;
is $dropbox->res->code, 200;

## revoke shared links with test file
my $revoke = $dropbox->revoke_shared_link($result->{'links'}->[0]->{'url'}) or die $dropbox->error;
is $dropbox->res->code, 200;

$dropbox->delete($path) or die $dropbox->error;

done_testing();
