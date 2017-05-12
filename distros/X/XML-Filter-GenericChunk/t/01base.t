use Test;
BEGIN { plan tests => 2 }
END { ok(0) unless $loaded }
use XML::Filter::GenericChunk;
ok(1);

use XML::Filter::CharacterChunk;
$loaded = 1;
ok(1);



