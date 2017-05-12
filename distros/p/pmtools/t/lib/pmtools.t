# pmtools testing

# ------ pragmas
use strict;
use warnings;
use pmtools;
use Test::More tests => 7;

# ------ define variable
my $output = undef;	# output from pmtools

my $iter = pmtools::new_pod_iterator('quux');
is(ref $iter, 'CODE', 'created a pmtools iterator');
is($iter->(), "$INC[0]/pod/quux.pod", "first POD file, first \@INC");
is($iter->(), "$INC[0]/quux.pod",     "middle POD file, first \@INC");
is($iter->(), "$INC[0]/quux.pm",      "last POD file, first \@INC");

my $old_pod_file;
my $pod_file;
while ($pod_file = $iter->()) {
    $old_pod_file = $pod_file;
}
is($old_pod_file, "$INC[$#INC]/quux.pm", 'last POD file, last @INC');

is($pod_file, undef, 'beyond end of filenames');
is($iter->(), undef, 'way beyond end of filenames');
