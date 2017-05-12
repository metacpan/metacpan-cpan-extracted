# $Id: pod.t,v 1.1.1.1 2008/06/30 02:04:04 Martin Exp $
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
__END__

