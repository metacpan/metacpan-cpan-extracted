##################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/xt/author/99_pod_coverage.t $
#    $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 210 $
##################################################################

use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.00 requried to test POD' if $@;
all_pod_coverage_ok();
