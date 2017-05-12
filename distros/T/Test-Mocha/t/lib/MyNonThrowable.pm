package MyNonThrowable;

use overload '""' => \&message;

sub new { bless [], $_[0] }

sub message { 'died' }

1;
