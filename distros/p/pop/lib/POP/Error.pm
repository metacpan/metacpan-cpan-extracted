package POP::Error;

use overload '""' => sub {"System Error: ${$_[0]}"};

sub new {  bless \$_[1], $_[0] }

1;
