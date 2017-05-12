# $Id: pod.t,v 1.1.1.1 2008/01/22 03:42:21 Daddy Exp $
use Test::More;
my $VERSION = do { my @r = ( q$Revision: 1.1.1.1 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
__END__

