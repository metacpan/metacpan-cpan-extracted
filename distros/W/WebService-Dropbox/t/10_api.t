use strict;
use Data::Dumper;
use Encode;
use Test::More;
use File::Temp;
use IO::File;
use File::Basename qw(dirname);
use File::Spec;
use WebService::Dropbox;

if (!$ENV{'DROPBOX_APP_KEY'} or !$ENV{'DROPBOX_APP_SECRET'}) {
    plan skip_all => 'missing App Key or App Secret';
}

my $dropbox = WebService::Dropbox->new({
    key => $ENV{'DROPBOX_APP_KEY'},
    secret => $ENV{'DROPBOX_APP_SECRET'},
    env_proxy => 1,
});

$dropbox->use_lwp if $ENV{'DROPBOX_USE_LWP'};

$dropbox->debug;
$dropbox->verbose;

if ($ENV{'DROPBOX_ACCESS_TOKEN'}) {
    $dropbox->access_token($ENV{'DROPBOX_ACCESS_TOKEN'});
} else {
    my $url = $dropbox->authorize or die $dropbox->error;
    warn "Please Access URL $url\n";
    warn "Enter Code: ";
    chomp( my $code = <STDIN> );
    $dropbox->token($code) or die $dropbox->error;
    warn "access_token: ", $dropbox->access_token, "\n";
}

$dropbox->get_current_account or die $dropbox->error;

my $exists = $dropbox->get_metadata('/make_test_folder');

if ($exists) {
    $dropbox->delete('/make_test_folder') or die $dropbox->error;
    is $dropbox->res->code, 200, "delete make_test_folder";
}

$dropbox->download("/x", File::Temp->new);
like $dropbox->error, qr|not_found|, 'File not found';

$dropbox->create_folder('/make_test_folder') or die $dropbox->error;
is $dropbox->res->code, 200, "create_folder success";

$dropbox->create_folder('/make_test_folder');
is $dropbox->res->code, 409, "create_folder error already exists.";

# my $file_mark = decode_utf8('\'!"#$%&(=~|@`{}[]+*;,<>_?-^ 日本語.txt');

# # files_put
# my $fh_put = File::Temp->new;
# $fh_put->print('test.test.test.');
# $fh_put->flush;
# $fh_put->seek(0, 0);
# $dropbox->files_put('make_test_folder/' . $file_mark, $fh_put);
# $fh_put->close;

# # files_put_chunked
# if (-f '/tmp/1GB.dat') {
#     my $fh = IO::File->new('/tmp/1GB.dat');
#     my $data = $dropbox->files_put_chunked('make_test_folder/large-' . $file_mark, $fh);
#     $fh->close;
# }

# # metadata
# $exists = $dropbox->metadata('make_test_folder/' . $file_mark)
#     or die $dropbox->error;

# if ($exists and !$exists->{is_deleted}) {
#     pass "put.";
# }

# # copy
# my $copy = $dropbox->copy('make_test_folder/' . $file_mark, 'make_test_folder/test.txt')
#     or die $dropbox->error;

# # copy_ref
# my $copy_ref = $dropbox->copy_ref('make_test_folder/' . $file_mark)
#     or die $dropbox->error;

# $copy = $dropbox->copy($copy_ref, 'make_test_folder/test2.txt')
#     or die $dropbox->error;

# # move
# my $move = $dropbox->move('make_test_folder/' . $file_mark, 'make_test_folder/test2b.txt')
#     or die $dropbox->error;

# # files_put
# $fh_put = File::Temp->new;
# $fh_put->print('test.');
# $fh_put->flush;
# $fh_put->seek(0, 0);
# $dropbox->files_put('make_test_folder/' . $file_mark, $fh_put)
#     or die $dropbox->error;
# $fh_put->close;

# # files
# my $fh_get = File::Temp->new;
# $dropbox->files('make_test_folder/' . $file_mark, $fh_get) or die $dropbox->error;
# $fh_get->flush;
# $fh_get->seek(0, 0);
# is $fh_get->getline, 'test.', 'download success.';
# $fh_get->close;

# # files_put overwrite
# $fh_put = File::Temp->new;
# $fh_put->print('test2.');
# $fh_put->flush;
# $fh_put->seek(0, 0);
# $dropbox->files_put('make_test_folder/' . $file_mark, $fh_put) or die $dropbox->error;
# $fh_put->close;

# $fh_get = File::Temp->new;
# $dropbox->files('make_test_folder/' . $file_mark, $fh_get) or die $dropbox->error;
# $fh_get->flush;
# $fh_get->seek(0, 0);
# is $fh_get->getline, 'test2.', 'overwrite success.';
# $fh_get->close;

# # files_put no overwrite
# $fh_put = File::Temp->new;
# $fh_put->print('test3.');
# $fh_put->flush;
# $fh_put->seek(0, 0);
# $dropbox->files_put('make_test_folder/test.txt', $fh_put, { overwrite => 0 })
#     or die $dropbox->error;
# $fh_put->close;

# $exists = $dropbox->metadata('make_test_folder/test (1).txt');

# if ($exists and !$exists->{is_deleted}) {
#     pass "no overwrite success.";
# }

# # delta
# my $delta = $dropbox->delta()
#     or die $dropbox->error;

# # revisions
# my $revisions = $dropbox->revisions('make_test_folder/' . $file_mark)
#     or die $dropbox->error;

# # restore
# my $restore = $dropbox->restore('make_test_folder/' . $file_mark, { rev => $revisions->[1]->{rev} })
#     or die $dropbox->error;

# $fh_get = File::Temp->new;
# $dropbox->files('make_test_folder/' . $file_mark, $fh_get) or die $dropbox->error;
# $fh_get->flush;
# $fh_get->seek(0, 0);
# is $fh_get->getline, 'test.', 'restore success.';
# $fh_get->close;

# # search
# my $search = $dropbox->search('make_test_folder/', { query => 'test' })
#     or die $dropbox->error;
# is scalar(@$search), 4, 'search';

# # shares
# my $shares = $dropbox->shares('make_test_folder/' . $file_mark)
#     or die $dropbox->error;

# ok $shares->{url}, "shares";

# # media
# my $media = $dropbox->media('make_test_folder/' . $file_mark)
#     or die $dropbox->error;

# ok $shares->{url}, "media";

# # delete
# $dropbox->delete('make_test_folder/' . $file_mark) or die $dropbox->error;

# # thumbnails
# $fh_put = IO::File->new(File::Spec->catfile(dirname(__FILE__), 'sample.png'));
# $dropbox->files_put('make_test_folder/sample.png', $fh_put) or die $dropbox->error;
# $fh_put->close;

# $fh_get = File::Temp->new;
# $dropbox->thumbnails('make_test_folder/sample.png', $fh_get) or die $dropbox->error;
# $fh_get->flush;
# $fh_get->seek(0, 0);
# ok -s $fh_get, 'thumbnails.';
# $fh_get->close;

# # japanese
# my $file_utf8 = decode_utf8('日本語.txt');
# my $file_move_utf8 = decode_utf8('日本語_移動.txt');

# $fh_put = File::Temp->new;
# $fh_put->print('test5.');
# $fh_put->flush;
# $fh_put->seek(0, 0);
# $dropbox->files_put('make_test_folder/' . $file_utf8, $fh_put)
#     or die $dropbox->error;
# $fh_put->close;

# $exists = $dropbox->metadata('make_test_folder/' . $file_utf8);

# if ($exists and !$exists->{is_deleted}) {
#     pass "utf8.";
# }

# $dropbox->move('make_test_folder/' . $file_utf8, 'make_test_folder/' . $file_move_utf8) or die $dropbox->error;

# $dropbox->delete('make_test_folder/' . $file_move_utf8) or die $dropbox->error;

done_testing();
