use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestConfig;
use Apache::TestRequest qw(UPLOAD_BODY);

plan tests => 7, need_lwp;

my $location = "/apreq_upload_test";

my %files = (
             '1b'   => 1,
             '1k'   => 1024,
             '10k'  => 10240,
             '63k'  => 64512,
             '64k'  => 65536,
             '65k'  => 66560,
             '128k' => 131072,
            );

my $server_root = Apache::Test::config()->{vars}->{serverroot};
my $dir = "$server_root/c-modules/apreq_upload_test";

foreach my $file (sort { $files{$a} <=> $files{$b} } keys %files) {
    my $size = $files{$file};

    my $result = UPLOAD_BODY($location, filename => "$dir/$file");
    ok t_cmp(
             $result,
             $size,
             "UPLOAD a file size $size btyes"
             );
}
