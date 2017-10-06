#
#===============================================================================
#
#         FILE: 01_yandexdisk_public.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01.10.2017 13:15:06
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use File::Basename;
use Test::More 'no_plan';
use Data::Printer;

my $UPLOAD_FILE = File::Spec->catfile($Bin, 'small_file');
my $TOKEN = 'AQAAAAAMIzNAAASQpMKd0J_8iUSkr4fIYskC880';

BEGIN {
    use_ok("Yandex::Disk::Public", "new");
}

can_ok("Yandex::Disk::Public", "new");

my $disk = Yandex::Disk::Public->new( -token => $TOKEN);

testPublic();
testListPublished();
testUnpublic();

sub testPublic {
    can_ok($disk, 'publicFile');
    my $res = $disk->publicFile( -path => '/Temp/' . basename($UPLOAD_FILE) );
    ok($res, "Get public metainfo");
    my $public_url = $disk->publicUrl;
    like($public_url, qr{^https}, "Test get public url");
}

sub testListPublished {
    can_ok($disk, 'listPublished');
    my $items = $disk->listPublished;
    like($items->[0]->{path}, qr{disk:/Temp/small_file}, "Test list published files");
}

sub testUnpublic {
    can_ok($disk, 'unpublicFile');
    my $res = $disk->unpublicFile( -path => '/Temp/' . basename($UPLOAD_FILE) );
    ok($res, "Test unpublic file");
}

