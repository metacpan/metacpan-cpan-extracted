# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2012-09-12 09:42:30 +0100 (Wed, 12 Sep 2012) $
# Id:            $Id: 00-pod.t 71 2012-09-12 08:42:30Z zerojinx $
# $HeadURL: https://text-sass.svn.sourceforge.net/svnroot/text-sass/trunk/t/00-pod.t $
#
use strict;
use warnings;
use Test::More;
eval {
  require Test::Pod;
  Test::Pod->import();
};
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

