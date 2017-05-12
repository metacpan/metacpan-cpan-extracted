
# $Id: pod.t,v 1.2 2008/07/21 03:25:46 Martin Exp $

use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

__END__

