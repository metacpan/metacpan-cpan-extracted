use strict;
use warnings;

use Test::More;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);

ok($xp);

# Debian bug #187583, http://bugs.debian.org/187583
# Check that evaluation doesn't lose the context information

my $nodes = $xp->find("text/para/node()[position()=last() and preceding-sibling::important]");
ok("$nodes", " has a preceding sibling.");

$nodes = $xp->find("text/para/node()[preceding-sibling::important and position()=last()]");
ok("$nodes", " has a preceding sibling.");

done_testing();

__DATA__
<text>
  <para>I start the text here, I break
the line and I go on, I <blink>twinkle</blink> and then I go on
    again.
This is not a new paragraph.</para><para>This is a
    <important>new</important> paragraph and
    <blink>this word</blink> has a preceding sibling.</para>
</text>