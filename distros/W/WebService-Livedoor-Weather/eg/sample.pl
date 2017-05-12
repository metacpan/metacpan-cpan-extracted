#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib "lib";
use WebService::Livedoor::Weather;
binmode STDOUT, ':utf8';
 
my $lwws = WebService::Livedoor::Weather->new;
my $ret = $lwws->get(130010);
 
printf "%s\n---\n%s\n", $ret->{title}, $ret->{description}{text};
