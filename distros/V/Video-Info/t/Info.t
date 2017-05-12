#!/usr/bin/perl

use lib './blib/lib';
use strict;

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) { 
	use lib 't';
    }
    use Test;
    plan tests => 7 }

use Video::Info;
ok(1);					#1

my $info;

$info = Video::Info->new( -file => 'eg/simpson.avi');
ok ref $info eq 'Video::Info::RIFF';

$info = Video::Info->new( -file => 'eg/t.asf');
ok ref $info eq 'Video::Info::ASF';

$info = Video::Info->new( -file => 'eg/meow.mp3');
ok ref $info eq 'MP3::Info';

$info = Video::Info->new( -file => 'eg/starstrp.mp2');
ok ref $info eq 'MP3::Info';

$info = Video::Info->new( -file => 'eg/random.m2v');
ok ref $info eq 'Video::Info::MPEG';

$info = Video::Info->new( -file => 'eg/t.mpg');
ok ref $info eq 'Video::Info::MPEG';

#$info = Video::Info->new( -file => 'eg/p8241014.mov');
#ok ref $info eq 'Video::Info::Quicktime';

#$info = Video::Info->new( -file => 'eg/sample.mov');
#ok ref $info eq 'Video::Info::Quicktime';
