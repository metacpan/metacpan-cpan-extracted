#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;
use autodie;

use Ubic::Service::InitScriptWrapper;
use Ubic::Result qw(result);

system('rm -rf tfiles');
system('mkdir tfiles');

my $service = Ubic::Service::InitScriptWrapper->new('t/init.d/test');

is ''.$service->start, 'started';

is ''.$service->start, 'already running'; # thanks to Ubic::Service::Skeleton

is ''.$service->status, 'running';

is ''.$service->stop, 'stopped';

is ''.$service->stop, 'not running';

is ''.$service->status, 'not running';

done_testing;
