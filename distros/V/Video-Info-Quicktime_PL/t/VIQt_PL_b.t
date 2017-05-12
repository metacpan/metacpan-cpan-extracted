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
    plan tests => 19 }

print "Loading Video::Info::Quicktime_PL...\n";
use Video::Info::Quicktime_PL;
# ok(1);

use Digest::MD5 qw(md5_base64);

print "Version: ".$Video::Info::Quicktime_PL::VERSION . "\n";

my $file = Video::Info::Quicktime_PL->new(-file=>'eg/p8241014.mov');
ok $file;
ok $file->probe;
ok( $file->achans   , 0 );        
ok(1,1);                          
ok( $file->arate    , 0 );        
ok( $file->astreams , 0 );        
ok( int($file->fps) , 15 );        
ok( $file->vcodec   , 'jpeg' );   
ok( $file->scale    , 0 );        
ok( $file->vrate    , 0 );        
ok( $file->vstreams , 1 );        
ok( $file->vframes  , 83 );            
ok( $file->width    , 320 );      
ok( $file->height   , 240 );      
ok( $file->type     , 'moov' );   
ok( sprintf('%4.2f',$file->duration), '5.53' );
ok( $file->title    , undef);     
ok( $file->copyright, undef);

ok( md5_base64($file->pict), 'xomFZwnON6waoaaVTNbp5Q' );

# if (length($file->pict)>0) {
#     print "Outputing PICT file\n";
#     my $oi = 'eg/mov_preview.pict';
#     open(O,">$oi") || warn("Couldn't open $oi: $!\n");
#     binmode(O);
#     # Image::Magick methods will only recognize this file as 
#     # PICT if there exists a leading header of zeros:
#     print O "\x00" x 512;
#     print O $file->pict;
#     close(O);
# }


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
