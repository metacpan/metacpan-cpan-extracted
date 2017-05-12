package indirect::TestRequiredGlobal;

sub hurp { new ABC }

BEGIN { eval 'new DEF' }

eval 'new GHI';

1;
