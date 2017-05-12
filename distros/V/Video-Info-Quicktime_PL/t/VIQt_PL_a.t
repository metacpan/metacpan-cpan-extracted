#!/usr/bin/perl

use lib './blib/lib';
use lib '.';
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
    plan tests => 18 }

print "Loading Video::Info::Quicktime_PL...\n";
use Video::Info::Quicktime_PL;
# ok(1);

print "Version: ".$Video::Info::Quicktime_PL::VERSION . "\n";


my $file = Video::Info::Quicktime_PL->new(-file=>'eg/rot_button.mov');
ok $file;
ok $file->probe;
ok( $file->achans   , 0 );        
ok(1,1);                          
ok( $file->arate    , 0 );        
ok( $file->astreams , 0 );        
ok( int($file->fps) , 10 );        
ok( $file->vcodec   , 'jpeg' );   
ok( $file->scale    , 0 );        
ok( $file->vrate    , 0 );        
ok( $file->vstreams , 1 );        
ok( $file->vframes  , 21 );            
ok( $file->width    , 160 );      
ok( $file->height   , 120 );      
ok( $file->type     , 'moov' );   
ok( sprintf('%4.2f',$file->duration), '2.10' );
ok( $file->title    , undef);     
ok( $file->copyright, undef);     

do {
    print 'achans    '    .$file->achans       ."\n";
    print 'arate     '    .$file->arate        ."\n";
    print 'astreams  '    .$file->astreams     ."\n";
    print 'fps       '    .int($file->fps)     ."\n";
    print 'height    '    .$file->height       ."\n";
    print 'scale     '    .$file->scale        ."\n";
    print 'type      '    .$file->type         ."\n";
    print 'vcodec    '    .$file->vcodec       ."\n";
    print 'vframes   '    .$file->vframes      ."\n";
    print 'vrate     '    .$file->vrate        ."\n";
    print 'vstreams  '    .$file->vstreams     ."\n";
    print 'width     '    .$file->width        ."\n";
    print 'duration  '    .$file->duration     ."\n";
#    print 'acodecraw '    .$file->acodecraw    ."\n";
#    print 'acodec    '    .$file->acodec       ."\n";
#    print 'title     '    .$file->title        ."\n";
#    print 'copyright '    .$file->copyright    ."\n";
} if DEBUG;
