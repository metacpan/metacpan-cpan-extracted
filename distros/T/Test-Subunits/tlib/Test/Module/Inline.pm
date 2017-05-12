package Test::Module::Inline;

use 5.010;
use warnings;
use strict;

## use Test::More;
## plan tests => 5;

##{
my $DEF_COUNT = 0;
##}

sub example {
    my ($list_ref, $count) = @_;

    ##{
    ## {
    ##  my $list_ref = [1,undef,2,undef,3];
        $list_ref = [grep {defined} @{$list_ref}];
    ##  is_deeply $list_ref, [1,2,3] => 'grepping works';
    ## }
    ##}

    ##{
    ## {
    ##  my $count = undef;
        $count //= $DEF_COUNT;
    ##  is $count, 0 => 'default count works';
    ## }
    ##}

    ##{
    ## {
    ##  my ($list_ref, $count) = ([1..5], 3);
        my (@selections, @rejections);
        for my $list_elem (@{$list_ref}) {
            if ($list_elem > $count) {
                push @selections, $list_elem;
            }
            else {
                push @rejections, $list_elem;
            }
        }
    ## is_deeply \@selections, [4..5] => 'selection works';
    ## is_deeply \@rejections, [1..3] => 'rejection works';
    ## }
    ##}

        process_data(@selections);

    ##{
    ## {
    ##  my ($count, @rejections) = (3,1,2);
    ##  local *STDOUT;
    ##  open *STDOUT, '>', \my $stdout;
        for my $reject (@rejections) {
            say "Rejected: $reject (<= $count)";
        }
    ##  is $stdout, "Rejected: 1 (<= 3)\nRejected: 2 (<= 3)\n" => 'right output';
    ## }
    ##}

    ## done_testing();
}

1;

