use Test;
BEGIN { plan tests => 2 }
END { ok(0) unless $loaded }
use XML::GDOME::XSLT;
$loaded = 1;
ok(1);

my $p = XML::GDOME::XSLT->new();
ok($p);
