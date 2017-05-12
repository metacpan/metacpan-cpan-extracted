#!/usr/bin/perl

use lib './lib', '../lib';

use Asterisk::QCall;

use Data::Dumper;

my $queue = new Asterisk::QCall;

$mytime = time()+240;
$queue->queuetime($mytime);
#$queue->queuedir('/tmp/queuetemp');
$queue->create_qcall('Zap/g3/7343418096','5175409674', '8@incomingpri', 0);

