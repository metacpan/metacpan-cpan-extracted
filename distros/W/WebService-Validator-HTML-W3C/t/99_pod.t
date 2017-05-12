# $Id: 99_pod.t,v 1.1 2004/01/13 22:34:37 struan Exp $
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
