#!/usr/bin/perl

use lib './blib/lib';
use strict;
use constant DEBUG => 1;

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) { 
	use lib 't';
    }
    use Test;
    plan tests => 19 }

print "Loading Video::Info::Quicktime_PL...\n";
use Video::Info::Quicktime_PL;
ok(1);

my $file = Video::Info::Quicktime_PL->new(-file=>'eg/sample5.mov'); # p8241014.mov');
ok $file;
ok $file->probe;
ok( $file->achans   , 2 );
ok( $file->arate    , 22050 );
ok( $file->astreams , 1 );
ok( int($file->fps) , 12 );
ok( $file->height   , 240 );
ok( $file->scale    , 0 );
ok( $file->type     , 'moov' );
ok( $file->vcodec   , 'SVQ1' );
ok( $file->vframes  , 60 );
ok( $file->vrate    , 0 );
ok( $file->vstreams , 1 );
ok( $file->width    , 190 );
ok( int($file->duration), 5 );
# ok $file->acodecraw    eq '';
ok($file->acodec,'QDM2');
ok($file->title,"QuickTime Sample Movie");
ok($file->copyright,"© Apple Computer, Inc. 2001");

do {
print 'achans   '    .$file->achans       ."\n";
print 'arate    '    .$file->arate        ."\n";
print 'astreams '    .$file->astreams     ."\n";
print 'fps      '    .int($file->fps)     ."\n";
print 'height   '    .$file->height       ."\n";
print 'scale    '    .$file->scale        ."\n";
print 'type     '    .$file->type         ."\n";
print 'vcodec   '    .$file->vcodec       ."\n";
print 'vframes  '    .$file->vframes      ."\n";
print 'vrate    '    .$file->vrate        ."\n";
print 'vstreams '    .$file->vstreams     ."\n";
print 'width    '    .$file->width        ."\n";
print 'duration '    .$file->duration     ."\n";
# print 'acodecraw'    .$file->acodecraw    ."\n";
print 'acodec   '    .$file->acodec       ."\n";
print 'title    '    .$file->title        ."\n";
print 'copyright'    .$file->copyright    ."\n";
} if DEBUG;
