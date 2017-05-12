#!/usr/bin/perl -w

use strict;
use FindBin;
#use lib "$FindBin::Bin/../inc";
#use lib "$FindBin::Bin/../lib";
#use lib "$FindBin::Bin/../../Parse-Binary/lib";
use Test::More tests => 43;

$SIG{__DIE__} = sub { use Carp; Carp::confess(@_) };
$SIG{__WARN__} = sub { use Carp; Carp::cluck(@_) };

use_ok('Win32::Exe');

for ( qw( 32  64 ) ) {
    my $PEtype = $_;
    
    my $file = "$FindBin::Bin/winexe$PEtype.exe";

    my @expectedsections = ( $PEtype == 32 ) ? qw( .text .data .rdata .bss .idata .rsrc ) : qw( .text .data .rdata .bss .idata .CRT .tls .rsrc);
    my $expectedheadersize = ( $PEtype == 32 ) ? 224 : 240;

    ok(my $orig = Win32::Exe->read_file($file), 'read_file');

    my $exe = Win32::Exe->new($file);

    is($exe->ExpectedOptHeaderSize, $expectedheadersize, qq(Type $PEtype expected headersize));

    isa_ok($exe, 'Win32::Exe');
    is($exe->dump, $orig, qq(rountrip PE type $PEtype));

    is($exe->Subsystem, 'console', 'Subsystem');
    $exe->SetSubsystem('windows');
    is($exe->Subsystem, 'windows', 'SetSubsystem');
    $exe->SetSubsystem('CONSOLE');
    is($exe->Subsystem, 'console', 'SetSubsystem with uppercase string');

    is_deeply(
        [map $_->Name, $exe->sections],
        [ @expectedsections ],
        'sections'
    );

    $exe->refresh;
    is($exe->dump, $orig, qq(roundtrip after refresh 1 $PEtype));

    my ($sections) = $exe->sections;
    isa_ok($sections, 'Win32::Exe::Section');
    $sections->refresh;
    is($exe->dump, $orig, qq(roundtrip after refresh 2 $PEtype));

    my $rsrc = $exe->resource_section;
    isa_ok($rsrc, 'Win32::Exe::Section::Resources');
    $rsrc->refresh;
    is($exe->dump, $orig, qq(roundtrip after refresh 3 $PEtype));

    my @expectresources = ('/#RT_GROUP_ICON/#1/#0', '/#RT_ICON/#1/#0', '/#RT_ICON/#2/#0', '/#RT_MANIFEST/#1/#0', '/#RT_VERSION/#1/#0',);

    is_deeply(
        [$rsrc->names],
        [ @expectresources ],
        qq(resource names : $PEtype)
    );

    my $group = $rsrc->first_object('GroupIcon');
    my $expectginame = '/#RT_GROUP_ICON/#1/#0';
    is($group->PathName, $expectginame, 'group pathname');

    my $version = $rsrc->first_object('Version');
    is($version->info->[0], 'VS_VERSION_INFO', 'version->info');
    is($version->get('FileVersion'), '0,0,0,0', 'version->get');

    $version->set('FileVersion', '1,0,0,0');
    is($version->get('FileVersion'), '1,0,0,0', 'version->set took effect');
    $version->refresh;
    is($version->get('FileVersion'), '1,0,0,0', 'version->set remains after refresh');


    isnt(($exe->dump), $orig, qq(dump changed after resource refresh 4 $PEtype));
    $orig = $exe->dump;
    is(($exe->dump), $orig, qq(roundtrip after refresh 5 $PEtype));

}

1;
