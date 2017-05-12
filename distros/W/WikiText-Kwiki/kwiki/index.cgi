#!/usr/bin/perl -w
use lib 'lib';
use Kwiki;
Kwiki->new->debug->process('config*.*', -plugins => 'plugins');
