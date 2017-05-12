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

print "Loading Video::Info::Quicktime...\n";
use Video::Info::Quicktime;
ok(1);

my $file = Video::Info::Quicktime->new(-file=>'eg/sample.mov');

ok $file;
ok $file->probe;
ok $file->achans       == 2;		warn $file->achans if DEBUG;
ok $file->acodec       eq 'QDM2';	warn $file->acodec if DEBUG;
ok $file->arate        == 22050;	warn $file->arate  if DEBUG;
ok $file->astreams     == 1;		warn $file->astreams if DEBUG;
ok $file->vcodec       eq 'SVQ1';	warn $file->vcodec if DEBUG;
ok $file->vframes      == 60;		warn $file->vframes if DEBUG;
ok $file->vrate        == -1;	    warn $file->vrate if DEBUG;
ok $file->vstreams     == 1;		warn $file->vstreams if DEBUG;
ok $file->fps          == 12;		warn $file->fps if DEBUG;
ok $file->width        == 190;		warn $file->width if DEBUG;
ok $file->height       == 240;		warn $file->height if DEBUG;
ok !$file->type        eq '';       warn $file->type if DEBUG;
ok int($file->duration)== 5;		warn $file->duration if DEBUG;
ok $file->title        eq '-1';     warn $file->title if DEBUG;
ok $file->copyright    eq '-1';     warn $file->copyright if DEBUG;
