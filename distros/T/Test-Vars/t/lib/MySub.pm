# https://github.com/houseabsolute/p5-Test-Vars/issues/41
package MySub;
use strict;
use warnings;
use feature ':5.26';

sub foo  {
    my sub my_bar {  };
    my_bar();
    my_bar();
}

1;
