#
#===============================================================================
#
#         FILE: 00_yandexdisk_api.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 28.09.2017 13:15:41
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use FindBin '$Bin';
use File::Path::Tiny;
use Digest::MD5;
use File::Basename;
use lib "$Bin/../lib";
use Test::More 'no_plan';
use File::Spec;

my $TOKEN = 'AQAAAAAMIzNAAASQpMKd0J_8iUSkr4fIYskC880';
my $UPLOAD_FILE = File::Spec->catfile($Bin, 'small_file');
my $DOWNLOAD_FILE = File::Spec->catfile($Bin, "download_file");
File::Path::Tiny::rm ($DOWNLOAD_FILE);


BEGIN {
    use_ok("Yandex::Disk");
}

can_ok("Yandex::Disk", "new");

my $disk = Yandex::Disk->new( -token => $TOKEN);

isa_ok($disk, "Yandex::Disk");

testDiskInfo();
testCreateFolder();
testUploadFile();
testListFiles();
testListAllFiles();
testLastUploadedFiles();
testDownloadFile();
testCompareFile();
testDeleteResource();
testPublic();
testEmptyTrash();

File::Path::Tiny::rm ($DOWNLOAD_FILE);

sub testDiskInfo {
    can_ok("Yandex::Disk", "getDiskInfo");
    my $diskinfo = $disk->getDiskInfo();
    ok ($diskinfo->{total_space} > 0, "Test getDiskInfo total space");
    is ($diskinfo->{user}->{login}, 'anuta.belova2014', "Test getDiskInfo login");
}

sub testUploadFile {
    can_ok("Yandex::Disk", "uploadFile");
    my $res = $disk->uploadFile(
                                    -overwrite      => 1,
                                    -file           => $UPLOAD_FILE,
                                    -remote_path    => "/Temp",
                                );
    ok ($res, "Test uploadFile");
}

sub testDownloadFile {
    File::Path::Tiny::rm($DOWNLOAD_FILE);
    can_ok("Yandex::Disk", "downloadFile");
    my $res = $disk->downloadFile(
                                    -path       => '/Temp/' . basename($UPLOAD_FILE),
                                    -file       => $DOWNLOAD_FILE,
                                );
    ok($res, "Test downloadFile");
}

sub testCompareFile {
    my $source_md5 = get_md5($UPLOAD_FILE);
    my $downloaded_md5 = get_md5($DOWNLOAD_FILE);
    is ($source_md5, $downloaded_md5, "Test MD5 compare uploaded and downloaded file");
}

sub testCreateFolder {
    can_ok("Yandex::Disk", "createFolder");
    my $res = $disk->createFolder( -path => 'Temp/test', -recursive => 1);
    ok($res, "Test create folder");
}

sub testDeleteResource {
    can_ok("Yandex::Disk", "deleteResource");
    my $res = $disk->deleteResource( -path  => '/Temp/test' ) ;
    ok($res, "Test deleteResource");
}

sub testPublic {
    my $public = $disk->public();
    isa_ok($public, "Yandex::Disk::Public", "Test get Yandex::Disk::Public object");
}

sub testEmptyTrash {
    can_ok("Yandex::Disk", "emptyTrash");
    my $res = $disk->emptyTrash();
    ok ($res, "Test empty trash");
}

sub testListFiles {
    can_ok("Yandex::Disk", "listFiles");
    my $list = $disk->listFiles(-path =>'/Temp');
    my $found_file = grep {$_->{name} eq 'small_file'} @$list;
    ok ($found_file, "Test listFiles");
}

sub testListAllFiles {
    can_ok("Yandex::Disk", "listAllFiles");
    my $list = $disk->listAllFiles();
    my $found_file = grep {$_->{name} eq 'small_file'} @$list;
    ok ($found_file, "Test listAllFiles");
}

sub testLastUploadedFiles {
    can_ok("Yandex::Disk", "lastUploadedFiles");
    my $list = $disk->lastUploadedFiles();
    my $found_file = grep {$_->{name} eq 'small_file'} @$list;
    ok ($found_file, "Test lastUploadedFiles");
}


sub get_md5 {
    my $fname = shift;
    my $md5 = Digest::MD5->new;
    open my $FL, "<", $fname or die "Cant open $fname $!";
    while (<$FL>) {
        $md5->add($_);
    }
    close $FL;
    return $md5->b64digest;
}
