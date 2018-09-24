#!/usr/bin/perl

# $Id: 01packdrake.t 223440 2007-06-10 22:09:58Z nanardon $

use strict;
use Test::More tests => 7;
use Digest::MD5;

use_ok('packdrake');

-d "test" || mkdir "test" or die "Can't create directory test";

my $coin = q{
 ___________
< Coin coin >
 -----------
 \     ,~~.
  \ __( o  )
    `--'==( ___/)
       ( (   . /
        \ '-' /
    ~'`~'`~'`~'`~
};

sub clean_test_files {
    -d "test" or return;
    system("rm -fr $_") foreach (glob("test/*"));
}

clean_test_files();

mkdir "test/dir" or die "Can't create 'test/dir'";
open(my $fh, "> test/file") or die "Can't create 'test/file'";
print $fh $coin;
close $fh;

symlink("file", "test/link") or die "Can't create symlink 'test/link': $!\n";

open($fh, "> test/list") or die "can't open 'test/list': $!\n";
print($fh join("\n", qw(dir file link)) ."\n");
close($fh);

open(my $listh, "< test/list") or die "can't read 'test/list': $!\n";
ok(packdrake::build_archive(
    $listh,
    "test",
    "packtest.cz",
    400_000,
    "gzip -9",
    "gzip -d",
), "Creating a packdrake archive");
close($listh);

clean_test_files();

my $pack = packdrake->new("packtest.cz");
ok($pack->extract_archive("test", qw(dir file link)), "Extracting files from archive");

ok(open($fh, "test/file"), "Opening extract file");
sysread($fh, my $data, 1_000);
ok($data eq $coin, "data successfully restored");
ok(-d "test/dir", "dir successfully restored");
ok(readlink("test/link") eq "file", "symlink successfully restored");

clean_test_files();

