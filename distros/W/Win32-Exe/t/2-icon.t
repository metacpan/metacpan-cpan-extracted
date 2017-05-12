#!/usr/bin/perl -w

use strict;
use FindBin;
#use lib "$FindBin::Bin/../inc";
#use lib "$FindBin::Bin/../lib";
#use lib "$FindBin::Bin/../../Parse-Binary/lib";
use Test::More tests => 27;

$SIG{__DIE__} = sub { use Carp; Carp::confess(@_) };
$SIG{__WARN__} = sub { use Carp; Carp::cluck(@_) };

use_ok('Win32::Exe::IconFile');

for ( qw( 32 64) ) {
    my $PEtype = $_;
    my $hd_icon = "$FindBin::Bin/hd.ico";
    my $par_icon = "$FindBin::Bin/par.ico";
    my $exe_file = "$FindBin::Bin/winexe$PEtype.exe";
       
    ok(my $par_orig = Win32::Exe::IconFile->read_file($par_icon), 'read_file');

    my $ico = Win32::Exe::IconFile->new($par_icon);
    isa_ok($ico, 'Win32::Exe::IconFile');
    is($ico->dump, $par_orig, 'roundtrip');
    is($ico->dump_iconfile, $par_orig, 'roundtrip with dump_iconfile');

    my ($icon1, $icon2) = $ico->icons;
    is(length($icon1->Data), $icon1->ImageSize, 'Image1 size fits');
    is(length($icon2->Data), $icon2->ImageSize, 'Image2 size fits');

    my $exe = Win32::Exe::IconFile->new($exe_file);
    isa_ok($exe, 'Win32::Exe');
    is($exe->dump_iconfile, $par_orig, 'roundtrip with dump_iconfile');
    $exe->set_icons(scalar $ico->icons);
    is($exe->dump_iconfile, $par_orig, 'roundtrip after set_icons');

    ok(my $hd_orig = Win32::Exe::IconFile->read_file($hd_icon), 'read_file');
    my $ico_hd = Win32::Exe::IconFile->new($hd_icon);
    $exe->set_icons(scalar $ico_hd->icons);
    
    if($_ == 32) {
        is(length($exe->dump), 13824, 'dump size correct after set_icons');
    } else {
        is(length($exe->dump), 20992, 'dump size correct after set_icons');
    }

    my $bad_icon = eval { Win32::Exe->new($par_icon) };
    is($bad_icon, undef, 'Win32::Exe->new($icon) should raise an exception');
    like($@, qr/Incorrect PE header -- not a valid \.exe file/, 'exception wording is correct');

}
