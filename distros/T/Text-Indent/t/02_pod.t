#
# $Id: 02_pod.t 4552 2010-09-23 10:40:29Z james $
#

use strict;
use warnings;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

#
# EOF
