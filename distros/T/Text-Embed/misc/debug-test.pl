#!/usr/bin/perl

BEGIN{ unshift @INC, '../lib'; }

system("perl -I../lib ../t/Text-Embed.t 1 > testresults.txt");
