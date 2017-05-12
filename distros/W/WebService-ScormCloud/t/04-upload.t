#!perl -T

use strict;
use warnings;

use File::Spec;
use Test::More tests => 24;
use Test::Exception;

use lib File::Spec->curdir;
require File::Spec->catfile('t', '_test_util.pl');

my $SAMPLE_UPLOAD_FILE      = 'api-sample-upload.zip';
my $SAMPLE_UPLOAD_FILE_PATH = './blib/' . $SAMPLE_UPLOAD_FILE;

my ($ScormCloud, $skip_live_tests) = getScormCloudObject();

diag 'Live tests will be skipped' if $skip_live_tests;

can_ok($ScormCloud, 'getUploadToken');
can_ok($ScormCloud, 'getUploadProgress');
can_ok($ScormCloud, 'uploadFile');
can_ok($ScormCloud, 'listFiles');
can_ok($ScormCloud, 'deleteFiles');

SKIP:
{
    skip 'Skipping live tests', 19 if $skip_live_tests;

    my $token = $ScormCloud->getUploadToken;
    ok($token, '$ScormCloud->getUploadToken');

    my $progress;
    throws_ok { $progress = $ScormCloud->getUploadProgress() }
    qr/^Missing token/,
      '$ScormCloud->getUploadProgress caught missing token';

    $progress = $ScormCloud->getUploadProgress($token);
    isa_ok($progress, 'HASH', '$ScormCloud->getUploadProgress');
    is(scalar(keys %{$progress}), 0, '$ScormCloud->getUploadProgress is empty');

    unless (-f $SAMPLE_UPLOAD_FILE_PATH)
    {
        my $fh;
        unless (open($fh, '>', $SAMPLE_UPLOAD_FILE_PATH))
        {
            BAIL_OUT(
                  "Cannot create sample upload file: $SAMPLE_UPLOAD_FILE_PATH");
        }
        print $fh "foo\n";
        close $fh;
    }

    my $remote_name;

    throws_ok
    {
        $remote_name = $ScormCloud->uploadFile();
    }
    qr/^Missing file/, '$ScormCloud->uploadFile caught missing file';

    throws_ok
    {
        $remote_name =
          $ScormCloud->uploadFile($SAMPLE_UPLOAD_FILE_PATH, 'foobar');
    }
    qr/^Invalid API response data/,
      '$ScormCloud->uploadFile caught bogus token';

    $remote_name = $ScormCloud->uploadFile($SAMPLE_UPLOAD_FILE_PATH, $token);
    like($remote_name, qr/$SAMPLE_UPLOAD_FILE$/,
         '$ScormCloud->uploadFile remote name');

    $progress = $ScormCloud->getUploadProgress($token);
    isa_ok($progress, 'HASH', '$ScormCloud->getUploadProgress');
    foreach my $key (qw(bytes_read content_length percent_complete upload_id))
    {
        ok($progress->{$key}, "\$ScormCloud->getUploadProgress->{$key} exists");
    }

    my $list = $ScormCloud->listFiles;
    isa_ok($list, 'ARRAY', '$ScormCloud->listFiles');
    cmp_ok(@{$list}, '>=', 1, '$ScormCloud->listFiles at least one file');

    isa_ok($list->[0], 'HASH', '$ScormCloud->listFiles is a list of hashrefs');
    ok($list->[0]->{name}, '$ScormCloud->listFiles file name exists');

    my @matches = grep { /$SAMPLE_UPLOAD_FILE$/ } map { $_->{name} } @{$list};
    cmp_ok(scalar(@matches), '>=', 1,
           '$ScormCloud->listFiles at least one test file');

    throws_ok { $ScormCloud->deleteFiles() } qr/^Missing file/,
      '$ScormCloud->deleteFiles caught missing file';

    foreach my $file (@matches)
    {
        $ScormCloud->deleteFiles($file);
    }

    $list = $ScormCloud->listFiles;
    @matches = grep { /$SAMPLE_UPLOAD_FILE$/ } map { $_->{name} } @{$list};
    is(scalar(@matches), 0, '$ScormCloud->deleteFiles deleted all test files');
}

