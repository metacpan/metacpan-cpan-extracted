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
    plan tests => 18 }

use Video::Info::MPEG;
ok(1);

my $file = Video::Info::MPEG->new(-file=>'eg/random.m2v');
#the good
ok $file;
ok $file->probe;
ok !$file->acodec;                            warn $file->acodec if DEBUG;
ok !$file->acodecraw;                         warn $file->acodecraw if DEBUG;
ok $file->achans       == 0;                  warn $file->achans if DEBUG;
ok $file->arate        == 0;                  warn $file->arate if DEBUG;
ok $file->astreams     == 0;                  warn $file->astreams if DEBUG;
ok $file->vstreams     == 1;                  warn $file->vstreams if DEBUG;
ok int($file->duration)== 0;                  warn $file->duration if DEBUG;
ok $file->vframes      == 0;                  warn $file->vframes if DEBUG;
ok $file->vcodec       eq 'MPEG1';            warn $file->vcodec if DEBUG;
ok $file->comments     eq '';                 warn $file->comments if DEBUG;
ok $file->vrate        == 104857200;          warn $file->vrate if DEBUG;
ok $file->height       == 240;                warn $file->height if DEBUG;
ok $file->width        == 320;                warn $file->width  if DEBUG;
ok int($file->fps)     == 30;                 warn $file->fps if DEBUG;
ok $file->type         eq 'MPEG';             warn $file->type if DEBUG;

#the bad

#the ugly


