# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2011-05-29 22:56:18 +0100 (Sun, 29 May 2011) $
# Id:            $Id: 00-pod.t 11 2011-05-29 21:56:18Z rmp $
# Source:        $Source$
# $HeadURL: svn+ssh://psyphi.net/repository/svn/www-scraper-lite/trunk/t/00-pod.t $
#
use strict;
use warnings;
use Test::More;

our $VERSION = do { my @r = (q$Revision: 11 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
