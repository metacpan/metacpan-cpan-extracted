package Test::Module::Basic;

use 5.010;
use warnings;
use strict;

##{
    my $DEF_COUNT = 0;
##}

## sub def_count {
##      return $DEF_COUNT;
## }

sub example {
    my ($list_ref, $count) = @_;

    ##{
    ## sub normalize_list {
    ##  my $list_ref = shift;
        $list_ref = [grep {defined} @{$list_ref}];
    ##  return $list_ref
    ## }
    ##}

    ##{
    ## sub normalize_count {
    ##  my $count = shift;
        $count //= $DEF_COUNT;
    ##  return $count;
    ## }
    ##}

    ##{
    ## sub divide_list {
    ##  my ($list_ref, $count)  = @_;
        my (@selections, @rejections);
        for my $list_elem (@{$list_ref}) {
            if ($list_elem > $count) {
                push @selections, $list_elem;
            }
            else {
                push @rejections, $list_elem;
            }
        }
    ##  return [\@selections, \@rejections];
    ## }
    ##}

        process_data(@selections);

    ##{
    ## sub report_rejections {
    ##  my ($count, @rejections) = @_;
        for my $reject (@rejections) {
            say "Rejected: $reject (<= $count)";
        }
    ## }
    ##}
}

1;
