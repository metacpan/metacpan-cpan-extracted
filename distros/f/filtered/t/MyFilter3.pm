package MyFilter3;

use Filter::Simple;

FILTER sub {
    my ($pkg, $func) = @_;
    $func->();
};

1;
