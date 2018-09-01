package # hide from PAUSE
    Jaxsun::Trait::Provider;
use strict;
use warnings;

use decorators ':for_providers';

sub JSONProperty : Decorator : TagMethod { () }

1;
