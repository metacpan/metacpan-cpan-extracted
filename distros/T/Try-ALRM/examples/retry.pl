
use strict;
use warnings;

local $SIG{ALRM} = sub {
  print qq{Alarm!! .. reArming ..\n};
  goto &retry;
};

sub retry {
  alarm 1;
  print qq{Trying something that might timeout ...\n};
  sleep 5;
  alarm 0;
}

retry();
