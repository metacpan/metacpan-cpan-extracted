#!/usr/local/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 1998,2005,2013 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: srezic@cpan.org
# WWW:  http://www.rezic.de
#

use strict;
use FindBin;
use lib $FindBin::RealBin;

use Test::More;

use File::Compare;
use File::Temp qw(tempfile);
use Getopt::Long;
use Tk;
use Tk::TIFF;

my $top = eval { Tk::MainWindow->new() };
if (!Tk::Exists($top)) {
    plan skip_all => "Cannot create MainWindow: $@";
    CORE::exit(0);
}

my $interactive;
GetOptions("interactive" => \$interactive)
    or die "usage: $0 [-interactive]";

$top->geometry("400x480+10+10");

# XXX test-2channel.tif - does not work yet
my @tiff_files = qw(test-none.tif test-lzw.tif
		    test-packbits.tif test-float.tif);

plan tests => 29;

SKIP: {
    skip "No MIME::Base64 available for string read test", scalar @tiff_files
	if !eval { require MIME::Base64; 1 };

    for my $tiff_file (@tiff_files) {
	my $tiff_path = "$FindBin::RealBin/$tiff_file";

	open my $fh, $tiff_path
	    or die "Can't open $tiff_path: $!";
	binmode $fh;
	my $buf = do {
	    undef $/;
	    <$fh>;
	};

	my $p =	eval { $top->Photo(-data => MIME::Base64::encode_base64($buf)) };
	ok $p && !$@, "string read of $tiff_file"
	    or diag $@;
    }
}

my @photo_defs;
for my $tiff_file (@tiff_files) {
    my $tiff_path = "$FindBin::RealBin/$tiff_file";
    my $p = eval { $top->Photo(-file => $tiff_path) };
    ok $p && !$@, "file read of $tiff_file"
	or diag $@;
    push @photo_defs, { p => $p, label => $tiff_file }
	if $p;
}

{
    Tk::TIFF::setContrastEnhance(1);
    my $p = eval { $top->Photo(-file => "$FindBin::RealBin/test-float.tif") };
    ok $p && !$@, 'contrast enhanced float tiff'
	or diag $@;
    push @photo_defs, { p => $p, label => 'test-float.tif (contrastEnhance=1)' }
	if $p;
}

{
    $top->packPropagate(0);
    my $image_l = $top->Label->pack(-expand => 1);
    my $label_l = $top->Label->pack(-fill => 'x');
    my $cont;
    if ($interactive) {
	$top->Button(-text => 'Continue',
		     -command => sub { $cont++ },
		    )->pack;
    }
    for my $i (0 .. $#photo_defs) {
	my($p, $label) = @{$photo_defs[$i]}{qw(p label)};
	$image_l->configure(-image => $p);
	$label_l->configure(-text => $label);
	$top->update;
	if ($interactive) {
	    $top->waitVariable(\$cont);
	} else {
	    $top->tk_sleep(0.5);
	}
    }
}

for my $photo_def (@photo_defs) {
    my($p, $label) = @{$photo_def}{qw(p label)};

    my($tmp1fh,$tmp1file) = tempfile(UNLINK => 1, SUFFIX => "_1.tiff")
	or die "Can't create temporary file: $!";
    $p->write($tmp1file);
    ok -s $tmp1file, "tiff file $label written";

    my $p2 = $top->Photo(-file => $tmp1file);
    ok $p2, 'tiff file re-read';

    my($tmp2fh,$tmp2file) = tempfile(UNLINK => 1, SUFFIX => "_2.tiff")
	or die "Can't create temporary file: $!";
    $p2->write($tmp2file);
    ok compare($tmp1file, $tmp2file) == 0, 'Comparison of both files';

    my($tmp3fh, $tmp3file) = tempfile(UNLINK => 1, SUFFIX => "_3.tiff")
	or die "Can't create temporary file: $!";
    $p2->write($tmp3file, '-format' => ['tiff', -compression => 'lzw']);
    ok -s $tmp3file, 'write lzw tiff';
}

# REPO BEGIN
# REPO NAME tk_sleep /home/e/eserte/work/srezic-repository 
# REPO MD5 2fc80d814604255bbd30931e137bafa4

sub Tk::Widget::tk_sleep {
    my($top, $s) = @_;
    my $sleep_dummy = 0;
    $top->after($s*1000,
                sub { $sleep_dummy++ });
    $top->waitVariable(\$sleep_dummy)
	unless $sleep_dummy;
}
# REPO END

