package MyFilter;

use Filter::Simple;

FILTER sub {
    s/FOO/BAR/g;
};

1;
