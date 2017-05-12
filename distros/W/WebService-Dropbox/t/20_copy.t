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

my $fh_put = File::Temp->new;
$fh_put->print('test.test.test.');
$fh_put->flush;
$fh_put->seek(0, 0);
$dropbox->upload('/make_test_folder/copy.txt', $fh_put) or die $dropbox->error;
$fh_put->close;

is $dropbox->res->code, 200;

$dropbox->copy('/make_test_folder/copy.txt', '/make_test_folder/copy.2.txt');

$dropbox->move('/make_test_folder/copy.txt', '/make_test_folder/copy.4.txt');

is $dropbox->res->code, 200;

my $reference = $dropbox->copy_reference_get('/make_test_folder/copy.2.txt');

is $dropbox->res->code, 200;

$dropbox->copy_reference_save($reference->{copy_reference}, '/make_test_folder/copy.3.txt');

is $dropbox->res->code, 200;

$dropbox->get_metadata('/make_test_folder/copy.3.txt', {
    include_media_info => JSON::true,
    include_deleted => JSON::true,
    include_has_explicit_shared_members => JSON::false,
});

is $dropbox->res->code, 200;

my $write_code_data = '';
my $write_code = sub {
    # compatible with LWP::UserAgent and Furl::HTTP
    my $chunk = @_ == 4 ? $_[3] : $_[0];
    $write_code_data .= $chunk;
};
$dropbox->download('/make_test_folder/copy.3.txt', $write_code);

is $write_code_data, 'test.test.test.';

is $dropbox->res->code, 200;

$dropbox->get_temporary_link('/make_test_folder/copy.3.txt');

is $dropbox->res->code, 200;

my $fh = IO::File->new('./thumbnail.jpeg', '>');
$dropbox->get_thumbnail('/Photos/1ONWv.png', $fh);
$fh->close;

is $dropbox->res->code, 200;

done_testing();
