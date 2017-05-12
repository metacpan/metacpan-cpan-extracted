package Test::Module::Basic;

use 5.010; use warnings;


sub example {
    my ($list_ref, $count) = @_;

    ##{ normalize_list ($list_ref) --> $list_ref
        $list_ref = [grep {defined} @{$list_ref}];
    ##}

    ##: normalize_count ($count) --> $count
        $count //= 0;

    ##{ divide_list ($list_ref, $count) --> [\@selections, \@rejections]
        my (@selections, @rejections);
        for my $list_elem (@{$list_ref}) {
            if ($list_elem > $count) {
                push @selections, $list_elem;
            }
            else {
                push @rejections, $list_elem;
            }
        }
    ##}

        process_data(@selections);

    ##: report_rejections ($count, @rejections) --> ()
        for my $reject (@rejections) {
            say "Rejected: $reject (<= $count)";
        }

}

1;

