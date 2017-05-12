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
    plan tests => 17 }

#####################
#what do do with id3?  make a method? comment?
#####################
my $id3 = '';
#####################
#####################
 
use Video::Info::MPEG;
ok(1);

my $file = Video::Info::MPEG->new(-file=>'eg/meow.mp3');
#the good
ok $file;
ok $file->probe;
ok $file->type         eq 'MPEG';             warn $file->type if DEBUG;
ok $file->achans       == 1;                  warn $file->achans if DEBUG;

ok $file->arate        == 128000;             warn $file->arate if DEBUG;
ok !$file->vstreams;                          warn $file->vstreams if DEBUG;
ok !$file->vcodec;                            warn $file->vcodec if DEBUG;
ok !$file->vframes;                           warn $file->vframes if DEBUG;
ok $file->astreams     == 1;                  warn $file->astreams if DEBUG;

ok int($file->fps)     == 0;                  warn $file->fps if DEBUG;
ok $file->height       == 0;                  warn $file->height if DEBUG;
ok $file->width        == 0;                  warn $file->width  if DEBUG;
ok $file->vrate        == 0;                  warn $file->vrate if DEBUG;

#the bad
ok $file->acodec       eq 'MPEG Layer 1/2';   warn $file->acodec if DEBUG;
ok $file->acodecraw    == 80;                 warn $file->acodecraw if DEBUG;
ok $file->duration     == 0;                  warn $file->duration if DEBUG;

#the ugly
