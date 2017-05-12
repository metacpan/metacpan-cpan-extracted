#!/usr/bin/perl

use lib './blib/lib';
use strict;
use constant DEBUG => 0;

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

my $userdata = "(C) 1997-2000 Womble Multimedia, Inc.\nMPEG-VCR OEM (09/2000)\nOct 15 2000\n";
 
use Video::Info::MPEG;
ok(1);

my $file = Video::Info::MPEG->new(-file=>'eg/t.mpg');
#the good
ok $file;
ok $file->probe;
ok $file->type         eq 'MPEG';             warn $file->type if DEBUG;
ok $file->acodec       eq 'MPEG Layer 1/2';   warn $file->acodec if DEBUG;
ok $file->acodecraw    == 80;                 warn $file->acodecraw if DEBUG;
ok $file->achans       == 2;                  warn $file->achans if DEBUG;
ok $file->arate        == 256000;             warn $file->arate if DEBUG;
ok int($file->fps)     == 29;                 warn $file->fps if DEBUG;
ok $file->height       == 240;                warn $file->height if DEBUG;
ok $file->width        == 352;                warn $file->width  if DEBUG;
ok $file->duration     == 1.2697;             warn $file->duration if DEBUG;
ok $file->astreams     == 1;                  warn $file->astreams if DEBUG;
ok $file->vstreams     == 1;                  warn $file->vstreams if DEBUG;
ok $file->vcodec       eq 'MPEG1';            warn $file->vcodec if DEBUG;
ok $file->comments     eq $userdata;          warn $file->comments if DEBUG;
ok $file->vframes      == 38;                 warn $file->vframes if DEBUG;
ok $file->vrate        == 1500000;            warn $file->vrate if DEBUG;
ok $file->minutes      == 0;                  warn $file->minutes if DEBUG;

#the bad

#the ugly

#bah, don't worry about this one.  we need to deprecate this public method.
#ok $file->scale        == 83255;              warn $file->scale if DEBUG;
