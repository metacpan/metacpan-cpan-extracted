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
    plan tests => 39 }

print "Loading Video::Info::ASF...\n";
use Video::Info::ASF;
ok(1);

my $file = Video::Info::ASF->new(-file=>'eg/t.asf');
ok $file;
ok $file->probe;
ok $file->achans        == 2;                               warn $file->achans   if DEBUG;
ok $file->height        == 240;                             warn $file->height   if DEBUG;
ok $file->width         == 320;                             warn $file->width    if DEBUG;
ok $file->arate         == 64080;                           warn $file->arate    if DEBUG;
ok $file->vrate         == 524288;                          warn $file->vrate    if DEBUG;
ok $file->astreams      == 1;                               warn $file->astreams if DEBUG;
ok $file->vstreams      == 1;                               warn $file->vstreams if DEBUG;
ok int($file->duration) == 8319;                            warn $file->duration if DEBUG;

ok denull($file->title)       eq 'ASF  TEST #1';            warn $file->title    if DEBUG;
ok denull($file->author)      eq 'UnKnôwn - Founder of [PC]';       warn $file->author      if DEBUG;
ok denull($file->description) eq '';                                warn $file->description if DEBUG;
ok denull($file->copyright)   eq '#100_____collectors - DalNet';    warn $file->copyright   if DEBUG;
ok denull($file->rating)      eq '(None)';                  warn $file->rating   if DEBUG;
ok denull($file->acodec)      eq 'DivX audio (WMA)';        warn $file->acodec   if DEBUG;
ok $file->type                eq 'ASF';                     warn $file->type     if DEBUG;
ok $file->vcodec              eq 'MP43';                    warn $file->vcodec   if DEBUG;
ok length($file->header)      == 895;                       warn length($file->header)   if DEBUG;

##############################################################################
#not quite sure how to derive these...
#pretty much just useful to derive duration anyway, which is a freebie for ASF
#warn $file->vframes;#      == 349;
#warn $file->fps;#     == 12;
#warn $file->scale;#        == 83255;
##############################################################################

$file = Video::Info::ASF->new(-file=>'eg/nature.asf');
ok $file;
ok $file->probe;
ok $file->achans        == 1;                               warn $file->achans   if DEBUG;
ok $file->height        == 240;                             warn $file->height   if DEBUG;
ok $file->width         == 320;                             warn $file->width    if DEBUG;
ok $file->arate         == 16000;                           warn $file->arate    if DEBUG;
ok $file->vrate         == 920412;                          warn $file->vrate    if DEBUG;
ok $file->astreams      == 0;                               warn $file->astreams if DEBUG;
ok $file->vstreams      == 0;                               warn $file->vstreams if DEBUG;
ok int($file->duration) == 4;                               warn $file->duration if DEBUG;

ok denull($file->title)       eq 'The Living Trees';            warn $file->title    if DEBUG;
ok denull($file->author)      eq 'AIMS Multimedia';       warn $file->author      if DEBUG;
ok denull($file->description) eq 'The Living Trees';                                warn $file->description if DEBUG;
ok denull($file->copyright)   eq '(C) 2002 AIMS Multimedia';    warn $file->copyright   if DEBUG;
ok denull($file->rating)      eq 'Educational';                  warn $file->rating   if DEBUG;
ok denull($file->acodec)      eq 'Windows Media Audio';        warn $file->acodec   if DEBUG;
ok $file->type                eq 'ASF';                     warn $file->type     if DEBUG;
ok $file->vcodec              eq 'MP43';                    warn $file->vcodec   if DEBUG;
ok length($file->header)      == 4355;                       warn length($file->header)   if DEBUG;

##############################################################################
#not quite sure how to derive these...
#pretty much just useful to derive duration anyway, which is a freebie for ASF
#warn $file->vframes;#      == 349;
#warn $file->fps;#     == 12;
#warn $file->scale;#        == 83255;
##############################################################################

#grumpy about unicode doubles
sub denull {
  my $string = shift;
  $string =~ s/\0//g;
  return $string;
}
