package BaseException;
use strict;
use warnings;

sub throw { die bless {}, shift }

package MyException;
use strict;
use warnings;
our @ISA = 'BaseException';

package YourException;
use strict;
use warnings;
our @ISA = 'BaseException';

1;
