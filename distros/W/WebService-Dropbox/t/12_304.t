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

my $fh_put = File::Temp->new;
$fh_put->print('test.test.test.');
$fh_put->flush;
$fh_put->seek(0, 0);
$dropbox->upload('/304.dat', $fh_put) or die $dropbox->error;
$fh_put->close;

my $fh_get = File::Temp->new;
$dropbox->download('/304.dat', $fh_get);

is $dropbox->res->code, 200;

my $etag = $dropbox->res->header('ETag');

$dropbox->download('/304.dat', $fh_get, { headers => ['If-None-Match', $etag] });

is $dropbox->res->code, 304;

$dropbox->delete('/304.dat');

done_testing();
