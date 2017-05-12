use strict; use warnings;
use Test;

BEGIN { plan tests => 3 }

use XML::XPath;
ok(1);

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

my @nodes = $xp->findnodes("//*[namespace_uri() = 'foobar.example.com']");
ok(@nodes, 4);


__DATA__
<xml xmlns="foobar.example.com">
    <foo>
        <bar/>
        <foo/>
    </foo>
</xml>
