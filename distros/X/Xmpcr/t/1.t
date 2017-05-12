
use strict;
use Test;
BEGIN { plan tests => 2}

eval { use Audio::Xmpcr; return 1;};
ok($@,'');
croak() if $@;  # If Net::Ping::HTTP didn't load... bail hard now

my $r=new Audio::Xmpcr(LOADTEST => 1);
ok(ref $r,'Audio::Xmpcr');

