##################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/criticism-1.02/xt/author/98_pod_syntax.t $
#    $Date: 2008-07-27 16:11:59 -0700 (Sun, 27 Jul 2008) $
#   $Author: thaljef $
# $Revision: 174 $
##################################################################

use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
all_pod_files_ok();