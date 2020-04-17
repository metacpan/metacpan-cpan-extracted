#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';


need_root_and_prepare();

my $name = 'various';
symlink $name, "media/${name}_bis";
my @media = ($name, "${name}_bis");
my @media_dirs = map { "$::pwd/media/$_" } @media;

urpmi_addmedia("$_ $::pwd/media/$_") foreach @media;

test_urpmq('', @media_dirs);
test_urpmq("--media $media[0]", $media_dirs[0]);
test_urpmq("--media $media[1]", $media_dirs[1]);
test_urpmq("--excludemedia $media[1]", $media_dirs[0]);
test_urpmq("--excludemedia $media[0]", $media_dirs[1]);
test_urpmq("--sortmedia $media[0],$media[1]", $media_dirs[0], $media_dirs[1]);
test_urpmq("--sortmedia $media[1],$media[0]", $media_dirs[1], $media_dirs[0]);

test_urpmi('', $media_dirs[0], $media[1]);
test_urpmi("--media $media[0]", $media_dirs[0], $media[1]);
test_urpmi("--media $media[1]", $media_dirs[1], $media[0]);
test_urpmi("--excludemedia $media[1]", $media_dirs[0], $media[1]);
test_urpmi("--excludemedia $media[0]", $media_dirs[1], $media[0]);
test_urpmi("--sortmedia $media[0],$media[1]", $media_dirs[0], $media[1]);
test_urpmi("--sortmedia $media[1],$media[0]", $media_dirs[1], $media[0]);

sub test_urpmq {
    my ($para, @wanted) = @_;
    my @l = run_urpm_cmd("urpmq $para --sources $name");
    foreach my $dir (@wanted) {
	my $found = shift @l;
	is(dirname($found), $dir, "directory $dir found");
    }
}

sub test_urpmi {
    my ($para, $wanted, $bad) = @_;
    my $s = run_urpm_cmd("urpmi $para $name");
    $s =~ s/^Preparing.*//sm;
    $s =~ s/^\s+$//sm;
    $s =~ s/^SECURITY: NOT checking package.*//m;

    ok($s =~ m!^installing $name\S* from $wanted$!m, "$wanted in <<'$s'>>");
    isnt($s =~ m!\Q$bad/!, "$bad not in $s", "$bad not in output");

    urpme($name);
}
