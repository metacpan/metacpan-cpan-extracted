package Test::Module::HalfWrappers;

use 5.010; use warnings;


sub example {
    my ($list_ref, $count) = @_;

    ##{ normalize_list ($list_ref)
        $list_ref = [grep {defined} @{$list_ref}];
    ##}

    ##: normalize_count ($count)
        $count //= 0;

    ##{ report_rejections ($count, @rejections)
        for my $reject (@rejections) {
            say "Rejected: $reject (<= $count)";
        }
    ##}
}

1;

