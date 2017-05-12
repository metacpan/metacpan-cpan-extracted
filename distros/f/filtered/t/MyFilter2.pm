package MyFilter2;

use Filter::Simple;

FILTER sub {
    s/FOOFOO/BAR/g;
};

1;
