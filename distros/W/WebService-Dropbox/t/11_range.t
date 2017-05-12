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

$dropbox->get_current_account or die $dropbox->error;

my $exists = $dropbox->get_metadata('/make_test_folder');

unless ($exists) {
    $dropbox->create_folder('/make_test_folder') or die $dropbox->error;
    is $dropbox->res->code, 200, "delete make_test_folder";
}

my $file_mark = decode_utf8('\'!"#$%&(=~|@`{}[]+*;,<>_?-^ 日本語.txt');

# upload
my $fh_put = File::Temp->new;
$fh_put->print('test.test.test.');
$fh_put->flush;
$fh_put->seek(0, 0);
$dropbox->upload('/make_test_folder/' . $file_mark, $fh_put) or die $dropbox->error;
$fh_put->close;

# download
my $fh_get = File::Temp->new;
$dropbox->download('/make_test_folder/' . $file_mark, $fh_get) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
is $fh_get->getline, 'test.test.test.', 'download success.';
$fh_get->close;

$fh_get = File::Temp->new;
$dropbox->download('/make_test_folder/' . $file_mark, $fh_get, { headers => ['Range' => 'bytes=10-14'] }) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
is $fh_get->getline, 'test.', 'download range success.';
$fh_get->close;

$dropbox->use_lwp;

$fh_get = File::Temp->new;
$dropbox->download('/make_test_folder/' . $file_mark, $fh_get, { headers => ['Range' => 'bytes=10-14'] }) or die $dropbox->error;
$fh_get->flush;
$fh_get->seek(0, 0);
is $fh_get->getline, 'test.', 'download range success.';
$fh_get->close;

done_testing();
