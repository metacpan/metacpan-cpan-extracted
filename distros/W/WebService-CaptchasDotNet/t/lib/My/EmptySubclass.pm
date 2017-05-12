package My::EmptySubclass;

use strict;
use warnings FATAL => qw(all);

use WebService::CaptchasDotNet;

@My::EmptySubclass::ISA = qw(WebService::CaptchasDotNet);

1;
