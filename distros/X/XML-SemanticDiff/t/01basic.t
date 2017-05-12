use Test;
BEGIN { plan tests => 2 }
END { ok(0) unless $loaded }
use XML::SemanticDiff;
$loaded = 1;
ok(1);

my $diff = XML::SemanticDiff->new();
ok($diff);
