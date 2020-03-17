package UniEvent::Error;
use 5.012;
use UniEvent;

use overload
    '""'     => \&what,
    fallback => 1,
;

1;
