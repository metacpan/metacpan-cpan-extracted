use v5.20;
use warnings;
use utf8;


    use Test2::V0;
    use Test2::Tools::Condition;

    my $positive_number = condition { $_ > 0 };
    is 1, $positive_number; 
    is {
        a => 0,
        b => 1,
    }, {
        a => !$positive_number,
        b => $positive_number,
    };

